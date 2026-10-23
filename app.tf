resource "terraform_data" "app_db" {
  depends_on = [docker_container.haproxy]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    environment = {
      PGPASSWORD = nonsensitive(random_password.pg_superuser.result)
      APP_PASS   = nonsensitive(random_password.app_db.result)
    }
    command = <<-EOT
      PSQL="timeout 20 docker run --rm --network db-net -e PGPASSWORD -e PGCONNECT_TIMEOUT=5 postgres:17-alpine psql -h haproxy -p 5000 -U postgres"

      for i in $(seq 1 60); do
        [ "$($PSQL -tA -c 'show transaction_read_only' 2>/dev/null)" = "off" ] && break
        echo "waiting for writable postgres leader..."; sleep 5
      done

      for i in $(seq 1 10); do
        $PSQL -tA -c "select 1 from pg_roles where rolname='app'" | grep -q 1 \
          || $PSQL -c "CREATE USER app WITH PASSWORD '$APP_PASS';"
        $PSQL -tA -c "select 1 from pg_database where datname='app'" | grep -q 1 \
          || $PSQL -c "CREATE DATABASE app OWNER app;"
        if $PSQL -tA -c "select 1 from pg_database where datname='app'" | grep -q 1; then
          exit 0
        fi
        echo "retrying..."; sleep 5
      done
      exit 1
    EOT
  }
}

resource "terraform_data" "app" {
  depends_on       = [terraform_data.app_db, helm_release.ingress_nginx]
  triggers_replace = filemd5("${path.module}/k8s/app.yaml")

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    environment = {
      APP_PASS = nonsensitive(random_password.app_db.result)
    }
    command = <<-EOT
      docker build -t notes:1.0.0 ${path.module}/app
      kind load docker-image notes:1.0.0 --name demo
      kubectl --context kind-demo create secret generic notes-db --from-literal=DB_USER=app --from-literal=DB_PASSWORD="$APP_PASS" --dry-run=client -o yaml | kubectl --context kind-demo apply -f -
      kubectl --context kind-demo apply -f ${path.module}/k8s/app.yaml
      kubectl --context kind-demo rollout status deploy/notes --timeout=300s
    EOT
  }
}
