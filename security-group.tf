# ------------------------------
# Security Group
# ------------------------------
resource "aws_security_group" "web-sg" {
  name        = "${var.project}-${var.environment}-web-sg"
  description = "web server security group"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name    = "${var.project}-${var.environment}-web-sg"
    Project = var.project
    Env     = var.environment
  }
}

resource "aws_security_group_rule" "front_in_tcp3000" {
  security_group_id = aws_security_group.web-sg.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 3000
  to_port           = 3000
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "api_in_tcp8000" {
  security_group_id = aws_security_group.web-sg.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 8000
  to_port           = 8000
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "opmng_in_ssh" {
  security_group_id = aws_security_group.web-sg.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = [local.my_ip]
}

resource "aws_security_group_rule" "all_out" {
  security_group_id = aws_security_group.web-sg.id
  type              = "egress"
  protocol          = -1
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}