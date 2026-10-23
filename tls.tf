resource "tls_private_key" "demo" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "demo" {
  private_key_pem       = tls_private_key.demo.private_key_pem
  validity_period_hours = 8760
  dns_names             = ["localhost", "grafana.local", "prometheus.local", "alertmanager.local"]

  subject {
    common_name = "demo.local"
  }

  allowed_uses = ["key_encipherment", "digital_signature", "server_auth"]
}

resource "terraform_data" "tls_secrets" {
  depends_on       = [helm_release.monitoring, terraform_data.app]
  triggers_replace = tls_self_signed_cert.demo.cert_pem

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    environment = {
      TLS_CRT = tls_self_signed_cert.demo.cert_pem
      TLS_KEY = nonsensitive(tls_private_key.demo.private_key_pem)
    }
    command = <<-EOT
      d=$(mktemp -d)
      printf '%s\n' "$TLS_CRT" > $d/tls.crt
      printf '%s\n' "$TLS_KEY" > $d/tls.key
      for ns in default monitoring; do
        kubectl --context kind-demo create secret tls demo-tls --cert=$d/tls.crt --key=$d/tls.key -n $ns --dry-run=client -o yaml | kubectl --context kind-demo apply -f -
      done
      rm -rf $d
    EOT
  }
}
