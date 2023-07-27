variable "vpc_id" {
  type = string
  description = "vpc where the ALB will be placed"
}

variable "vpc_public_subnets" {
  type = list(string)
  description = "subnets where the ALB will be placed"
}

variable "dns_zone_id" {
  type = string
  description = "route53 zone id where the dns_service_name record will get created"
}

variable "dns_service_name" {
  type = string
  description = "DNS records / endpoint where the service will be available"
}

variable "k8s_service_name" {
  type = string
  description = "k8s service name to reference in tg binding"
}

variable "k8s_service_port" {
  type = string
  description = "k8s service port to reference in tg binding"
}

