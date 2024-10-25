provider "aws" {
  region = "ap-south-1"
}
resource "aws_vpc" "myvpc" {
    cidr_block="15.0.0.0/16"
    instance_tenancy="default"
  tags = {
    Name = "terraformcvpc"
  }
}
resource "aws_subnet" "pubsub" {
  vpc_id=aws_vpc.myvpc.id
 cidr_block="15.0.1.0/24"
  tags = {
    Name = "publicsubnet"
  }
}
resource "aws_subnet" "privsub" {
  vpc_id=aws_vpc.myvpc.id
 cidr_block="15.0.2.0/24"
  tags = {
    Name = "privatesubnet"
  }
}
resource "aws_internet_gateway" "tigw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "IGW"
  }
}
resource "aws_eip" "eip" {
 domain="vpc"
}
resource "aws_nat_gateway" "tnat" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.pubsub.id

  tags = {
    Name = "natgw"
  }

}
resource "aws_route_table" "pubrt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tigw.id
  }

  tags = {
    Name = "publicRT"
  }
}
resource "aws_route_table_association" "pubassociation" {
  subnet_id      = aws_subnet.pubsub.id
  route_table_id = aws_route_table.pubrt.id
}
resource "aws_route_table" "privrt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.tnat.id
  }

  tags = {
    Name = "privateRT"
  }
}
resource "aws_route_table_association" "privassociation" {
  subnet_id      = aws_subnet.privsub.id
  route_table_id = aws_route_table.privrt.id
}

resource "aws_vpc" "mainvpc" {
  cidr_block = "10.1.0.0/16"
}

resource "aws_security_group" "allow_all" {
  vpc_id = aws_vpc.myvpc.id

  ingress {
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 22
    to_port   = 22
  }
 ingress {
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 80
    to_port   = 80
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags={
    Name="allow_all"
  }
}
resource "aws_security_group" "priv_all" {
  vpc_id = aws_vpc.myvpc.id

  ingress {
    protocol  = "tcp"
    cidr_blocks = []
    from_port = 0
    to_port   = 65535
   security_groups=[aws_security_group.allow_all.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags={
    Name="priv_all"
  }
}
resource "aws_instance" "publicmachine" {
  ami                         = "ami-0d473344347276854"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.pubsub.id
  key_name                    = "ppkmb"
  vpc_security_group_ids      = ["${aws_security_group.allow_all.id}"]
  associate_public_ip_address = true
}
resource "aws_instance" "private" {
  ami                    = "ami-0d473344347276854"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.privsub.id
  key_name               = "formaskypem"
  vpc_security_group_ids = ["${aws_security_group.priv_all.id}"]
}