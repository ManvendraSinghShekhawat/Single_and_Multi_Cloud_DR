# Providers for different regions
provider "aws" {
  alias  = "eu_north_1"
  region = "eu-north-1"
}

provider "aws" {
  alias  = "eu_west_1"
  region = "eu-west-1"
}

# VPC and subnets in eu-north-1
resource "aws_vpc" "vpc_eu_north" {
  provider = aws.eu_north_1
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "subnet_a_eu_north" {
  provider = aws.eu_north_1
  vpc_id = aws_vpc.vpc_eu_north.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-north-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "subnet_b_eu_north" {
  provider = aws.eu_north_1
  vpc_id = aws_vpc.vpc_eu_north.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "eu-north-1b"
  map_public_ip_on_launch = true
}

# Internet Gateway
resource "aws_internet_gateway" "igw_eu_north" {
  provider = aws.eu_north_1
  vpc_id = aws_vpc.vpc_eu_north.id
}

# Route Table
resource "aws_route_table" "route_table_eu_north" {
  provider = aws.eu_north_1
  vpc_id = aws_vpc.vpc_eu_north.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_eu_north.id
  }
}

# Associate Route Table with Subnets
resource "aws_route_table_association" "rt_assoc_subnet_a_eu_north" {
  provider = aws.eu_north_1
  subnet_id      = aws_subnet.subnet_a_eu_north.id
  route_table_id = aws_route_table.route_table_eu_north.id
}

resource "aws_route_table_association" "rt_assoc_subnet_b_eu_north" {
  provider = aws.eu_north_1
  subnet_id      = aws_subnet.subnet_b_eu_north.id
  route_table_id = aws_route_table.route_table_eu_north.id
}

# VPC and subnets in eu-west-1
resource "aws_vpc" "vpc_eu_west" {
  provider = aws.eu_west_1
  cidr_block = "10.1.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "subnet_a_eu_west" {
  provider = aws.eu_west_1
  vpc_id = aws_vpc.vpc_eu_west.id
  cidr_block = "10.1.1.0/24"
  availability_zone = "eu-west-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "subnet_b_eu_west" {
  provider = aws.eu_west_1
  vpc_id = aws_vpc.vpc_eu_west.id
  cidr_block = "10.1.2.0/24"
  availability_zone = "eu-west-1b"
  map_public_ip_on_launch = true
}

# Internet Gateway for eu-west-1
resource "aws_internet_gateway" "igw_eu_west" {
  provider = aws.eu_west_1
  vpc_id = aws_vpc.vpc_eu_west.id
}

# Route Table for eu-west-1
resource "aws_route_table" "route_table_eu_west" {
  provider = aws.eu_west_1
  vpc_id = aws_vpc.vpc_eu_west.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_eu_west.id
  }
}

# Associate Route Table with Subnets for eu-west-1
resource "aws_route_table_association" "rt_assoc_subnet_a_eu_west" {
  provider = aws.eu_west_1
  subnet_id      = aws_subnet.subnet_a_eu_west.id
  route_table_id = aws_route_table.route_table_eu_west.id
}

resource "aws_route_table_association" "rt_assoc_subnet_b_eu_west" {
  provider = aws.eu_west_1
  subnet_id      = aws_subnet.subnet_b_eu_west.id
  route_table_id = aws_route_table.route_table_eu_west.id
}

# RDS Subnet Group for eu-north-1
resource "aws_db_subnet_group" "rds_subnet_group_eu_north" {
  provider = aws.eu_north_1
  name       = "rds-subnet-group-eu-north"
  subnet_ids = [
    aws_subnet.subnet_a_eu_north.id,
    aws_subnet.subnet_b_eu_north.id
  ]
}

# RDS Subnet Group for eu-west-1
resource "aws_db_subnet_group" "rds_subnet_group_eu_west" {
  provider = aws.eu_west_1
  name       = "rds-subnet-group-eu-west"
  subnet_ids = [
    aws_subnet.subnet_a_eu_west.id,
    aws_subnet.subnet_b_eu_west.id
  ]
}

# RDS Instance in eu-north-1
resource "aws_db_instance" "primary_rds_eu_north" {
  provider = aws.eu_north_1
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "16.3"
  instance_class       = "db.t3.micro"
  db_name              = "mydatabase"
  username             = "dbadmin"
  password             = random_password.rds_password.result
  backup_retention_period = 7
  publicly_accessible  = true
  vpc_security_group_ids = [aws_security_group.rds_sg_eu_north.id]
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group_eu_north.name
  tags = {
    Name = "Primary RDS Instance eu-north-1"
  }
  skip_final_snapshot  = false
  final_snapshot_identifier = "primary-rds-final-snapshot"
}

# RDS Instance in eu-west-1
resource "aws_db_instance" "secondary_rds_eu_west" {
  provider = aws.eu_west_1
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "16.3"
  instance_class       = "db.t3.micro"
  db_name              = "mydatabase"
  username             = "dbadmin"
  password             = random_password.rds_password.result
  backup_retention_period = 7
  publicly_accessible  = true
  vpc_security_group_ids = [aws_security_group.rds_sg_eu_west.id]
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group_eu_west.name
  tags = {
    Name = "Secondary RDS Instance eu-west-1"
  }
  skip_final_snapshot  = false
  final_snapshot_identifier = "secondary-rds-final-snapshot"
}

# Random Password for RDS
resource "random_password" "rds_password" {
  length  = 16
  special = true
}

# Security Groups
resource "aws_security_group" "rds_sg_eu_north" {
  provider = aws.eu_north_1
  vpc_id = aws_vpc.vpc_eu_north.id

  ingress {
    from_port   = 5432
    to_port     = 5432
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

resource "aws_security_group" "rds_sg_eu_west" {
  provider = aws.eu_west_1
  vpc_id = aws_vpc.vpc_eu_west.id

  ingress {
    from_port   = 5432
    to_port     = 5432
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

resource "aws_security_group" "ec2_sg_eu_north" {
  provider = aws.eu_north_1
  vpc_id = aws_vpc.vpc_eu_north.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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

resource "aws_instance" "web_server_eu_north" {
  provider = aws.eu_north_1
  ami           = "ami-07a0715df72e58928" # Your specified AMI
  instance_type = "t3.micro"
  key_name      = "webapplication" # Your PEM key name
  subnet_id     = aws_subnet.subnet_a_eu_north.id
  vpc_security_group_ids = [aws_security_group.ec2_sg_eu_north.id]

  tags = {
    Name = "WebServer-eu-north-1"
  }
}

# Outputs
output "primary_rds_eu_north_endpoint" {
  value = aws_db_instance.primary_rds_eu_north.endpoint
}

output "secondary_rds_eu_west_endpoint" {
  value = aws_db_instance.secondary_rds_eu_west.endpoint
}

output "rds_username" {
  value = aws_db_instance.primary_rds_eu_north.username
}

output "rds_password" {
  value = random_password.rds_password.result
  sensitive = true
}

output "web_server_eu_north_public_ip" {
  value = aws_instance.web_server_eu_north.public_ip
}
