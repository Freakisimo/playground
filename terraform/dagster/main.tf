terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  profile = "terraform"
  region = "us-east-1"
}

resource "aws_ecs_cluster" "dagster_cluster" {
  name = "dagster-cluster"
}

resource "aws_ecs_task_definition" "dagster_task_definition" {
  family                   = "dagster-task"
  container_definitions    = jsonencode([
    {
      name      = "dagster"
      image     = "dagster/dagster"
      memory    = 256
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 0
          protocol      = "tcp"
        }
      ]
    }
  ])
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
}

resource "aws_ecs_service" "dagster_service" {
  name            = "dagster-service"
  cluster         = aws_ecs_cluster.dagster_cluster.id
  task_definition = aws_ecs_task_definition.dagster_task_definition.arn
  desired_count   = 1

  load_balancer {
    target_group_arn = aws_lb_target_group.dagster_target_group.arn
    container_name   = "dagster"
    container_port   = 3000
  }

  network_configuration {
    security_groups = [aws_security_group.dagster_security_group.id]
    subnets         = aws_subnet.dagster_subnet.*.id
  }
  depends_on = [
    aws_lb_target_group.dagster_target_group,
  ]
}

resource "aws_vpc" "dagster_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "dagster-vpc"
  }
}

resource "aws_subnet" "dagster_subnet" {
  count = 2
  cidr_block = "10.0.${count.index}.0/24"
  vpc_id     = aws_vpc.dagster_vpc.id
  tags = {
    Name = "dagster-subnet-${count.index}"
  }
}


resource "aws_security_group" "dagster_security_group" {
  name_prefix = "dagster-sg-"
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  vpc_id      = aws_vpc.dagster_vpc.id
}

resource "aws_lb_target_group" "dagster_target_group" {
  name        = "dagster-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.dagster_vpc.id
}

resource "aws_lb" "dagster_alb" {
  name = "dagster-alb"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.dagster_security_group.id]
  subnets = aws_subnet.dagster_subnet.*.id
}
