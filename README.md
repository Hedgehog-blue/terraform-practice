# Terraform Infrastructure

## Description

This project provisions infrastructure using Terraform:

- Cloudflare domain (daria-test.pp.ua)
- AWS Route53 hosted zone for subdomain
- Two EC2 instances: web_server and app
- DNS records for both servers
- Security groups with restricted access

## Structure

All Terraform files are located in the `infra/` directory.

## Requirements

- Terraform installed
- AWS CLI configured
- Cloudflare API token
- SSH key

## Usage

```bash
cd infra
terraform init
terraform plan
terraform apply
```

##Notes
- Local backend is used
- Sensitive data is not committed
- SSH access is restricted by IP
