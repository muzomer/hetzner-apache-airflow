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

