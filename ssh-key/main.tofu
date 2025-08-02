# Set the variable value in *.tfvars file
# or using the -var="hcloud_token=..." CLI option
variable "hcloud_token" {}

provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_ssh_key" "airflow" {
  name = "apache-airflow-key"
  public_key = file("./id_rsa.pub")
}
