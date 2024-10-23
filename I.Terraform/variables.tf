#cloud vars
variable "token" {
  type        = string
  description = "OAuth-token; https://cloud.yandex.ru/docs/iam/concepts/authorization/oauth-token"
}

variable "cloud_id" {
  type        = string
  default     = "b1g2ut41nofg2g17nhm4"
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/cloud/get-id"
}

variable "folder_id" {
  type        = string
  default     = "b1g4noustnsrb4ejb93n"
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/folder/get-id"
}

variable "ssh_public_key_path" {
  type    = string
  default = "~/.ssh/id_ed25519.pub"
}

variable "image_id" {
  type        = string
  default     = "fd8p2umr6e4i8n31bfu6"
  description = "Ubuntu 18.04"
}

variable "master_node_resources" {
  default = {
    platform_id = "standard-v2"
    cores = 2
    memory = 4
    core_fraction = 20
    storage_size = 50
  }
}

variable "worker_nodes_resources" {
  default = {
    platform_id = "standard-v1"
    cores = 2
    memory = 2
    core_fraction = 20
    storage_size = 50
  }
  
}

variable "master_node_network_settings" {
  default = {
    default_zone = "ru-central1-d"
    v4_cidr_blocks = ["192.168.10.0/24"]
    ip_address = "192.168.10.100"
  }  
}

variable "worker_node_network_settings-a" {
  default = {
    default_zone = "ru-central1-a"
    v4_cidr_blocks = ["192.168.100.0/24"]
    ip_address = "192.168.100.101"
  }  
}

variable "worker_node_network_settings-b" {
  default = {
    default_zone = "ru-central1-b"
    v4_cidr_blocks = ["192.168.200.0/24"]
    ip_address = "192.168.200.202"
  }  
}
