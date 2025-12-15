provider "aws" {
  region = var.aws_region
}

# ---------------- NETWORK ----------------
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ---------------- SECURITY GROUPS ----------------
resource "aws_security_group" "ecs_sg" {
  name   = "strapi-ecs-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds_sg" {
  name   = "strapi-rds-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------- RDS ----------------
resource "aws_db_subnet_group" "default" {
  name       = "strapi-db-subnet"
  subnet_ids = data.aws_subnets.default.ids
}

resource "aws_db_instance" "postgres" {
  identifier             = "strapi-postgres"
  engine                 = "postgres"
  instance_class         = "db.t3.micro"
  allocated_storage      = var.db_allocated_storage
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = false
  skip_final_snapshot    = true
}

# ---------------- ECR ----------------
resource "aws_ecr_repository" "strapi" {
  name = "strapi-app"
}

# ---------------- IAM ----------------
resource "aws_iam_role" "ecs_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "secrets_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

# ---------------- ECS ----------------
resource "aws_ecs_cluster" "strapi" {
  name = "strapi-cluster"
}
data "aws_secretsmanager_secret" "strapi" {
  name = "strapi/secrets"
}

resource "aws_ecs_task_definition" "strapi" {
  family                   = "strapi-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
  {
    name  = "strapi"
    image = "${aws_ecr_repository.strapi.repository_url}:${var.image_tag}"

    portMappings = [{
      containerPort = 1337
    }]

    environment = [
      { name = "HOST", value = "0.0.0.0" },
      { name = "PORT", value = "1337" },

      { name = "DATABASE_CLIENT", value = "postgres" },
      { name = "DATABASE_HOST", value = aws_db_instance.postgres.address },
      { name = "DATABASE_PORT", value = "5432" },
      { name = "DATABASE_NAME", value = var.db_name },
      { name = "DATABASE_USERNAME", value = var.db_username },
      { name = "DATABASE_PASSWORD", value = var.db_password }
    ]

    secrets = [
      {
        name      = "APP_KEYS"
        valueFrom = "${data.aws_secretsmanager_secret.strapi.arn}:APP_KEYS::"
      },
      {
        name      = "API_TOKEN_SALT"
        valueFrom = "${data.aws_secretsmanager_secret.strapi.arn}:API_TOKEN_SALT::"
      },
      {
        name      = "ADMIN_JWT_SECRET"
        valueFrom = "${data.aws_secretsmanager_secret.strapi.arn}:ADMIN_JWT_SECRET::"
      },
      {
        name      = "TRANSFER_TOKEN_SALT"
        valueFrom = "${data.aws_secretsmanager_secret.strapi.arn}:TRANSFER_TOKEN_SALT::"
      },
      {
        name      = "ENCRYPTION_KEY"
        valueFrom = "${data.aws_secretsmanager_secret.strapi.arn}:ENCRYPTION_KEY::"
      },
      {
        name      = "ADMIN_AUTH_SECRET"
        valueFrom = "${data.aws_secretsmanager_secret.strapi.arn}:ADMIN_AUTH_SECRET::"
      }
    ]
  }
])
}

resource "aws_ecs_service" "strapi" {
  name            = "strapi-service"
  cluster         = aws_ecs_cluster.strapi.id
  task_definition = aws_ecs_task_definition.strapi.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = data.aws_subnets.default.ids
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  depends_on = [aws_db_instance.postgres]
}
