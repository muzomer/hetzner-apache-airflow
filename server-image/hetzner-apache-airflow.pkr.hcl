packer {
  required_plugins {
    hcloud = {
      version = ">= 1.0.0"
      source  = "github.com/hetznercloud/hcloud"
    }
  }
}

variable "hcloud_token" {
  description = "The Hetzner Cloud API token to use for authentication."
  type        = string
  sensitive   = true
}

variable "ssh_public_key_name" {
  description = "The name of the SSH key stored in the Hetzner Cloud to use for authentication."
  type        = string
  default     = "apache-airflow-key"
}

variable "db_name" {
  description = "The name of the Airflow database."
  type        = string
  default     = "airflowdb"
}

variable "db_username" {
  description = "The username for the Airflow database."
  type        = string
  default     = "airflow"
}

variable "db_password" {
  description = "The password for the Airflow database. This is sensitive and should be passed at runtime."
  type        = string
  sensitive   = true
}

variable "airflow_os_user" {
  description = "The username for the Airflow OS user"
  type        = string
  default     = "airflow"
}

variable "airflow_user_home" {
  description = "The home directory for the Airflow OS user"
  type        = string
  default     = "/home/airflow"
}

variable "airflow_version" {
  description = "The version of Airflow to install"
  type        = string
  default     = "3.0.3"
}

locals {
  timestamp_formatted = formatdate("YYYY-MM-DD-hhmmss", timestamp())
}

source "hcloud" "ubuntu" {
  token       = var.hcloud_token
  image       = "ubuntu-24.04"
  server_type = "cx22"
  location    = "nbg1"
  # Will appear as snapshot description in Hetzner images
  snapshot_name = "Apache Airflow - Ubuntu 24.04 - ${local.timestamp_formatted}"
  snapshot_labels = {
    name = "apache-airflow"
  }
  ssh_keys       = [var.ssh_public_key_name]
  ssh_username   = "root"
  ssh_agent_auth = true
}

build {
  sources = ["source.hcloud.ubuntu"]

  provisioner "shell" {
    environment_vars = [
      "DB_USERNAME=${var.db_username}",
      "DB_PASSWORD=${var.db_password}",
      "AIRFLOW_VERSION=${var.airflow_version}",
      "AIRFLOW_OS_USER=${var.airflow_os_user}",
      "AIRFLOW_USER_HOME=${var.airflow_user_home}",
    ]
    script = "templates/install_packages_and_create_db.sh"
  }

  # Environment Variables File
  provisioner "file" {
    content     = <<-EOF
      AIRFLOW_HOME=${var.airflow_user_home}/airflow
      AIRFLOW__API_AUTH__JWT_SECRET=${uuidv4()}
      AIRFLOW__DATABASE__SQL_ALCHEMY_CONN=postgresql+psycopg2://${var.db_username}:${var.db_password}@localhost/${var.db_name}
      AIRFLOW__CORE__AUTH_MANAGER=airflow.providers.fab.auth_manager.fab_auth_manager.FabAuthManager
      AIRFLOW__CORE__EXECUTOR=CeleryExecutor
    EOF
    destination = "/etc/default/airflow"
  }

  # Airflow DB Migration and User Creation
  provisioner "shell" {
    environment_vars = [
      "AIRFLOW_HOME=${var.airflow_user_home}/airflow",
      "AIRFLOW__CELERY__BROKER_URL=redis://localhost:6379/0",
      "AIRFLOW__CORE__AUTH_MANAGER=airflow.providers.fab.auth_manager.fab_auth_manager.FabAuthManager",
      "AIRFLOW__DATABASE__SQL_ALCHEMY_CONN=postgresql+psycopg2://${var.db_username}:${var.db_password}@localhost/${var.db_name}",
    ]
    inline = [
      "${var.airflow_user_home}/airflow_venv/bin/airflow db migrate",
      "${var.airflow_user_home}/airflow_venv/bin/airflow users create --username admin --role Admin --email admin@example.com --firstname Admin --lastname Admin --password admin",
    ]
  }

  # Airflow Scheduler Systemd Unit
  provisioner "file" {
    source      = "templates/systemd/airflow-scheduler.service"
    destination = "/etc/systemd/system/airflow-scheduler.service"
  }

  # Airflow Webserver Systemd Unit
  provisioner "file" {
    source      = "templates/systemd/airflow-api-server.service"
    destination = "/etc/systemd/system/airflow-api-server.service"
  }

  # Airflow Webserver Systemd Unit
  provisioner "file" {
    source      = "templates/systemd/airflow-celery-worker.service"
    destination = "/etc/systemd/system/airflow-celery-worker.service"
  }

  provisioner "shell" {
    inline = [
      "systemctl daemon-reload",
      "systemctl enable airflow-scheduler",
      "systemctl enable airflow-api-server",
      "systemctl enable airflow-celery-worker",
    ]
  }
}
