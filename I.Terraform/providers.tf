terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
    }
  }
  required_version = ">=0.13"

  backend "s3" {
    endpoints  = {
      s3 = "https://storage.yandexcloud.net"
    }
    bucket     = "tf-state-bucket-caevert"
    region     = "ru-central1"
    key        = "terraform/infrastructure1/terraform.tfstate"
    access_key = "YCAJEgI9CgLdtrLvwN9ZxdUQk"
    secret_key = "YCNvdpzQ8r0vAl7WT4kSne18OM_483oEgqfw4_Oy"
      
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }

}
provider "yandex" {
  token     = var.token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  #   zone      = "ru-central1"
}

