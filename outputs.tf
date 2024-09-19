output "elb_public_dns_name" {
  description = "Public DNS name of the load balancer for this project"
  value       = module.alb_http.dns_name
}

output "bastion_host_public_ip" {
  description = "Public IP for bastion host"
  value       = [aws_instance.bastion_host[*].public_ip]

}

output "frontend_host_private_ip" {
  description = "Private IP for frontend instances"
  value       = [aws_instance.app_frontend[*].private_ip]
}

output "backend_host_private_ip" {
  description = "Private IP for backend instances"
  value       = [aws_instance.app_backend[*].private_ip]
}