#Using default vpc
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "dev-vpc"
  }
}
#Using default subnets
resource "aws_subnet" "public_1" {
  cidr_block = "10.0.0.0/20"
  vpc_id = aws_vpc.vpc.id
  availability_zone = "ap-south-1a"
  tags = {
    Name = "public-subnet-1"
  }
}
resource "aws_subnet" "public_2" {
  cidr_block = "10.0.32.0/20"
  vpc_id = aws_vpc.vpc.id
  availability_zone = "ap-south-1a"
  tags = {
    Name = "public-subnet-2"
  }
}

resource "aws_subnet" "private" {
  cidr_block = "10.0.16.0/20"
  vpc_id = aws_vpc.vpc.id
  availability_zone = "ap-south-1b"
  tags = {
    Name = "private-subnet"
  }
}

resource "aws_internet_gateway" "igw"{
    vpc_id = aws_vpc.vpc.id
    tags = {
        Name = "igw"
    }
}

resource "aws_eip" "nat_eip"{
    domain = "vpc"
    tags = {
        Name = "nat-eip"
    }
}

resource "aws_nat_gateway" "nat"{
    allocation_id = aws_eip.nat_eip.id
    subnet_id = aws_subnet.public_1.id
    tags = {
        Name = "nat"
    }
}

resource "aws_route_table" "public_rt"{
    vpc_id = aws_vpc.vpc.id
    route{
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
    tags = {
        Name = "public-rt"
    }
}

resource "aws_route_table_association" "public_rt_asso"{
    subnet_id = aws_subnet.public_1.id
    route_table_id = aws_route_table.public_rt.id
}
resource "aws_route_table_association" "public_2_rt_asso"{
    subnet_id = aws_subnet.public_2.id
    route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private_rt"{
    vpc_id = aws_vpc.vpc.id
    route{
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_nat_gateway.nat.id
    }
    tags = {
        Name = "private-rt"
    }
}

resource "aws_route_table_association" "private_rt_asso"{
    subnet_id = aws_subnet.private.id
    route_table_id = aws_route_table.private_rt.id
}
#Creating security group
resource "aws_security_group" "alb_sg"{
    name = "alb_sg"
    vpc_id = aws_vpc.vpc.id
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
    vpc_id = aws_vpc.vpc.id
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
    subnets = [aws_subnet.public_1.id,aws_subnet.public_2.id]
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
    vpc_zone_identifier = [aws_subnet.public_1.id,aws_subnet.public_2.id]
    launch_template{
        id = aws_launch_template.lt.id
        version = "$Latest"
    }

    
}
