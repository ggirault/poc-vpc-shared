# Protected instance, public ip accessible to and from the Internet
resource "aws_instance" "protected" {
  ami                    = local.ami
  instance_type          = "t3a.micro"
  subnet_id              = aws_subnet.protected.id
  iam_instance_profile   = aws_iam_instance_profile.main.id
  key_name               = "common-eu-west-3-archsolmmh"
  vpc_security_group_ids = [aws_security_group.default.id]
  volume_tags            = { Name = "protected" }
  tags                   = { Name = "protected" }
}

# Private instance, no public ip
resource "aws_instance" "private" {
  ami                    = local.ami
  instance_type          = "t3a.micro"
  subnet_id              = module.shared_vpc.private_subnets[0]
  iam_instance_profile   = aws_iam_instance_profile.main.id
  key_name               = "common-eu-west-3-archsolmmh"
  vpc_security_group_ids = [aws_security_group.default.id]
  volume_tags            = { Name = "private" }
  tags                   = { Name = "private" }
}

# Instance profile associated to all instances
resource "aws_iam_instance_profile" "main" {
  name_prefix = "archsol"
  role        = aws_iam_role.main.name
}

resource "aws_iam_role" "main" {
  name_prefix           = "archsol"
  description           = "Role for main CDZ"
  path                  = "/ggi/"
  force_detach_policies = true
  managed_policy_arns   = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]

  assume_role_policy = jsonencode({
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
  })
}
