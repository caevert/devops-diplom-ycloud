# Получаем ключи сервисного аккаунта bucket-bot для работы с tfstate
output "access_key" {
  value = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  sensitive = true
}
output "secret_key" {
  value = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  sensitive = true
}

# Получаем IP адреса созданных нод
output "master_public_ip" {
  value = yandex_compute_instance.master-node.network_interface[0].nat_ip_address
}
output "master_internal_ip" {
  value = yandex_compute_instance.master-node.network_interface[0].ip_address
}
output "worker1_internal_ip" {
  value = yandex_compute_instance.worker-node1.network_interface[0].ip_address
}
output "worker1_public_ip" {
  value = yandex_compute_instance.worker-node1.network_interface[0].nat_ip_address
}
output "worker2_internal_ip" {
  value = yandex_compute_instance.worker-node2.network_interface[0].ip_address
}
output "worker2_public_ip" {
  value = yandex_compute_instance.worker-node2.network_interface[0].nat_ip_address
}
