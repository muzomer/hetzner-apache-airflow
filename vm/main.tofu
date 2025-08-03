terraform {
  required_providers {
    hcloud = {
      source  = "hashicorp/hcloud"
      version = "1.52.0"
    }
  }
}

# Set the variable value in *.tfvars file
# or using the -var="hcloud_token=..." CLI option
variable "hcloud_token" {}

provider "hcloud" {
  token = var.hcloud_token
}

data "hcloud_image" "airflow" {
  most_recent = true
  with_selector = "name=apache-airflow"
}

resource "hcloud_server" "airflow" {
  name        = "apache-airflow"
  server_type = "cx22"
  image       = data.hcloud_image.airflow.id
  location    = "nbg1"
  ssh_keys    = ["apache-airflow-key"]
}


output "airflow_url" {
  value = "http://${hcloud_server.airflow.ipv4_address}:8080"
}

output "airflow_ip" {
  value = "hcloud_server.airflow.ipv4_address}"
}
