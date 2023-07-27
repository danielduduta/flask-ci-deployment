variable "image" {
  type = string
}

variable "replicas" {
  type = number
  description = "number of pods to run"
}

variable "dns_service_name" {
  type = string
}

variable "dns_zone_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_public_subnets" {
  type = list(string)
}


