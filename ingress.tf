resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  timeout          = 600
  depends_on       = [kind_cluster.main]

  values = [<<-EOT
    controller:
      hostPort:
        enabled: true
      service:
        type: NodePort
      nodeSelector:
        ingress-ready: "true"
      tolerations:
        - key: node-role.kubernetes.io/control-plane
          operator: Equal
          effect: NoSchedule
      watchIngressWithoutClass: true
      config:
        ssl-redirect: "false"
      admissionWebhooks:
        enabled: false
  EOT
  ]
}
