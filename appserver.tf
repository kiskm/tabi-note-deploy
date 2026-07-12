# ------------------------------
# key pair
# ------------------------------
resource "aws_key_pair" "keypair" {
  key_name   = "${var.project}-${var.environment}-keypair"
  public_key = file("./src/tabi-note-dev-keypair.pub")

  tags = {
    Name    = "${var.project}-${var.environment}-keypair"
    Project = var.project
    Env     = var.environment
  }
}

# ------------------------------
# EC2 Instance
# ------------------------------
resource "aws_instance" "app_server" {
  ami                         = data.aws_ami.app.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet_1a.id
  associate_public_ip_address = true
  vpc_security_group_ids = [
    aws_security_group.web-sg.id
  ]
  key_name = aws_key_pair.keypair.key_name

  user_data = <<-EOF
  #!/bin/bash
  # Error handling
  set -euxo pipefail
  exec > >(tee /var/log/user-data.log) 2>&1

  # Start declaration
  echo "[UserData] Start: $(date '+%F %T')"

  # Docker installation
  dnf install -y docker git
  systemctl start docker
  systemctl enable docker
  usermod -aG docker ec2-user

  # Docker Compose installation
  mkdir -p /usr/lib/docker/cli-plugins
  curl -SL https://github.com/docker/compose/releases/download/v5.1.3/docker-compose-linux-x86_64 -o /usr/lib/docker/cli-plugins/docker-compose
  chmod +x /usr/lib/docker/cli-plugins/docker-compose

  # Docker buildx installation
  curl -SL https://github.com/docker/buildx/releases/download/v0.34.1/buildx-v0.34.1.linux-amd64 -o /usr/lib/docker/cli-plugins/docker-buildx
  chmod +x /usr/lib/docker/cli-plugins/docker-buildx

  # Git clone
  cd /home/ec2-user
  git clone https://github.com/kiskm/tabi-note-deploy.git
  cd tabi-note-deploy
  git clone https://github.com/kiskm/tabi-note-api.git
  git clone https://github.com/kiskm/tabi-note-front.git
  chown -R ec2-user:ec2-user /home/ec2-user

  # Add swap
  dd if=/dev/zero of=/swapfile bs=128M count=16
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile

  # Build
  docker compose build api
  docker compose build front
  docker compose up -d

  # End declaration
  echo "[UserData] Done : $(date '+%F %T')"
  EOF

  tags = {
    Name    = "${var.project}-${var.environment}-app-ec2"
    Project = var.project
    Env     = var.environment
    Type    = "app"
  }
}

# ------------------------------
# Elastic IP
# ------------------------------
resource "aws_eip" "app" {
  domain   = "vpc"
  instance = aws_instance.app_server.id

  tags = {
    Name    = "${var.project}-${var.environment}-app-eip"
    Project = var.project
    Env     = var.environment
  }
}

output "app_public_ip" {
  value = aws_eip.app.public_ip
}