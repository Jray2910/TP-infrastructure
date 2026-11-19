resource "docker_network" "test" {
  name = "websolutions-test"
}

resource "docker_volume" "db" {
  name = "websolutions-test-db"
}

resource "docker_image" "postgres" {
  name         = "postgres:16-alpine"
  keep_locally = true
}

resource "docker_container" "db" {
  name    = "websolutions-test-db"
  image   = docker_image.postgres.image_id
  restart = "unless-stopped"

  env = [
    "POSTGRES_USER=websolutions",
    "POSTGRES_DB=websolutions",
    "POSTGRES_PASSWORD=${var.db_password}",
  ]

  networks_advanced {
    name    = docker_network.test.name
    aliases = ["db"]
  }

  volumes {
    volume_name    = docker_volume.db.name
    container_path = "/var/lib/postgresql/data"
  }

  healthcheck {
    test     = ["CMD", "pg_isready", "-h", "127.0.0.1", "-U", "websolutions", "-d", "websolutions"]
    interval = "3s"
    timeout  = "2s"
    retries  = 20
  }

  wait         = true
  wait_timeout = 90
}

resource "docker_container" "api" {
  name    = "websolutions-test-api"
  image   = var.api_image
  restart = "unless-stopped"

  env = [
    "PGHOST=db",
    "PGUSER=websolutions",
    "PGDATABASE=websolutions",
    "PGPASSWORD=${var.db_password}",
  ]

  networks_advanced {
    name = docker_network.test.name
  }

  ports {
    internal = 3000
    external = 3002
    ip       = "127.0.0.1"
  }

  depends_on = [docker_container.db]
}

output "api_url" {
  value = "http://127.0.0.1:3002"
}

output "health_url" {
  value = "http://127.0.0.1:8082/health"
}
