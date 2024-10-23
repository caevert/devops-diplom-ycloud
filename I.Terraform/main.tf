### Разворачиваем мастер ноду
resource "yandex_compute_instance" "master-node" {
  platform_id = var.master_node_resources.platform_id
  name        = "master"
  zone        = var.master_node_network_settings.default_zone
  resources {
    cores         = var.master_node_resources.cores
    memory        = var.master_node_resources.memory
    core_fraction = var.master_node_resources.core_fraction
  }
  boot_disk {
    initialize_params {
      image_id = var.image_id
      name     = "master-node"
      type     = "network-hdd"
      size     = var.master_node_resources.storage_size
    }
  }
  scheduling_policy {
    preemptible = false
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.master-zone.id
    nat       = true
    ip_address = var.master_node_network_settings.ip_address
  }
  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
  }
}

### Разворачиваем воркеры
resource "yandex_compute_instance" "worker-node1" {
  platform_id = var.worker_nodes_resources.platform_id
  name        = "slave1"
  zone        = var.worker_node_network_settings-a.default_zone
  resources {
    cores         = var.worker_nodes_resources.cores
    memory        = var.worker_nodes_resources.memory
    core_fraction = var.worker_nodes_resources.core_fraction
  }
  boot_disk {
    initialize_params {
      image_id = var.image_id
      name     = "worker-node1"
      type     = "network-hdd"
      size     = var.worker_nodes_resources.storage_size
    }
  }
  scheduling_policy {
    preemptible = true
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.worker-zone1.id
    nat       = true
  }
  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
  }
}

resource "yandex_compute_instance" "worker-node2" {
  platform_id = var.worker_nodes_resources.platform_id
  name        = "slave2"
  zone        = var.worker_node_network_settings-b.default_zone
  resources {
    cores         = var.worker_nodes_resources.cores
    memory        = var.worker_nodes_resources.memory
    core_fraction = var.worker_nodes_resources.core_fraction
  }
  boot_disk {
    initialize_params {
      image_id = var.image_id
      name     = "worker-node2"
      type     = "network-hdd"
      size     = var.worker_nodes_resources.storage_size
    }
  }
  scheduling_policy {
    preemptible = true
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.worker-zone2.id
    nat       = true
  }
  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
  }
}

#Разворачиваем контейнер registry

