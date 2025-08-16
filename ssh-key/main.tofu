resource "hcloud_ssh_key" "airflow" {
  name = "apache-airflow-key"
  public_key = file("./id_rsa.pub")
}
