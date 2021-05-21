resource "aws_spot_instance_request" "public" {
  ami                    = "ami-0b3e57ee3b63dd76b" # amazon linux 2 ami
  spot_price             = "0.03"
  instance_type          = "t3a.nano"
  subnet_id              = module.vpc.public_subnets[0]
  iam_instance_profile   = aws_iam_instance_profile.main.id
  vpc_security_group_ids = [aws_security_group.allow_internet_icmp.id]
  # key_name               = "cdz-eu-west-3-shrgrpemmh"
  # volume_tags            = local.instance_tags

  tags = {
    Name = "private"
  }
}

resource "aws_spot_instance_request" "private" {
  ami                  = "ami-0b3e57ee3b63dd76b" # amazon linux 2 ami
  spot_price           = "0.03"
  instance_type        = "t3a.nano"
  subnet_id            = module.vpc.private_subnets[0]
  iam_instance_profile = aws_iam_instance_profile.main.id
  # key_name               = "cdz-eu-west-3-shrgrpemmh"
  # volume_tags            = local.instance_tags

  tags = {
    Name = "private"
  }
}

resource "aws_spot_instance_request" "digidec_public" {
  ami                    = "ami-0b3e57ee3b63dd76b" # amazon linux 2 ami
  spot_price             = "0.03"
  instance_type          = "t3a.nano"
  subnet_id              = aws_subnet.digidec_public.id
  iam_instance_profile   = aws_iam_instance_profile.main.id
  vpc_security_group_ids = [aws_security_group.allow_internet_icmp.id]
  # key_name               = "cdz-eu-west-3-shrgrpemmh"
  # volume_tags            = local.instance_tags

  tags = {
    Name = "digidec_public"
  }
}

resource "aws_spot_instance_request" "digidec_private" {
  ami                  = "ami-0b3e57ee3b63dd76b" # amazon linux 2 ami
  spot_price           = "0.03"
  instance_type        = "t3a.nano"
  subnet_id            = aws_subnet.digidec_private.id
  iam_instance_profile = aws_iam_instance_profile.main.id
  # key_name               = "cdz-eu-west-3-shrgrpemmh"
  # volume_tags            = local.instance_tags

  tags = {
    Name = "digidec_private"
  }
}

resource "aws_iam_instance_profile" "main" {
  name_prefix = "ggi"
  role        = aws_iam_role.main.name
}

resource "aws_iam_role" "main" {
  name_prefix           = "ggi"
  description           = "Role for main CDZ"
  path                  = "/ggi/"
  force_detach_policies = true
  managed_policy_arns   = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]

  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : "sts:AssumeRole",
          "Principal" : {
            "Service" : "ec2.amazonaws.com"
          },
          "Effect" : "Allow",
          "Sid" : ""
        }
      ]
    }
  )
}

# Create a security group to allow ping from the Internet (Homeworking)
resource "aws_security_group" "allow_internet_icmp" {
  name        = "allow_icmp"
  description = "Allow ICMP inbound traffic from Homeworking"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "ICMP from Home"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = local.homeworking_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_icmp"
  }
}