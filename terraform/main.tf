terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# No data directory needed since we're not using persistent storage

# TimescaleDB container
resource "docker_container" "timescaledb" {
  name  = "timescaledb"
  image = docker_image.timescaledb.image_id
  
  restart = "unless-stopped"
  
  env = [
    "POSTGRES_USER=postgres",
    "POSTGRES_PASSWORD=postgres",
    "POSTGRES_DB=network_metrics"
  ]
  
  ports {
    internal = 5432
    external = 5432
    protocol = "tcp"
  }
  
  # No volume mount - database will be recreated from scratch each time
  
  depends_on = [
    docker_image.timescaledb
  ]

  # Wait for database to be ready before running the initialization script
  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for TimescaleDB to be ready..."
      max_attempts=30
      attempt=0
      while [ $attempt -lt $max_attempts ]; do
        if docker exec timescaledb pg_isready -h localhost -U postgres; then
          echo "TimescaleDB is ready!"
          break
        fi
        attempt=$((attempt+1))
        echo "Attempt $attempt/$max_attempts: TimescaleDB not ready yet, waiting 5 seconds..."
        sleep 5
      done

      if [ $attempt -eq $max_attempts ]; then
        echo "TimescaleDB did not become ready in time."
        exit 1
      fi

      echo "Initializing fresh database with schema..."
      docker cp ${abspath(path.cwd)}/../db/init.sql timescaledb:/init.sql
      docker exec timescaledb psql -U postgres -d network_metrics -f /init.sql || echo "Failed to execute init.sql"
      
      echo "Loading sample data..."
      docker cp ${abspath(path.cwd)}/../db/data.sql timescaledb:/data.sql
      docker exec timescaledb psql -U postgres -d network_metrics -f /data.sql || echo "Failed to execute data.sql"
      echo "Database initialization complete - fresh database created with sample data."
    EOT
  }
}

# TimescaleDB image
resource "docker_image" "timescaledb" {
  name = "timescale/timescaledb:latest-pg14"
  keep_locally = true
}

output "timescaledb_container_id" {
  value = docker_container.timescaledb.id
}

output "timescaledb_ip" {
  value = docker_container.timescaledb.network_data[0].ip_address
}

output "timescaledb_state" {
  value = "Container deployed"
}
