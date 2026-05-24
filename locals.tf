# ------------------------------
# My IP
# ------------------------------
locals {
  my_ip = "${jsondecode(data.http.my_ip.response_body)["ip"]}/32"
}
