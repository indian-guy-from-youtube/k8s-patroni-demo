resource "terraform_data" "security" {
  depends_on       = [terraform_data.app, helm_release.monitoring]
  triggers_replace = filemd5("${path.module}/k8s/security.yaml")

  provisioner "local-exec" {
    command = "kubectl --context kind-demo apply -f ${path.module}/k8s/security.yaml"
  }
}
