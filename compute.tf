# Security Group for the EC2 instances
resource "aws_security_group" "instance_sg" {
  name        = "instance-sg-${var.environment}"
  description = "Allow HTTP from ALB and SSH for debugging (optional)"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Optional: Allow SSH from your IP for debugging. REMOVE FOR MAX SECURITY.
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # WARNING: This is open to the world. Restrict to your IP in production!
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "instance-sg-${var.environment}"
  }
}

# Launch Template
resource "aws_launch_template" "web_server" {
  name_prefix   = "web-server-${var.environment}-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"           # Free tier eligible
  key_name      = "your-key-pair-name" # CHANGE THIS to your EC2 key pair name!

  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  user_data = filebase64("user-data.sh")

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name    = "web-server-${var.environment}"
      Version = var.app_version
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "web_asg" {
  name                = "web-asg-${var.environment}"
  desired_capacity    = 1 # Free tier: only 1 instance
  max_size            = 1
  min_size            = 1
  vpc_zone_identifier = [aws_subnet.public.id]
  target_group_arns   = [aws_lb_target_group.asg_tg.arn]

  launch_template {
    id      = aws_launch_template.web_server.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "web-asg-${var.environment}"
    propagate_at_launch = true
  }
}

# Get the latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's owner ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
