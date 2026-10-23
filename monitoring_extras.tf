resource "terraform_data" "monitoring_extras" {
  depends_on       = [helm_release.monitoring, terraform_data.app]
  triggers_replace = filemd5("${path.module}/k8s/monitoring-extras.yaml")

  provisioner "local-exec" {
    command = "kubectl --context kind-demo apply -f ${path.module}/k8s/monitoring-extras.yaml"
  }
}
