resource "aws_vpc" "myvpc"{
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "myvpc"
    }
}
resource "aws_subnet" "public_subnet"{
    vpc_id = aws_vpc.myvpc.id
    cidr_block = "10.0.0.0/20"
    availability_zone = "ap-south-1a"
    map_public_ip_on_launch = true
    tags = {
        Name = "public_subnet"
    }
}
resource "aws_subnet" "private_subnet"{
    vpc_id = aws_vpc.myvpc.id
    cidr_block = "10.0.16.0/20"
    availability_zone = "ap-south-1b"
    tags = {
        Name = "private_subnet"
    }
}
resource "aws_internet_gateway" "igw"{
    vpc_id = aws_vpc.myvpc.id
    tags = {
        Name = "igw"
    }
}
resource "aws_eip" "eip"{
    domain = vpc
    tags = {
        Name = "nat_eip"
    }
}
resource "aws_nat_gateway" "nat"{
    subnet_id = aws_subnet.public_subnet.id
    allocation_id = aws_eip.eip.id
    tags = {
        Name = "nat"
    }
}

resource "aws_route_table" "public_rt"{
    vpc_id = aws-vpc.myvpc.id
    route{
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
    tags = {
        Name = "public_rt"
    }
}
resource "aws_route_table_association" "public_rt_assoc"{
    subnet_id = aws_subnet.public_subnet.id
    route_table_id = aws_route_table.public_rt.id
}
resource "aws_route_table" "private_rt"{
    vpc_id = aws-vpc.myvpc.id
    route{
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_nat_gateway.nat.id
    }
    tags = {
        Name = "private_rt"
    }
}
resource "aws_route_table_association" "private_rt_assoc"{
    subnet_id = aws_subnet.private_subnet.id
    route_table_id = aws_route_table.private_rt.id
}

