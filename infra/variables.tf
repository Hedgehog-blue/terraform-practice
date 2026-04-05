variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID for daria-test.pp.ua"
  type        = string
}

variable "root_domain" {
  description = "Main Cloudflare-managed domain"
  type        = string
  default     = "daria-test.pp.ua"
}

variable "aws_subdomain" {
  description = "Delegated subdomain managed by Route53"
  type        = string
  default     = "aws"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "public_key_path" {
  description = "Path to your local SSH public key"
  type        = string
}

variable "my_ip_cidr" {
  description = "Your public IP in CIDR form, example 1.2.3.4/32"
  type        = string
}
