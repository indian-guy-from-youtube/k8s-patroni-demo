resource "kind_cluster" "main" {
  name           = "demo"
  wait_for_ready = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"
      kubeadm_config_patches = [
        "kind: InitConfiguration\nnodeRegistration:\n  kubeletExtraArgs:\n    node-labels: \"ingress-ready=true\"\n"
      ]
      extra_port_mappings {
        container_port = 80
        host_port      = 8088
      }
      extra_port_mappings {
        container_port = 443
        host_port      = 8443
      }
    }
    node {
      role = "worker"
    }
    node {
      role = "worker"
    }
  }
}
