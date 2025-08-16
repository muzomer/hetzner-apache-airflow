output "airflow_url" {
  value = "http://${hcloud_server.airflow.ipv4_address}:8080"
}

output "airflow_ip" {
  value = hcloud_server.airflow.ipv4_address
}
