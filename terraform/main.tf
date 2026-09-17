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
