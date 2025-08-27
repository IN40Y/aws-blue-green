output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.web_alb.dns_name
}

output "website_url" {
  description = "The URL where the web server is accessible"
  value       = "http://${aws_lb.web_alb.dns_name}"
}

output "route53_url" {
  description = "The Route53 URL (if domain was provided)"
  value       = var.domain_name != "" ? "http://blue-green-demo.${var.domain_name}" : "No domain configured"
}
