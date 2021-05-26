locals {
  homeworking_cidr_blocks = var.private_cidr_blocks

  ami = "ami-0b3e57ee3b63dd76b" # Amazon Linux 2

  vpc_cidr          = "10.70.0.0/17"
  public_subnets    = ["10.70.1.0/24"]  # Public subnet, only a firewall should be running inside this subnet
  private_subnets   = ["10.70.50.0/24"] # Private subnet, no public ip address, default route to firewall subnet
  protected_subnets = ["10.70.20.0/24"] # Public subnet protected by the firewal. The traffic coming to and from the Internet will be redirected to the firewall instances

  network_acls = {
    public_inbound = [
      {
        rule_number = 100
        rule_action = "allow"
        from_port   = 0
        to_port     = 0
        protocol    = -1
        cidr_block  = "0.0.0.0/0"
      },
    ]
    public_outbound = [
      {
        rule_number = 100
        rule_action = "allow"
        from_port   = 0
        to_port     = 0
        protocol    = -1
        cidr_block  = "0.0.0.0/0"
      },
    ]
    private_inbound = [
      {
        rule_number = 100
        rule_action = "allow"
        from_port   = 0
        to_port     = 0
        protocol    = -1
        cidr_block  = local.public_subnets[0]
      },
    ]
    private_outbound = [
      {
        rule_number = 100
        rule_action = "allow"
        from_port   = 0
        to_port     = 0
        protocol    = -1
        cidr_block  = local.public_subnets[0]
      },
    ]
  }
}

module "shared_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "shared-vpc"
  cidr = local.vpc_cidr

  azs             = ["eu-west-3a"]
  public_subnets  = local.public_subnets
  private_subnets = local.private_subnets

  public_inbound_acl_rules   = local.network_acls.public_inbound
  public_outbound_acl_rules  = local.network_acls.public_inbound
  private_inbound_acl_rules  = local.network_acls.private_inbound
  private_outbound_acl_rules = local.network_acls.private_inbound

  enable_nat_gateway     = false
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
  enable_vpn_gateway     = false

  public_dedicated_network_acl  = true
  private_dedicated_network_acl = true
}


#------------------------------------------------------------------
# Protected subnet
#------------------------------------------------------------------

resource "aws_subnet" "protected" {
  vpc_id                  = module.shared_vpc.vpc_id
  cidr_block              = local.protected_subnets[0]
  map_public_ip_on_launch = true
  tags                    = { Name = "shared-vpc-protected" }
}

resource "aws_route_table" "protected" {
  vpc_id = module.shared_vpc.vpc_id

  route {
    cidr_block  = "0.0.0.0/0"
    instance_id = aws_instance.firewall.id
  }

  tags = { Name = "shared-vpc-protected" }
}

resource "aws_route_table_association" "protected" {
  subnet_id      = aws_subnet.protected.id
  route_table_id = aws_route_table.protected.id
}


#------------------------------------------------------------------
# Private subnet
#------------------------------------------------------------------

resource "aws_route" "prifvate_to_firewall" {
  route_table_id         = module.shared_vpc.private_route_table_ids[0]
  destination_cidr_block = "0.0.0.0/0"
  instance_id            = aws_instance.firewall.id
}


#------------------------------------------------------------------
# Edge route Table
#------------------------------------------------------------------

resource "aws_route_table" "igw" {
  vpc_id = module.shared_vpc.vpc_id

  dynamic "route" {
    for_each = concat(local.private_subnets, local.protected_subnets)
    content {
      cidr_block  = route.value
      instance_id = aws_instance.firewall.id
    }
  }

  tags = { Name = "my-vpc-shared-igw" }
}

resource "aws_route_table_association" "igw" {
  gateway_id     = module.shared_vpc.igw_id
  route_table_id = aws_route_table.igw.id
}


#------------------------------------------------------------------
# Security Group
#------------------------------------------------------------------

# Create a security group to allow ping from the Internet (Homeworking)
resource "aws_security_group" "default" {
  name        = "firwall"
  description = "Allow all traffic from the VPC"
  vpc_id      = module.shared_vpc.vpc_id

  dynamic "ingress" {
    for_each = local.homeworking_cidr_blocks
    content {
      description = "SSH traffic from Home"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  dynamic "ingress" {
    for_each = local.homeworking_cidr_blocks
    content {
      description = "ICMP traffic from Home"
      from_port   = -1
      to_port     = -1
      protocol    = "icmp"
      cidr_blocks = [ingress.value]
    }
  }

  ingress {
    description = "All traffic from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [local.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "default-sg-mgmt"
  }
}
