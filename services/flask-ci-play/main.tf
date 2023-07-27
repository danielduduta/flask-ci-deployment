locals {
  service_name = "ciplay"
  k8s_port = 5000
}

module "k8s" {
  source = "../../modules/k8s/ciplay"  
  replicas = var.replicas
  k8s_service_port = local.k8s_port
  k8s_service_name = local.service_name
}

module "aws" {
  source = "../../modules/aws/external_svc"  
  vpc_id = var.vpc_id
  vpc_public_subnets = var.vpc_public_subnets
  dns_zone_id = var.dns_zone_id
  dns_service_zone = var.dns_service_name
  k8s_service_name = local.service_name
  k8s_service_port = local.k8s_port
}
