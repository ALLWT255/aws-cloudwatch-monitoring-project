terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_vpc" "main_vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "${var.environment}-vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment}-public-subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.environment}-igw"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.environment}-public-rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  route_table_id = aws_route_table.public_rt.id
  subnet_id      = aws_subnet.public_subnet.id
}

resource "aws_security_group" "web_sg" {
  vpc_id      = aws_vpc.main_vpc.id
  name        = "${var.environment}-web-sg"
  description = "Allow web traffic"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-web-sg"
  }
}

resource "aws_iam_role" "ec2_cloudwatch_role" {
  name = "${var.environment}-ec2-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy" {
  role       = aws_iam_role.ec2_cloudwatch_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "cloudwatch_profile" {
  name = "${var.environment}-cloudwatch-profile"
  role = aws_iam_role.ec2_cloudwatch_role.name
}

resource "aws_instance" "web_server" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.cloudwatch_profile.name
  associate_public_ip_address = true

  user_data = <<-EOF
  #!/bin/bash
  set -euo pipefail

  dnf install -y nginx amazon-cloudwatch-agent logrotate

  # Grant the agent access without making logs world-readable.
  usermod -a -G nginx cwagent
  install -d -o nginx -g nginx -m 2750 /var/log/nginx
  touch /var/log/nginx/access.log /var/log/nginx/error.log
  chown nginx:nginx /var/log/nginx/access.log /var/log/nginx/error.log
  chmod 0640 /var/log/nginx/access.log /var/log/nginx/error.log

  # Preserve agent read access after rotation.
  cat > /etc/logrotate.d/nginx <<'NGINX_LOGROTATE'
  /var/log/nginx/*.log {
      daily
      rotate 7
      missingok
      notifempty
      compress
      delaycompress
      create 0640 nginx nginx
      sharedscripts
      postrotate
          if systemctl is-active --quiet nginx; then
              /usr/sbin/nginx -s reopen
          fi
      endscript
  }
  NGINX_LOGROTATE

  # file() preserves placeholders; the quoted heredoc prevents shell expansion.
  cat > /opt/aws/amazon-cloudwatch-agent/etc/cloudwatch-agent.json <<'CWAGENT_CONFIG'
  ${indent(2, file("${path.module}/cloudwatch-agent.json"))}
  CWAGENT_CONFIG

  systemctl enable --now nginx
  /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
      -a fetch-config -m ec2 \
      -c file:/opt/aws/amazon-cloudwatch-agent/etc/cloudwatch-agent.json -s
  systemctl enable amazon-cloudwatch-agent
  EOF

  depends_on = [
    aws_route_table_association.public_assoc,
    aws_iam_role_policy_attachment.cloudwatch_agent_policy
  ]

  tags = {
    Name = "${var.environment}-web-server"
  }
}
