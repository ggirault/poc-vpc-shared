resource "aws_instance" "firewall" {
  ami                    = local.ami
  instance_type          = "t3a.micro"
  subnet_id              = module.shared_vpc.public_subnets[0]
  iam_instance_profile   = aws_iam_instance_profile.main.id
  key_name               = "common-eu-west-3-archsolmmh"
  source_dest_check      = false
  vpc_security_group_ids = [aws_security_group.default.id]
  volume_tags            = { Name = "firewall" }
  tags                   = { Name = "firewall" }
  user_data              = <<EOF
#!/bin/sh
sysctl -w net.ipv4.ip_forward=1
EOF
}
