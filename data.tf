# ------------------------------
# AMI
# ------------------------------
data "aws_ami" "app" {
  most_recent = true
  owners      = ["self", "amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.11.*-kernel-6.1-x86_64"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ------------------------------
# My IP
# ------------------------------
data "http" "my_ip" {
  url = "https://api.ipify.org?format=json"
}