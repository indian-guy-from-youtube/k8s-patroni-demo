resource "random_password" "pg_superuser" {
  length  = 20
  special = false
}
resource "random_password" "pg_admin" {
  length  = 20
  special = false
}
resource "random_password" "pg_standby" {
  length  = 20
  special = false
}
resource "random_password" "app_db" {
  length  = 20
  special = false
}
resource "random_password" "grafana" {
  length  = 20
  special = false
}

output "grafana_admin_password" {
  value     = random_password.grafana.result
  sensitive = true
}
