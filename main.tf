terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.8"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "docker" {}
provider "kind" {}

provider "helm" {
  kubernetes {
    host                   = kind_cluster.main.endpoint
    cluster_ca_certificate = kind_cluster.main.cluster_ca_certificate
    client_certificate     = kind_cluster.main.client_certificate
    client_key             = kind_cluster.main.client_key
  }
}
