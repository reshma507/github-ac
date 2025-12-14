provider "aws" {
  region = var.aws_region
}

# Default VPC & subnets
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ----- STEP 1: LOGIN TO DOCKER HUB ------
resource "null_resource" "docker_login" {
  provisioner "local-exec" {
    command = "echo ${var.dockerhub_password} | docker login -u ${var.dockerhub_username} --password-stdin"
  }
}

# ----- STEP 2: BUILD DOCKER IMAGE ------
resource "null_resource" "docker_build" {
  depends_on = [null_resource.docker_login]

  provisioner "local-exec" {
    command = "docker build -t ${var.dockerhub_username}/${var.image_name}:latest ."
  }
}

# ----- STEP 3: PUSH DOCKER IMAGE ------
resource "null_resource" "docker_push" {
  depends_on = [null_resource.docker_build]

  provisioner "local-exec" {
    command = "docker push ${var.dockerhub_username}/${var.image_name}:latest"
  }
}

# ----- Security group for EC2 (allow SSH & Strapi) -----
resource "aws_security_group" "strapi_sg" {
  name        = "strapi-sg"
  description = "Allow Strapi & SSH"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH"
  }

  ingress {
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Strapi HTTP"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "strapi-sg"
  }
}

# ----- Security group for RDS (allow only from EC2 SG) -----
resource "aws_security_group" "rds_sg" {
  name        = "strapi-rds-sg"
  description = "Allow Postgres only from EC2 security group"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "Postgres from EC2"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.strapi_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "strapi-rds-sg"
  }
}

# ----- RDS Subnet Group using default subnets -----
resource "aws_db_subnet_group" "default" {
  name       = "strapi-dbsubnet"
  subnet_ids = data.aws_subnets.default.ids
  tags = {
    Name = "strapi-dbsubnet"
  }
}

# ----- RDS Postgres instance (free-tier friendly: db.t2.micro) -----
resource "aws_db_instance" "postgres" {
  identifier         = "strapi-postgres-${random_id.rid.hex}"
  engine             = "postgres"
  # engine_version     = "15.5"          # adjust if needed
  instance_class     = "db.t3.micro"
  allocated_storage  = var.db_allocated_storage
  db_name = var.db_name
  # name        = var.db_name
  username           = var.db_username
  password           = var.db_password
  db_subnet_group_name = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot = true
  publicly_accessible = true
  storage_type        = "gp2"
  tags = {
    Name = "strapi-postgres"
  }
  depends_on = [aws_db_subnet_group.default]
}

# small random id for uniqueness for db identifier
resource "random_id" "rid" {
  byte_length = 4
}

# ----- EC2 Instance -----
# Get most recent Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_instance" "strapi" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.ec2_instance_type
  subnet_id              = element(data.aws_subnets.default.ids, 0)
  vpc_security_group_ids = [aws_security_group.strapi_sg.id]
  key_name               = var.key_name != "" ? var.key_name : null
  associate_public_ip_address = true

  # user_data installs docker, pulls image from Docker Hub and runs it pointing to the RDS endpoint
  user_data = <<-EOF
    #!/bin/bash
    set -e

    apt-get update -y
    apt-get install -y docker.io
    systemctl enable --now docker

    # Wait a few seconds for docker to be ready
    sleep 5

    # Pull and run Docker Hub image (latest tag)
    IMAGE="${var.dockerhub_username}/${var.image_name}:${var.image_tag}"

    # Compose environment for Strapi to use RDS Postgres
    cat > /home/ubuntu/strapi.env <<EOD
    HOST=0.0.0.0
    PORT=1337

    APP_KEYS=SrGRSHbSbHV/OUmId7doZg==,cL+QLmuRM9a9qlEl/adnyQ==,kp6YXYbOkeIqmu0YyevJTg==,XShDrs9TJTconCAJjL4SBw==
    API_TOKEN_SALT=DyBgHklIZdboUlQAZZ/42g==
    ADMIN_JWT_SECRET=BAtS+/RTXz97ztKthDHJ2g==
    TRANSFER_TOKEN_SALT=kDiBX+hOa+bhAKPpSFR37A==
    ENCRYPTION_KEY=8sPv6kraSJAPrV50wj2jpA==
    ADMIN_AUTH_SECRET=H3F9oWqv7J2u1PcQ5tUyZg==
    JWT_SECRET=q9O4SbGr3ewg3SktK8qieA==

    DATABASE_CLIENT=postgres
    DATABASE_HOST=${aws_db_instance.postgres.address}
    DATABASE_PORT=${aws_db_instance.postgres.port}
    DATABASE_NAME=${var.db_name}
    DATABASE_USERNAME=${var.db_username}
    DATABASE_PASSWORD=${var.db_password}
    DATABASE_SSL=true
    DATABASE_SSL_REJECT_UNAUTHORIZED=false
    EOD

    # Remove old container if exists
    docker rm -f strapi || true

    # Run new container
    docker run -d --restart unless-stopped \
      --name strapi \
      -p 1337:1337 \
      --env-file /home/ubuntu/strapi.env \
      ${var.dockerhub_username}/${var.image_name}:${var.image_tag}

    # Make sure files are owned by ubuntu
    chown ubuntu:ubuntu /home/ubuntu/strapi.env || true
  EOF

  depends_on = [null_resource.docker_push, aws_db_instance.postgres]

  tags = {
    Name = "Terraform-Strapi-EC2"
  }
}

# Outputs
output "strapi_url" {
  value = "http://${aws_instance.strapi.public_ip}:1337"
}

output "rds_endpoint" {
  value = aws_db_instance.postgres.address
}
