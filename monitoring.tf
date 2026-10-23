resource "helm_release" "monitoring" {
  name             = "monitoring"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true
  timeout          = 1800
  depends_on       = [helm_release.ingress_nginx, docker_container.haproxy]

  values = [<<-EOT
    kubeEtcd:
      enabled: false
    kubeControllerManager:
      enabled: false
    kubeScheduler:
      enabled: false
    kubeProxy:
      enabled: false
    prometheusOperator:
      admissionWebhooks:
        enabled: false
      tls:
        enabled: false
    prometheus:
      prometheusSpec:
        retention: 2d
        resources:
          requests:
            memory: 400Mi
        additionalScrapeConfigs:
          - job_name: patroni
            metrics_path: /metrics
            static_configs:
              - targets: ["haproxy:8081"]
                labels:
                  node: pg1
              - targets: ["haproxy:8082"]
                labels:
                  node: pg2
              - targets: ["haproxy:8083"]
                labels:
                  node: pg3
    alertmanager:
      alertmanagerSpec:
        resources:
          requests:
            memory: 50Mi
    grafana:
      adminPassword: ${random_password.grafana.result}
      ingress:
        enabled: true
        ingressClassName: nginx
        hosts:
          - grafana.local
        tls:
          - secretName: demo-tls
            hosts:
              - grafana.local
  EOT
  ]
}
