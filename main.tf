provider "aws" {
  profile = "terraform"
  region = "ca-central-1"
}

resource "aws_instance" "tabi-note" {
  ami = "ami-0344a23c782460e34"
  instance_type = "t2.micro"

  tags = {
    Name = "tabi-note"
  }

  user_data = <<EOF
#!/bin/bash
amazon-linux-extras install -y nginx1.12
systemctl start nginx
EOF
}