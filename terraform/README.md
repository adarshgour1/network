# TimescaleDB Terraform Setup

This directory contains Terraform configuration for setting up a TimescaleDB container locally.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html)
- [Docker](https://docs.docker.com/get-docker/)
- Docker permissions

## Configuration

The default configuration:

- Uses TimescaleDB 2.x with PostgreSQL 14
- Exposes port 5432
- Uses ephemeral storage (no persistent volume)
- Creates a database called `network_metrics`
- Uses default postgres/postgres for username/password

## Usage

```bash
# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Apply configuration
terraform apply

# To destroy the infrastructure
terraform destroy
```

## Initialization

After the container is running, the `init.sql` script from the `../db` directory will be automatically executed to create the necessary database structure.

**Note**: Since we're not using a persistent volume, the database will be recreated from scratch each time the Terraform configuration is applied. This ensures a clean environment for each deployment.

## Customization

You can customize the setup by editing the `variables.tf` file or by providing your own values:

```bash
terraform apply -var="db_user=myuser" -var="db_password=mypassword"
```
