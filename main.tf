# Create a dedicated VPC for this demo to avoid conflicts
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "blue-green-demo-${var.environment}"
  }
}

# Create a public subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-${var.environment}"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw-${var.environment}"
  }
}

# Create route table for public subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt-${var.environment}"
  }
}

# Associate public subnet with route table
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Create a Security Group for the ALB
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg-${var.environment}"
  description = "Allow HTTP traffic to ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
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
    Name = "alb-sg-${var.environment}"
  }
}

# Create the Application Load Balancer
resource "aws_lb" "web_alb" {
  name               = "web-alb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public.id]

  enable_deletion_protection = false # Must be false for easy destroy

  tags = {
    Name = "web-alb-${var.environment}"
  }
}

# Create a Target Group for the ASG
resource "aws_lb_target_group" "asg_tg" {
  name     = "asg-tg-${var.environment}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "asg-tg-${var.environment}"
  }
}

# Create ALB Listener on port 80
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg_tg.arn
  }
}

# Create a Route53 record (ONLY if a domain_name is provided)
resource "aws_route53_record" "weighted" {
  count = var.domain_name != "" ? 1 : 0

  zone_id = data.aws_route53_zone.selected[0].zone_id
  name    = "blue-green-demo.${var.domain_name}"
  type    = "A"

  weighted_routing_policy {
    weight = var.weight
  }

  set_identifier = var.environment
  alias {
    name                   = aws_lb.web_alb.dns_name
    zone_id                = aws_lb.web_alb.zone_id
    evaluate_target_health = true
  }
}

# Data source to get the hosted zone ID if a domain is provided
data "aws_route53_zone" "selected" {
  count = var.domain_name != "" ? 1 : 0
  name  = var.domain_name
}
