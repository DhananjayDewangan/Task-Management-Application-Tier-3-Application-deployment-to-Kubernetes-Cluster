terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }
  }

  required_version = ">= 1.6.0"
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_namespace_v1" "task_management" {
  metadata {
    name = "task-management"
  }
}

resource "kubernetes_secret_v1" "postgres" {
  metadata {
    name      = "postgres-secret"
    namespace = kubernetes_namespace_v1.task_management.metadata[0].name
  }

  type = "Opaque"

  data = {
    POSTGRES_DB       = var.db_name
    POSTGRES_USER     = var.db_user
    POSTGRES_PASSWORD = var.db_password
  }
}

resource "kubernetes_persistent_volume_claim_v1" "postgres" {
  metadata {
    name      = "postgres-pvc"
    namespace = kubernetes_namespace_v1.task_management.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "1Gi"
      }
    }

    storage_class_name = "standard"
  }

  wait_until_bound = false
}

resource "kubernetes_deployment_v1" "postgres" {
  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace_v1.task_management.metadata[0].name
    labels = {
      app = "postgres"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "postgres"
      }
    }

    template {
      metadata {
        labels = {
          app = "postgres"
        }
      }

      spec {
        container {
          name  = "postgres"
          image = "postgres:17"

          port {
            container_port = 5432
          }

          env {
            name = "POSTGRES_DB"

            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.postgres.metadata[0].name
                key  = "POSTGRES_DB"
              }
            }
          }

          env {
            name = "POSTGRES_USER"

            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.postgres.metadata[0].name
                key  = "POSTGRES_USER"
              }
            }
          }

          env {
            name = "POSTGRES_PASSWORD"

            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.postgres.metadata[0].name
                key  = "POSTGRES_PASSWORD"
              }
            }
          }

          volume_mount {
            name       = "postgres-storage"
            mount_path = "/var/lib/postgresql/data"
          }
        }

        volume {
          name = "postgres-storage"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.postgres.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "postgres" {
  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace_v1.task_management.metadata[0].name
  }

  spec {
    selector = {
      app = "postgres"
    }

    port {
      port        = 5432
      target_port = 5432
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_deployment_v1" "backend" {
  metadata {
    name      = "backend"
    namespace = kubernetes_namespace_v1.task_management.metadata[0].name

    labels = {
      app = "backend"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "backend"
      }
    }

    template {
      metadata {
        labels = {
          app = "backend"
        }
      }

      spec {
        container {
          name  = "backend"
          image = "dhananjaydewangan/task-management-backend:1.0"

          port {
            container_port = 3000
          }

          env {
            name  = "DB_HOST"
            value = "postgres"
          }

          env {
            name  = "DB_PORT"
            value = "5432"
          }

          env {
            name = "DB_NAME"

            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.postgres.metadata[0].name
                key  = "POSTGRES_DB"
              }
            }
          }

          env {
            name = "DB_USER"

            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.postgres.metadata[0].name
                key  = "POSTGRES_USER"
              }
            }
          }

          env {
            name = "DB_PASSWORD"

            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.postgres.metadata[0].name
                key  = "POSTGRES_PASSWORD"
              }
            }
          }

          env {
            name  = "PORT"
            value = "3000"
          }
        }
      }
    }
  }
}