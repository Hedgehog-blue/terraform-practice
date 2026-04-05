output "delegated_domain" {
  value = aws_route53_zone.delegated.name
}

output "route53_nameservers" {
  value = aws_route53_zone.delegated.name_servers
}

output "web_server_public_ip" {
  value = aws_instance.servers["web_server"].public_ip
}

output "app_server_public_ip" {
  value = aws_instance.servers["app"].public_ip
}

output "web_fqdn" {
  value = aws_route53_record.web.fqdn
}

output "app_fqdn" {
  value = aws_route53_record.app.fqdn
}
