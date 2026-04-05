locals {
  delegated_domain = "${var.aws_subdomain}.${var.root_domain}"

  instances = {
    web_server = {
      name = "web_server"
    }
    app = {
      name = "app"
    }
  }
}

data "aws_availability_zones" "available" {}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["137112412989"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_vpc" "main" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "terraform-main-vpc"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "terraform-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.10.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "terraform-public-subnet"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "terraform-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_key_pair" "main" {
  key_name   = "terraform-main-key"
  public_key = file(var.public_key_path)
}

resource "aws_security_group" "web_server" {
  name        = "web-server-sg"
  description = "Allow HTTP, HTTPS, and SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from world"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from world"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-server-sg"
  }
}

resource "aws_security_group" "app" {
  name        = "app-server-sg"
  description = "Allow 8080 from web server and SSH from my IP"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "8080 from web server"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.web_server.id]
  }

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "app-server-sg"
  }
}

resource "aws_instance" "servers" {
  for_each = local.instances

  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  key_name                    = aws_key_pair.main.key_name
  associate_public_ip_address = true

  vpc_security_group_ids = each.key == "web_server" ? [
    aws_security_group.web_server.id
    ] : [
    aws_security_group.app.id
  ]

  tags = {
    Name = each.value.name
  }
}

resource "aws_route53_zone" "delegated" {
  name = local.delegated_domain

  tags = {
    Name = local.delegated_domain
  }
}

resource "cloudflare_record" "delegation" {
  for_each = toset(aws_route53_zone.delegated.name_servers)

  zone_id = var.cloudflare_zone_id
  name    = var.aws_subdomain
  type    = "NS"
  content = each.value
  ttl     = 1
}

resource "aws_route53_record" "web" {
  zone_id = aws_route53_zone.delegated.zone_id
  name    = "web.${local.delegated_domain}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.servers["web_server"].public_ip]
}

resource "aws_route53_record" "app" {
  zone_id = aws_route53_zone.delegated.zone_id
  name    = "app.${local.delegated_domain}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.servers["app"].public_ip]
}
