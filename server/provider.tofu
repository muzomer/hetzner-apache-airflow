terraform {
  required_providers {
    hcloud = {
      source  = "hashicorp/hcloud"
      version = "1.52.0"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}
