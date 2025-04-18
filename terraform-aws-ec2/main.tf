provider "aws" {
  region = var.aws_region
}

# -----------------------------
# 1. Custom VPC
# -----------------------------
resource "aws_vpc" "custom_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "custom-vpc"
  }
}

# -----------------------------
# 2. Public Subnets
# -----------------------------
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.custom_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-1a"
  map_public_ip_on_launch = true
  tags = { Name = "public-subnet-1" }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.custom_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-west-1b"
  map_public_ip_on_launch = true
  tags = { Name = "public-subnet-2" }
}

# -----------------------------
# 3. Private Subnets
# -----------------------------
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.custom_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-west-1a"
  tags = { Name = "private-subnet-1" }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.custom_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "eu-west-1b"
  tags = { Name = "private-subnet-2" }
}

# -----------------------------
# 4. Internet Gateway + NAT Gateway
# -----------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.custom_vpc.id
  tags   = { Name = "custom-igw" }
}

resource "aws_eip" "nat_eip" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_1.id
  tags          = { Name = "nat-gateway" }
}

# -----------------------------
# 5. Route Tables
# -----------------------------
# Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.custom_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "public-rt" }
}

# Route table associations for public subnets
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_rt.id
}

# Private Route Table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.custom_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = { Name = "private-rt" }
}

# Route table associations for private subnets
resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private_rt.id
}

# -----------------------------
# 6. Security Group for Windows RDP
# -----------------------------
resource "aws_security_group" "windows_sg" {
  name        = "windows_rdp_sg"
  description = "Allow RDP"
  vpc_id      = aws_vpc.custom_vpc.id

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "allow-rdp" }
}

# -----------------------------
# 7. EC2 Instance in public subnet
# -----------------------------
resource "aws_instance" "windows_vm" {
  ami                    = var.ami_id
  instance_type          = "t3.micro"
  key_name               = var.key_name
  subnet_id              = aws_subnet.public_1.id
  vpc_security_group_ids = [aws_security_group.windows_sg.id]

  tags = {
    Name = "MyWindowsServer"
  }
}

# -----------------------------
# 8. Amazon Linux EC2 Instance
# -----------------------------
resource "aws_instance" "linux_vm" {
  ami                    = "ami-0ce8c2b29fcc8a346"     # ✅ Amazon Linux 2 AMI for eu-west-1
  instance_type          = "t2.micro"
  key_name               = "my-key"
  subnet_id              = aws_subnet.public_2.id      # Placed in second public subnet
  vpc_security_group_ids = [aws_security_group.windows_sg.id]  # Reuse same SG for now

  tags = {
    Name = "AmazonLinux-For-Docker"
  }
}
