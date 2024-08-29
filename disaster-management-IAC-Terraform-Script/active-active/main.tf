provider "aws" {
  alias  = "primary"
  region = "eu-north-1"
}

provider "aws" {
  alias  = "secondary"
  region = "eu-west-1"
}

# Primary Region (eu-north-1) Setup
resource "aws_vpc" "primary_vpc" {
  provider = aws.primary
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "primary_public_subnet_1" {
  provider = aws.primary
  vpc_id = aws_vpc.primary_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-north-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "primary_public_subnet_2" {
  provider = aws.primary
  vpc_id = aws_vpc.primary_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "eu-north-1b"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "primary_igw" {
  provider = aws.primary
  vpc_id = aws_vpc.primary_vpc.id
}

resource "aws_route_table" "primary_public_rt" {
  provider = aws.primary
  vpc_id = aws_vpc.primary_vpc.id
}

resource "aws_route" "primary_internet_access" {
  provider = aws.primary
  route_table_id = aws_route_table.primary_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.primary_igw.id
}

resource "aws_route_table_association" "primary_public_rta_1" {
  provider = aws.primary
  subnet_id = aws_subnet.primary_public_subnet_1.id
  route_table_id = aws_route_table.primary_public_rt.id
}

resource "aws_route_table_association" "primary_public_rta_2" {
  provider = aws.primary
  subnet_id = aws_subnet.primary_public_subnet_2.id
  route_table_id = aws_route_table.primary_public_rt.id
}

resource "aws_security_group" "primary_ec2_sg" {
  provider = aws.primary
  vpc_id = aws_vpc.primary_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
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
}

resource "aws_instance" "primary_web_server" {
  provider = aws.primary
  ami = "ami-07a0715df72e58928"  # Replace with a valid AMI ID for eu-north-1
  instance_type = "t3.micro"
  subnet_id = aws_subnet.primary_public_subnet_1.id
  vpc_security_group_ids = [aws_security_group.primary_ec2_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y nginx
              echo "Primary Instance: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)" > /var/www/html/index.html
              systemctl restart nginx
              EOF

  tags = {
    Name = "WebServerPrimary"
  }
}

resource "aws_db_instance" "primary_db" {
  provider = aws.primary
  identifier = "primary-db"
  engine = "postgres"
  engine_version = "16.3"
  instance_class = "db.t3.micro"
  allocated_storage = 20
  db_subnet_group_name = aws_db_subnet_group.primary_db_subnet_group.id
  vpc_security_group_ids = [aws_security_group.primary_ec2_sg.id]
  username = "dbadmin"
  password = "password"
  publicly_accessible = true
  multi_az = false
  db_name = "mydatabase"
  skip_final_snapshot  = false
  final_snapshot_identifier = "primary-rds-final-snapshot"
}

resource "aws_db_subnet_group" "primary_db_subnet_group" {
  provider = aws.primary
  name = "primary-db-subnet-group"
  subnet_ids = [aws_subnet.primary_public_subnet_1.id, aws_subnet.primary_public_subnet_2.id]
  description = "Primary database subnet group"
}

# Secondary Region (eu-west-1) Setup
resource "aws_vpc" "secondary_vpc" {
  provider = aws.secondary
  cidr_block = "10.1.0.0/16"  # Adjusted to avoid conflict with primary VPC
  enable_dns_support = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "secondary_public_subnet_1" {
  provider = aws.secondary
  vpc_id = aws_vpc.secondary_vpc.id
  cidr_block = "10.1.1.0/24"
  availability_zone = "eu-west-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "secondary_public_subnet_2" {
  provider = aws.secondary
  vpc_id = aws_vpc.secondary_vpc.id
  cidr_block = "10.1.2.0/24"
  availability_zone = "eu-west-1b"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "secondary_igw" {
  provider = aws.secondary
  vpc_id = aws_vpc.secondary_vpc.id
}

resource "aws_route_table" "secondary_public_rt" {
  provider = aws.secondary
  vpc_id = aws_vpc.secondary_vpc.id
}

resource "aws_route" "secondary_internet_access" {
  provider = aws.secondary
  route_table_id = aws_route_table.secondary_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.secondary_igw.id
}

resource "aws_route_table_association" "secondary_public_rta_1" {
  provider = aws.secondary
  subnet_id = aws_subnet.secondary_public_subnet_1.id
  route_table_id = aws_route_table.secondary_public_rt.id
}

resource "aws_route_table_association" "secondary_public_rta_2" {
  provider = aws.secondary
  subnet_id = aws_subnet.secondary_public_subnet_2.id
  route_table_id = aws_route_table.secondary_public_rt.id
}

resource "aws_security_group" "secondary_ec2_sg" {
  provider = aws.secondary
  vpc_id = aws_vpc.secondary_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
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
}

resource "aws_instance" "secondary_web_server" {
  provider = aws.secondary
  ami = "ami-0932dacac40965a65"  # Replace with a valid AMI ID for eu-west-1
  instance_type = "t3.micro"
  subnet_id = aws_subnet.secondary_public_subnet_1.id
  vpc_security_group_ids = [aws_security_group.secondary_ec2_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y nginx
              echo "Secondary Instance: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)" > /var/www/html/index.html
              systemctl restart nginx
              EOF

  tags = {
    Name = "WebServerSecondary"
  }
}

resource "aws_db_instance" "secondary_db" {
  provider = aws.secondary
  identifier = "secondary-db"
  engine = "postgres"
  engine_version = "16.3"
  instance_class = "db.t3.micro"
  allocated_storage = 20
  db_subnet_group_name = aws_db_subnet_group.secondary_db_subnet_group.id
  vpc_security_group_ids = [aws_security_group.secondary_ec2_sg.id]
  username = "dbadmin"
  password = "password"
  publicly_accessible = true
  multi_az = false
  db_name = "mydatabase"
  skip_final_snapshot  = false
  final_snapshot_identifier = "secondary-rds-final-snapshot"
}

resource "aws_db_subnet_group" "secondary_db_subnet_group" {
  provider = aws.secondary
  name = "secondary-db-subnet-group"
  subnet_ids = [aws_subnet.secondary_public_subnet_1.id, aws_subnet.secondary_public_subnet_2.id]
  description = "Secondary database subnet group"
}

# Primary ELB
resource "aws_elb" "primary_elb" {
  provider = aws.primary
  name               = "primary-elb"
  subnets            = [aws_subnet.primary_public_subnet_1.id, aws_subnet.primary_public_subnet_2.id]

  listener {
    instance_port     = 80
    instance_protocol = "HTTP"
    lb_port           = 80
    lb_protocol       = "HTTP"
  }

  instances = [aws_instance.primary_web_server.id]

  health_check {
    target              = "HTTP:80/"
    interval            = 5
    timeout             = 2
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Secondary ELB
resource "aws_elb" "secondary_elb" {
  provider = aws.secondary
  name               = "secondary-elb"
  subnets            = [aws_subnet.secondary_public_subnet_1.id, aws_subnet.secondary_public_subnet_2.id]

  listener {
    instance_port     = 80
    instance_protocol = "HTTP"
    lb_port           = 80
    lb_protocol       = "HTTP"
  }

  instances = [aws_instance.secondary_web_server.id]

  health_check {
    target              = "HTTP:80/"
    interval            = 5
    timeout             = 2
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Route 53 Failover Routing Setup
resource "aws_route53_record" "failover_primary" {
  zone_id = "Z0617063L23CMBRUC8SY"  # Replace with your actual hosted zone ID
  name    = "www.mannu.xyz."
  type    = "A"
  set_identifier = "Primary"

  failover_routing_policy {
    type = "PRIMARY"
  }

  alias {
    name                   = aws_elb.primary_elb.dns_name
    zone_id                = aws_elb.primary_elb.zone_id
    evaluate_target_health = true
  }

  health_check_id = aws_route53_health_check.primary_health.id
}

resource "aws_route53_record" "failover_secondary" {
  zone_id = "Z0617063L23CMBRUC8SY"  # Replace with your actual hosted zone ID
  name    = "www.mannu.xyz."
  type    = "A"
  set_identifier = "Secondary"

  failover_routing_policy {
    type = "SECONDARY"
  }

  alias {
    name                   = aws_elb.secondary_elb.dns_name
    zone_id                = aws_elb.secondary_elb.zone_id
    evaluate_target_health = true
  }

  health_check_id = aws_route53_health_check.secondary_health.id
}

# Health Checks for Route 53
resource "aws_route53_health_check" "primary_health" {
  provider = aws.primary
  fqdn     = aws_elb.primary_elb.dns_name
  type     = "HTTP"
  resource_path = "/"
  failure_threshold = 1
  request_interval = 30
}

resource "aws_route53_health_check" "secondary_health" {
  provider = aws.secondary
  fqdn     = aws_elb.secondary_elb.dns_name
  type     = "HTTP"
  resource_path = "/"
  failure_threshold = 1
  request_interval = 30
}

# Outputs
output "website_link" {
  value = "http://www.mannu.xyz"
}

output "primary_instance_public_ip" {
  value = aws_instance.primary_web_server.public_ip
}

output "secondary_instance_public_ip" {
  value = aws_instance.secondary_web_server.public_ip
}

output "primary_db_endpoint" {
  value = aws_db_instance.primary_db.endpoint
}

output "secondary_db_endpoint" {
  value = aws_db_instance.secondary_db.endpoint
}

output "primary_web_server_url" {
  value = "http://${aws_instance.primary_web_server.public_ip}"
}

output "secondary_web_server_url" {
  value = "http://${aws_instance.secondary_web_server.public_ip}"
}
