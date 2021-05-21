#--------------------------------------------------------
# Private subnet 4 digidec
#--------------------------------------------------------

# private subnet for digidec
resource "aws_subnet" "digidec_private" {
  vpc_id                  = module.vpc.vpc_id
  cidr_block              = local.digidec_private_subnet
  map_public_ip_on_launch = true
  availability_zone       = "eu-west-3a"

  tags = {
    Name = "digidec_private"
  }
}

#--------------------------------------------------------
# Public subnet 4 digidec
#--------------------------------------------------------

# public subnet for digidec
resource "aws_subnet" "digidec_public" {
  vpc_id                  = module.vpc.vpc_id
  cidr_block              = local.digidec_public_subnet
  map_public_ip_on_launch = false
  availability_zone       = "eu-west-3a"

  tags = {
    Name = "digidec_public"
  }
}


#--------------------------------------------------------
# NACL for digidec subnets
#--------------------------------------------------------

resource "aws_network_acl" "digidec" {
  vpc_id = module.vpc.vpc_id

  subnet_ids = [
    aws_subnet.digidec_public.id,
    aws_subnet.digidec_private.id
  ]

  dynamic "ingress" {
    for_each = local.digidec_nacl_rules

    content {
      protocol   = ingress.value.protocol
      rule_no    = ingress.key
      action     = ingress.value.action
      cidr_block = ingress.value.cidr_block
      from_port  = ingress.value.from_port
      to_port    = ingress.value.to_port
    }
  }

  dynamic "egress" {
    for_each = local.digidec_nacl_rules

    content {
      protocol   = egress.value.protocol
      rule_no    = egress.key
      action     = egress.value.action
      cidr_block = egress.value.cidr_block
      from_port  = egress.value.from_port
      to_port    = egress.value.to_port
    }
  }

  tags = {
    Name = "digidec_nacl"
  }
}
