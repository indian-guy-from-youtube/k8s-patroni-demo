resource "docker_image" "haproxy" {
  name         = "haproxy:3.0-alpine"
  keep_locally = true
}

resource "docker_container" "haproxy" {
  name       = "haproxy"
  hostname   = "haproxy"
  image      = docker_image.haproxy.image_id
  depends_on = [docker_container.pg, kind_cluster.main]

  ports {
    internal = 5000
    external = 5000
    ip       = "127.0.0.1"
  }
  ports {
    internal = 7000
    external = 7000
    ip       = "127.0.0.1"
  }

  upload {
    file    = "/usr/local/etc/haproxy/haproxy.cfg"
    content = <<-EOT
      global
        maxconn 200
      defaults
        mode tcp
        timeout connect 5s
        timeout client 30m
        timeout server 30m
        timeout check 3s
      listen postgres
        bind *:5000
        option httpchk GET /primary
        http-check expect status 200
        default-server inter 3s fall 3 rise 2 on-marked-down shutdown-sessions
        server pg1 pg1:5432 check port 8008
        server pg2 pg2:5432 check port 8008
        server pg3 pg3:5432 check port 8008
      listen patroni_pg1
        bind *:8081
        server pg1 pg1:8008
      listen patroni_pg2
        bind *:8082
        server pg2 pg2:8008
      listen patroni_pg3
        bind *:8083
        server pg3 pg3:8008
      listen stats
        mode http
        bind *:7000
        stats enable
        stats uri /
    EOT
  }

  networks_advanced {
    name = docker_network.db.name
  }
  networks_advanced {
    name = "kind"
  }
}
