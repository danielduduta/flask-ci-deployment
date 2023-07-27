locals {
  service_name = var.k8s_service_name
  k8s_port = var.k8s_service_port
}

resource "kubernetes_deployment" "deployment" {
  metadata {
    name = local.service_name
    namespace = var.namespace
  }

  spec {
    replicas = var.replicas
    selector {
      match_labels = {
        app = local.service_name
      }
    }

    template {
      metadata {
        labels = {
          app = local.service_name
        }
      }

      spec {
        topology_spread_constraint {
          max_skew = 1
          topology_key = "topology.kubernetes.io/zone"
          when_unsatisfiable = "DoNotSchedule"
          label_selector {
            match_labels = {
              app = local.service_name
            }
          }
        }
        container {
          image = var.image
          name = local.service_name
          command = ["uwsgi", "--ini", "uwsgi.ini"]
        }
      }
    }
  }
}

resource "kubernetes_service" "service" {
  metadata {
    name = local.service_name
    namespace = var.namespace
  }
  spec {
    type = "ClusterIP"
    selector = {
      app = local.service_name
    }
    port {
      target_port = local.k8s_backend_port
      port = local.k8s_port
    }
  }
}

