resource "docker_network" "db" {
  name = "db-net"
}

# --- etcd: кластер из 3 нод ---
resource "docker_image" "etcd" {
  name         = "quay.io/coreos/etcd:v3.5.16"
  keep_locally = true
}

locals {
  etcd_nodes   = ["etcd1", "etcd2", "etcd3"]
  etcd_cluster = join(",", [for n in local.etcd_nodes : "${n}=http://${n}:2380"])
}

resource "docker_container" "etcd" {
  for_each = toset(local.etcd_nodes)
  name     = each.key
  hostname = each.key
  image    = docker_image.etcd.image_id
  restart  = "unless-stopped"

  command = [
    "etcd",
    "--name=${each.key}",
    "--data-dir=/etcd-data",
    "--listen-client-urls=http://0.0.0.0:2379",
    "--advertise-client-urls=http://${each.key}:2379",
    "--listen-peer-urls=http://0.0.0.0:2380",
    "--initial-advertise-peer-urls=http://${each.key}:2380",
    "--initial-cluster=${local.etcd_cluster}",
    "--initial-cluster-state=new",
    "--initial-cluster-token=demo-etcd",
  ]

  networks_advanced {
    name = docker_network.db.name
  }
}

# --- 3 ноды Patroni ---
resource "docker_image" "spilo" {
  name         = "ghcr.io/zalando/spilo-17:4.0-p3"
  keep_locally = true
}

resource "docker_volume" "pgdata" {
  for_each = toset(["pg1", "pg2", "pg3"])
  name     = "${each.key}-data"
}

resource "docker_container" "pg" {
  for_each   = toset(["pg1", "pg2", "pg3"])
  name       = each.key
  hostname   = each.key
  image      = docker_image.spilo.image_id
  restart    = "unless-stopped"
  depends_on = [docker_container.etcd]

  env = [
    "SCOPE=pgcluster",
    "ETCD3_HOSTS=etcd1:2379,etcd2:2379,etcd3:2379",
    "PGPASSWORD_SUPERUSER=${random_password.pg_superuser.result}",
    "PGPASSWORD_ADMIN=${random_password.pg_admin.result}",
    "PGPASSWORD_STANDBY=${random_password.pg_standby.result}",
  ]

  volumes {
    volume_name    = docker_volume.pgdata[each.key].name
    container_path = "/home/postgres/pgdata"
  }

  networks_advanced {
    name = docker_network.db.name
  }
}
