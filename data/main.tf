#Using default vpc
data "aws_vpc" "default" {
  default = true
}
#Using default subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}
#Creating security group
resource "aws_security_group" "alb_sg"{
    name = "alb_sg"
    vpc_id = data.aws_vpc.default.id
    ingress{
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress{
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress{
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "alb_sg"
    }
}
#Creating ALB target Group
resource "aws_lb_target_group" "tg"{
    name = "tg"
    port = 80
    protocol = "HTTP"
    vpc_id = data.aws_vpc.default.id
    health_check {
        path = "/"
    }
}
#Creating ALB
resource "aws_lb" "app_lb"{
    name = "app-lb"
    load_balancer_type = "application"
    internal = false
    security_groups = [aws_security_group.alb_sg.id]
    subnets = data.aws_subnets.default.ids
}
#Creating Listener
resource "aws_alb_listener" "listener"{
    load_balancer_arn = aws_lb.app_lb.arn
    port = 80
    protocol = "HTTP"
    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.tg.arn
    }
}
#Launch Template
resource "aws_launch_template" "lt"{
    name = "mylt"
    image_id = "ami-01a00762f46d584a1"
    key_name = "mumbai"
    instance_type = "t3.micro"
    vpc_security_group_ids = [aws_security_group.alb_sg.id]
    user_data = filebase64("/root/practice-terraform/data/user_data.sh")
}
#Auto Scaling
resource "aws_autoscaling_group" "asg"{
    name = "asg"
    desired_capacity = 2
    min_size = 2
    max_size = 4
    health_check_type = "ELB"
    target_group_arns = [aws_lb_target_group.tg.arn]
    vpc_zone_identifier = data.aws_subnets.default.ids
    launch_template{
        id = aws_launch_template.lt.id
        version = "$Latest"
    }

    
}
