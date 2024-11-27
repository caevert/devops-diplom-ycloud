### Разворачиваем VPC
resource "yandex_vpc_network" "diplom-vpc2" {
  name        = "diplom-vpc2"
  description = "My diplom project vpc"
}

resource "yandex_vpc_subnet" "master-zone" {
  name           = "master-zone"
  zone           = var.master_node_network_settings.default_zone
  network_id     = yandex_vpc_network.diplom-vpc2.id
  v4_cidr_blocks = var.master_node_network_settings.v4_cidr_blocks
}

resource "yandex_vpc_subnet" "worker-zone1" {
  name           = "worker-zone1"
  zone           = var.worker_node_network_settings-a.default_zone
  network_id     = yandex_vpc_network.diplom-vpc2.id
  v4_cidr_blocks = var.worker_node_network_settings-a.v4_cidr_blocks
}

resource "yandex_vpc_subnet" "worker-zone2" {
  name           = "worker-zone2"
  zone           = var.worker_node_network_settings-b.default_zone
  network_id     = yandex_vpc_network.diplom-vpc2.id
  v4_cidr_blocks = var.worker_node_network_settings-b.v4_cidr_blocks
}
