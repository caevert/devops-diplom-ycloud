#Сервисный аккаунт для S3 bucket terraform
// Create SA
resource "yandex_iam_service_account" "bucket-sa" {
  folder_id = var.folder_id
  name      = "bucketbot"
}

// Grant pemissions
resource "yandex_resourcemanager_folder_iam_member" "bucket-sa-editor" {
  folder_id = var.folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.bucket-sa.id}"
}


#Сервисный аккаунт для Yandex Compute Registry
// Create SA
resource "yandex_iam_service_account" "docker-sa" {
  folder_id = var.folder_id
  name      = "dockerbot"
}

// Grant pemissions
resource "yandex_resourcemanager_folder_iam_member" "docker-sa-editor" {
  folder_id = var.folder_id
  role      = "container-registry.admin"
  member    = "serviceAccount:${yandex_iam_service_account.docker-sa.id}"
}
