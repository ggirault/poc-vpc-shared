locals {
  homeworking_cidr_blocks = var.private_cidr_blocks

  vpc_cidr               = "10.70.128.0/17"
  public_subnets         = ["10.70.144.0/24", "10.70.145.0/24"]
  private_subnets        = ["10.70.146.0/24", "10.70.147.0/24"]
  digidec_public_subnet  = "10.70.164.0/24"
  digidec_private_subnet = "10.70.166.0/24"

  digidec_nacl_rules = {
    "100" = { # Allow from subnets wihtin the same project and environment
      protocol   = -1
      action     = "allow"
      cidr_block = "10.70.164.0/23"
      from_port  = 0
      to_port    = 0
    },
    "200" = { # Allow from shared public and private subnets
      protocol   = -1
      action     = "allow"
      cidr_block = "10.70.144.0/23"
      from_port  = 0
      to_port    = 0
    },
    "500" = { # Deny all other ips dedicated to the AWS cloud
      protocol   = -1
      action     = "deny"
      cidr_block = "10.70.0.0/16"
      from_port  = 0
      to_port    = 0
    },
    "1000" = { # Allow traffic from the Internet
      protocol   = -1
      action     = "allow"
      cidr_block = "0.0.0.0/0"
      from_port  = 0
      to_port    = 0
    }
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc-shared"
  cidr = local.vpc_cidr

  azs             = ["eu-west-3a", "eu-west-3b"]
  public_subnets  = local.public_subnets
  private_subnets = local.private_subnets

  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true
  enable_vpn_gateway     = false

  public_dedicated_network_acl  = true
  private_dedicated_network_acl = true
}


# Create a vpc endpoint for the shared private subnet
resource "aws_vpc_endpoint" "s3" {
  for_each = toset([
    "ssm",
    "ssmmessages",
    "ec2messages",
  ])

  vpc_id             = module.vpc.vpc_id
  service_name       = "com.amazonaws.eu-west-3.${each.key}"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [aws_security_group.endpoints.id]
}


# Create a security group to allow all traffic to vpc endpoints
resource "aws_security_group" "endpoints" {
  name        = "allow_all"
  description = "Allow all traffic to vpc endpoint"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "ICMP from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}