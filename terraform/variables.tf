variable "db_user" {
  type        = string
  default     = "postgres"
  description = "Username for the TimescaleDB database"
}

variable "db_password" {
  type        = string
  default     = "postgres"
  description = "Password for the TimescaleDB database"
  sensitive   = true
}

variable "db_name" {
  type        = string
  default     = "network_metrics"
  description = "Name for the TimescaleDB database"
}

variable "db_port" {
  type        = number
  default     = 5432
  description = "Port for the TimescaleDB database"
}

# No data directory variable needed since we're not using persistent storage
