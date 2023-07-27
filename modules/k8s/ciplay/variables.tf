variable "replicas" {
  type = number
  description = "Number of pods to deploy"
}

variable "k8s_service_name" {
  type = string
  description = "K8S service to be deployed"
}

variable "k8s_service_port" {
  type = string
  description = "K8S service port"
}

