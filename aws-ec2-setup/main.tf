# Define variables
variable "region" {
  default = "us-east-1"
}
variable "availability_zone" {
  default = "us-east-1a"
}
variable "ec2_instance_ami" {
  default = "ami-0df8c184d5f6ae949" # Amazon Linux 2023 AMI 2023.6.20250115.0 x86_64 HVM kernel-6.1
}
variable "ec2_instance_type" {
  default = "t2.medium"
}
variable "local_public_key_path" {
  default = "~/.ssh/id_rsa.pub"
}

#
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.5.7"
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
}

# Create a VPC
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.availability_zone
}

resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig.id
  }
}

resource "aws_route_table_association" "route_table_association" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_security_group" "security_group" {
  name        = "allow-ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.vpc.id

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
    Name = "ssh-access-sg"
  }
}

resource "aws_key_pair" "key_pair" {
  key_name   = "my-key-pair"
  public_key = file(var.local_public_key_path)
  #   public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_instance" "ec2_instance" {
  ami                         = var.ec2_instance_ami
  instance_type               = var.ec2_instance_type
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.subnet.id
  key_name                    = aws_key_pair.key_pair.key_name
  vpc_security_group_ids = [aws_security_group.security_group.id]
  user_data = <<EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install git -y
    sudo yum install gcc -y
  EOF
}

output "ec2_instance_public_ip" {
  value = aws_instance.ec2_instance.public_ip
}
output "ec2_instance_ssh_cmd" {
  value = "ssh -i ${replace(var.local_public_key_path, ".pub", "")} ec2-user@${aws_instance.ec2_instance.public_ip}"
}
