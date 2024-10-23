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
  token     = "y0_AgAAAAAYAa0UAATuwQAAAAESsxOGAADi2FY-8JJN3boZ3IiB6CvIHlCToQ"
  cloud_id  = "b1g2ut41nofg2g17nhm4"
  folder_id = "b1g4noustnsrb4ejb93n"
  zone      = "ru-central1"
}
