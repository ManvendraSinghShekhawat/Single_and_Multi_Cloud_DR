# Define providers
provider "aws" {
  region = "eu-north-1"
}

provider "google" {
  credentials = file("./key")
  project     = "wide-net-432004-a7"
  region      = "europe-north1"
}

# AWS VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "main-vpc"
  }
}

# AWS Subnets
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index}.0/24"
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-${count.index}"
  }
}

# AWS Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

# AWS Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Associate Route Table with Subnets
resource "aws_route_table_association" "public" {
  count      = 2
  subnet_id  = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# AWS Security Group
resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.main.id

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

  tags = {
    Name = "web-sg"
  }
}

# AWS EC2 Instances
resource "aws_instance" "web_server_aws" {
  count             = 2
  ami               = "ami-07a0715df72e58928"  # Your specified AMI
  instance_type     = "t3.micro"
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  subnet_id         = aws_subnet.public[count.index].id
  security_groups   = [aws_security_group.web_sg.name]

  tags = {
    Name = "web-server-aws-${count.index}"
  }
}

# GCP VM Instances
resource "google_compute_instance" "web_server_gcp" {
  count        = 2
  name         = "web-server-gcp-${count.index}"
  machine_type = "e2-micro"
  zone         = element(data.google_compute_zones.available.names, count.index)

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10-buster-v20210701"
    }
  }

  network_interface {
    network = "default"
  }

  tags = ["web-server"]
}

# Data sources for availability zones and compute zones
data "aws_availability_zones" "available" {}

data "google_compute_zones" "available" {}

# AWS Application Load Balancer
resource "aws_lb" "app_lb" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = [for subnet in aws_subnet.public : subnet.id]

  enable_deletion_protection = false
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Service is unavailable"
      status_code  = "503"
    }
  }
}

# AWS Target Group
resource "aws_lb_target_group" "web_targets" {
  name        = "web-targets"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold    = 2
    unhealthy_threshold  = 2
  }
}

resource "aws_lb_target_group_attachment" "aws_attachment" {
  count             = 2
  target_group_arn  = aws_lb_target_group.web_targets.arn
  target_id         = aws_instance.web_server_aws[count.index].id
  port              = 80
}

# Route 53 DNS Failover Configuration
resource "aws_route53_zone" "main" {
  name = "multicloud.mannu.xyz"  
}

resource "aws_route53_record" "failover_primary" {
  zone_id = aws_route53_zone.main.id
  name    = "Z0617063L23CMBRUC8SY" 
  type    = "A"

  alias {
    name                   = aws_lb.app_lb.dns_name
    zone_id                = aws_lb.app_lb.zone_id
    evaluate_target_health = true
  }

  failover_routing_policy {
    type = "PRIMARY"
  }
  
  health_check_id = aws_route53_health_check.primary.id
}

resource "aws_route53_record" "failover_secondary" {
  zone_id = aws_route53_zone.main.id
  name    = "Z0617063L23CMBRUC8SY"  # Replace with your DNS record name
  type    = "A"

  alias {
    name                   = aws_lb.app_lb.dns_name
    zone_id                = aws_lb.app_lb.zone_id
    evaluate_target_health = true
  }

  failover_routing_policy {
    type = "SECONDARY"
  }
  
  health_check_id = aws_route53_health_check.secondary.id
}

# Health Checks
resource "aws_route53_health_check" "primary" {
  fqdn              = aws_lb.app_lb.dns_name
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = 3
  request_interval  = 30
}

resource "aws_route53_health_check" "secondary" {
  fqdn              = aws_lb.app_lb.dns_name
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = 3
  request_interval  = 30
}

# Output the Load Balancer DNS
output "load_balancer_dns" {
  value = aws_lb.app_lb.dns_name
}


# Define providers
provider "aws" {
  region = "eu-north-1"
}

provider "google" {
  credentials = file("<PATH_TO_YOUR_GCP_CREDENTIALS_JSON>")
  project     = "wide-net-432004-a7"
  region      = "europe-north1"
}

# AWS EC2 Instances
resource "aws_instance" "web_server_aws" {
  count             = 2
  ami               = "ami-07a0715df72e58928"
  instance_type     = "t3.micro"
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name = "web-server-aws-${count.index}"
  }
}

# GCP VM Instances
resource "google_compute_instance" "web_server_gcp" {
  count        = 2
  name         = "web-server-gcp-${count.index}"
  machine_type = "e2-micro"
  zone         = element(data.google_compute_zones.available.names, count.index)

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10-buster-v20210701"
    }
  }

  network_interface {
    network = "default"
  }

  tags = ["web-server"]
}

# Data sources for availability zones and compute zones
data "aws_availability_zones" "available" {}

data "google_compute_zones" "available" {}

# AWS Application Load Balancer
resource "aws_lb" "app_lb" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["sg-089987654acd13"]  
  subnets            = ["<SUBNET_ID_1>", "<SUBNET_ID_2>"]  

  enable_deletion_protection = false
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Service is unavailable"
      status_code  = "503"
    }
  }
}

# AWS Target Group
resource "aws_lb_target_group" "web_targets" {
  name        = "web-targets"
  port        = 80
  protocol    = "HTTP"
  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold    = 2
    unhealthy_threshold  = 2
  }
}

resource "aws_lb_target_group_attachment" "aws_attachment" {
  count             = 2
  target_group_arn  = aws_lb_target_group.web_targets.arn
  target_id         = aws_instance.web_server_aws[count.index].id
  port              = 80
}

# Route 53 DNS Failover Configuration
resource "aws_route53_zone" "main" {
  name = "multicloud.mannu.xyz"
}

resource "aws_route53_record" "failover_primary" {
  zone_id = aws_route53_zone.main.id
  name    = "multicloud.mannu.xyz" 
  type    = "A"

  alias {
    name                   = aws_lb.app_lb.dns_name
    zone_id                = aws_lb.app_lb.zone_id
    evaluate_target_health = true
  }

  failover_routing_policy {
    type = "PRIMARY"
  }
  
  health_check_id = aws_route53_health_check.primary.id
}

resource "aws_route53_record" "failover_secondary" {
  zone_id = aws_route53_zone.main.id
  name    = "multicloud.mannu.xyz"  # Replace with your DNS record name
  type    = "A"

  alias {
    name                   = aws_lb.app_lb.dns_name
    zone_id                = aws_lb.app_lb.zone_id
    evaluate_target_health = true
  }

  failover_routing_policy {
    type = "SECONDARY"
  }
  
  health_check_id = aws_route53_health_check.secondary.id
}

# Health Checks
resource "aws_route53_health_check" "primary" {
  fqdn              = aws_lb.app_lb.dns_name
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = 3
  request_interval  = 30
}

resource "aws_route53_health_check" "secondary" {
  fqdn              = aws_lb.app_lb.dns_name
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = 3
  request_interval  = 30
}

# Output the Load Balancer DNS
output "load_balancer_dns" {
  value = aws_lb.app_lb.dns_name
}
