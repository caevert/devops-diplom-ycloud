# Дипломный практикум в Yandex.Cloud - Антон Жандаров
  * [Цели:](#цели)
  * [Этапы выполнения:](#этапы-выполнения)
     * [Создание облачной инфраструктуры](#создание-облачной-инфраструктуры)
     * [Создание Kubernetes кластера](#создание-kubernetes-кластера)
     * [Создание тестового приложения](#создание-тестового-приложения)
     * [Подготовка cистемы мониторинга и деплой приложения](#подготовка-cистемы-мониторинга-и-деплой-приложения)
     * [Установка и настройка CI/CD](#установка-и-настройка-cicd)
  * [Что необходимо для сдачи задания?](#что-необходимо-для-сдачи-задания)
  * [Как правильно задавать вопросы дипломному руководителю?](#как-правильно-задавать-вопросы-дипломному-руководителю)

**Перед началом работы над дипломным заданием изучите [Инструкция по экономии облачных ресурсов](https://github.com/netology-code/devops-materials/blob/master/cloudwork.MD).**

---
## Цели:

1. Подготовить облачную инфраструктуру на базе облачного провайдера Яндекс.Облако.
2. Запустить и сконфигурировать Kubernetes кластер.
3. Установить и настроить систему мониторинга.
4. Настроить и автоматизировать сборку тестового приложения с использованием Docker-контейнеров.
5. Настроить CI для автоматической сборки и тестирования.
6. Настроить CD для автоматического развёртывания приложения.

---
## Этапы выполнения:


### Создание облачной инфраструктуры

Для начала необходимо подготовить облачную инфраструктуру в ЯО при помощи [Terraform](https://www.terraform.io/).

Особенности выполнения:

- Бюджет купона ограничен, что следует иметь в виду при проектировании инфраструктуры и использовании ресурсов;
Для облачного k8s используйте региональный мастер(неотказоустойчивый). Для self-hosted k8s минимизируйте ресурсы ВМ и долю ЦПУ. В обоих вариантах используйте прерываемые ВМ для worker nodes.

Предварительная подготовка к установке и запуску Kubernetes кластера.

Предварительная подготовка к установке и запуску Kubernetes кластера.

1. Создайте сервисный аккаунт, который будет в дальнейшем использоваться Terraform для работы с инфраструктурой с необходимыми и достаточными правами. Не стоит использовать права суперпользователя
2. Подготовьте [backend](https://www.terraform.io/docs/language/settings/backends/index.html) для Terraform:  
   а. Рекомендуемый вариант: S3 bucket в созданном ЯО аккаунте(создание бакета через TF)
   б. Альтернативный вариант:  [Terraform Cloud](https://app.terraform.io/)
3. Создайте конфигурацию Terrafrom, используя созданный бакет ранее как бекенд для хранения стейт файла. Конфигурации Terraform для создания сервисного аккаунта и бакета и основной инфраструктуры следует сохранить в разных папках.
4. Создайте VPC с подсетями в разных зонах доступности.
5. Убедитесь, что теперь вы можете выполнить команды `terraform destroy` и `terraform apply` без дополнительных ручных действий.
6. В случае использования [Terraform Cloud](https://app.terraform.io/) в качестве [backend](https://www.terraform.io/docs/language/settings/backends/index.html) убедитесь, что применение изменений успешно проходит, используя web-интерфейс Terraform cloud.
   Ожидаемые результаты:

1. Terraform сконфигурирован и создание инфраструктуры посредством Terraform возможно без дополнительных ручных действий.

[Конфигурация terraform](I.Terraform/)

![Terraform apply](./assets/T-1.png)

![Service accounts](./assets/Service%20accounts%20YC.png)

![S3 backend for terraform tfstate in YC Object Storage](./assets/T-2.png)

VMS in YC
```
+----------------------+--------+---------------+---------+----------------+----------------+
|          ID          |  NAME  |    ZONE ID    | STATUS  |  EXTERNAL IP   |  INTERNAL IP   |
+----------------------+--------+---------------+---------+----------------+----------------+
| epdjehfpdpfalutkuep9 | slave2 | ru-central1-b | RUNNING | 158.160.69.16 | 192.168.200.20  |
| fhm2630o4n2btldi565o | slave1 | ru-central1-a | RUNNING | 130.193.38.67 | 192.168.100.34 |
| fv485411t4bqp5mff2dt | master | ru-central1-d | RUNNING | 84.252.133.212  | 192.168.10.100 
```
2. Полученная конфигурация инфраструктуры является предварительной, поэтому в ходе дальнейшего выполнения задания возможны изменения.

---
### Создание Kubernetes кластера

2. Подготовьте [backend](https://www.terraform.io/docs/language/settings/backends/index.html) для Terraform:  
   а. Рекомендуемый вариант: S3 bucket в созданном ЯО аккаунте(создание бакета через TF)
   б. Альтернативный вариант:  [Terraform Cloud](https://app.terraform.io/)  

Применяем изменения и узнаем значения ключей
```
terraform plan
terraform apply
terraform output s3_access_key
terraform output s3_secret_key
```
Далее прописываем их значение в конфигурации `s3 backend` в файле `providers.tf` (примечание - в момент создания бакета нижеприведенный блок кода по инициализации `s3 backend` закомментирован, так как нельзя настроить удаленное хранение состояния конфигурации терраформ в бакете, не создав при этом сам бакет).
```tf
 backend "s3" {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
   }
    bucket                      = "diplom-project-khoroshevlv"
    region                      = "ru-central1"
    key                         = "terraform.tfstate"
    access_key                  = <my access_key>
    secret_key                  = <my access_key>
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}
```
Инициализируем инфраструктуру
```
terraform init
```

![Alt_text](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/blob/main/screenshots/diplom1.png)
![Alt_text](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/blob/main/screenshots/diplom2.png)

3. Создайте VPC с подсетями в разных зонах доступности.

```tf
resource "yandex_vpc_network" "my_vpc" {
  name = var.VPC_name
}

resource "yandex_vpc_subnet" "public_subnet" {
  count = length(var.public_subnet_zones)
  name  = "${var.public_subnet_name}-${var.public_subnet_zones[count.index]}"
  v4_cidr_blocks = [
    cidrsubnet(var.public_v4_cidr_blocks[0], 4, count.index)
  ]
  zone       = var.public_subnet_zones[count.index]
  network_id = yandex_vpc_network.my_vpc.id
}
```
К терраформ коду указываем следующие переменные:
```tf
### vpc vars

variable "VPC_name" {
  type        = string
  default     = "my-vpc"
}

### subnet vars

variable "public_subnet_name" {
  type        = string
  default     = "public"
}

variable "public_v4_cidr_blocks" {
  type        = list(string)
  default     = ["192.168.10.0/24"]
}

variable "subnet_zone" {
  type        = string
  default     = "ru-central1"
}

variable "public_subnet_zones" {
  type    = list(string)
  default = ["ru-central1-a", "ru-central1-b",  "ru-central1-d"]
}
```
4. Убедитесь, что теперь вы можете выполнить команды `terraform destroy` и `terraform apply` без дополнительных ручных действий.

При выполнении команды `terraform destroy` удаляются все вычислительные ресурсы, кроме нашего бакета и загруженного в него `terraform.tfstate`, а также созданной нами сети `my-vpc` (лжидаемый результат).

Применяем изменения и проверяем инфраструктуру
```
terraform apply
terraform state list
```

![Alt_text](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/blob/main/screenshots/diplom3.png)


5. В случае использования [Terraform Cloud](https://app.terraform.io/) в качестве [backend](https://www.terraform.io/docs/language/settings/backends/index.html) убедитесь, что применение изменений успешно проходит, используя web-интерфейс Terraform cloud.

Ожидаемые результаты:

1. Terraform сконфигурирован и создание инфраструктуры посредством Terraform возможно без дополнительных ручных действий.
2. Полученная конфигурация инфраструктуры является предварительной, поэтому в ходе дальнейшего выполнения задания возможны изменения.

---
### Создание Kubernetes кластера

На этом этапе необходимо создать [Kubernetes](https://kubernetes.io/ru/docs/concepts/overview/what-is-kubernetes/) кластер на базе предварительно созданной инфраструктуры.   Требуется обеспечить доступ к ресурсам из Интернета.

Это можно сделать двумя способами:

1. Рекомендуемый вариант: самостоятельная установка Kubernetes кластера.  
   а. При помощи Terraform подготовить как минимум 3 виртуальных машины Compute Cloud для создания Kubernetes-кластера. Тип виртуальной машины следует выбрать самостоятельно с учётом требовании к производительности и стоимости. Если в дальнейшем поймете, что необходимо сменить тип инстанса, используйте Terraform для внесения изменений.

В целях экономии выделенного бюджета и с учетом ресурсоемкости создадим кластер из одной `control-plane` ноды и двух `worker` нод.

Конфиграция `control-plane` ноды:
```tf
resource "yandex_compute_instance" "control-plane" {
  name            = var.control_plane_name
  platform_id     = var.platform
  resources {
    cores         = var.control_plane_core
    memory        = var.control_plane_memory
    core_fraction = var.control_plane_core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = var.control_plane_disk_size
    }
  }

  scheduling_policy {
    preemptible = var.scheduling_policy
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.public_subnet[0].id
    nat       = var.nat
  }

  metadata = {
    user-data = "${file("/home/leo/kuber-homeworks/3.2/terraform/cloud-init.yaml")}"
 }
}
```
Переменные:
```tf
### control-plane node vars

variable "control_plane_name" {
  type        = string
  default     = "control-plane"
}

variable "platform" {
  type        = string
  default     = "standard-v1"
}

variable "control_plane_core" {
  type        = number
  default     = "4"
}

variable "control_plane_memory" {
  type        = number
  default     = "8"
}

variable "control_plane_core_fraction" {
  description = "guaranteed vCPU, for yandex cloud - 20, 50 or 100 "
  type        = number
  default     = "20"
}

variable "control_plane_disk_size" {
  type        = number
  default     = "50"
}

variable "image_id" {
  type        = string
  default     = "fd893ak78u3rh37q3ekn"
}

variable "scheduling_policy" {
  type        = bool
  default     = "true"
}
```
Конфигурация `worker` нод:
```tf
resource "yandex_compute_instance" "worker" {
  count           = var.worker_count
  name            = "worker-node-${count.index + 1}"
  platform_id     = var.worker_platform
  zone = var.public_subnet_zones[count.index]
  resources {
    cores         = var.worker_cores
    memory        = var.worker_memory
    core_fraction = var.worker_core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = var.worker_disk_size
    }
  }

    scheduling_policy {
    preemptible = var.scheduling_policy
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.public_subnet[count.index].id
    nat       = var.nat
  }

  metadata = {
    user-data = "${file("/home/leo/diplom/terraform/cloud-init.yaml")}"
 }
}
```
Переменные:
```tf
### worker nodes vars

variable "worker_count" {
  type        = number
  default     = "2"
}

variable "worker_platform" {
  type        = string
  default     = "standard-v1"
}

variable "worker_cores" {
  type        = number
  default     = "4"
}

variable "worker_memory" {
  type        = number
  default     = "2"
}

variable "worker_core_fraction" {
  description = "guaranteed vCPU, for yandex cloud - 20, 50 or 100 "
  type        = number
  default     = "20"
}

variable "worker_disk_size" {
  type        = number
  default     = "50"
}

variable "nat" {
  type        = bool
  default     = "true"
}
```
Для всех виртуальных машин используется `cloud-init.yaml` следующей конфигурации:
```yml
#cloud-config
users:
  - name: leo
    ssh_authorized_keys:
      - ssh-rsa <public_key>
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    groups: sudo
    shell: /bin/bash
package_update: true
package_upgrade: true
packages:
  - nginx
  - nano
  - software-properties-common
runcmd:
  - mkdir -p /home/leo/.ssh
  - chown -R leo:leo /home/leo/.ssh
  - chmod 700 /home/leo/.ssh
  - sudo add-apt-repository ppa:deadsnakes/ppa -y
  - sudo apt-get update
```
   б. Подготовить [ansible](https://www.ansible.com/) конфигурации, можно воспользоваться, например [Kubespray](https://kubespray.io/#/)
  
Скачиваем репозиторий с `Kubespray`
```
git clone https://github.com/kubernetes-sigs/kubespray
```
Устанавливаем зависимости
```
python3.10 -m pip install --upgrade pip
pip3 install -r requirements.txt
```
Копируем шаблон с  `inventory` файлом
```
cp -rfp inventory/sample inventory/mycluster
```
Корректируем файл `inventory.ini`, где прописываем актуальные ip адреса виртуальных машин, развернутых в предвдущих пунктах, в качестве CRI будем использовать `containerd`, а запуск `etcd` будет осущуствляться на мастере.
```
# ## Configure 'ip' variable to bind kubernetes services on a
# ## different ip than the default iface
# ## We should set etcd_member_name for etcd cluster. The node that is not a etcd member do not need to set the value, or can set the empty string value.
[all]
node1 ansible_host=51.250.71.251   ansible_user=leo ansible_ssh_private_key_file=~/.ssh/id_rsa # ip=192.168.10.7  etcd_member_name=etcd1
node2 ansible_host=84.201.174.252  ansible_user=leo ansible_ssh_private_key_file=~/.ssh/id_rsa # ip=192.168.10.10 etcd_member_name=etcd2
node3 ansible_host=89.169.166.190  ansible_user=leo ansible_ssh_private_key_file=~/.ssh/id_rsa # ip=192.168.10.19 etcd_member_name=etcd3
# node4 ansible_host=95.54.0.15   # ip=10.3.0.4 etcd_member_name=etcd4
# node5 ansible_host=95.54.0.16   # ip=10.3.0.5 etcd_member_name=etcd5
# node6 ansible_host=95.54.0.17   # ip=10.3.0.6 etcd_member_name=etcd6

# ## configure a bastion host if your nodes are not directly reachable
# [bastion]
# bastion ansible_host=x.x.x.x ansible_user=some_user

[kube_control_plane]
node1
# node2
# node3

[etcd]
 node1
# node2
# node3

[kube_node]
node2
node3
# node4
# node5
# node6

[calico_rr]

[k8s_cluster:children]
kube_control_plane
kube_node
calico_rr
```
   в. Задеплоить Kubernetes на подготовленные ранее инстансы, в случае нехватки каких-либо ресурсов вы всегда можете создать их при помощи Terraform.
```
ansible-playbook -i inventory/mycluster/inventory.ini cluster.yml -b -v
```

![Alt_text](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/blob/main/screenshots/diplom4.png)

2. Альтернативный вариант: воспользуйтесь сервисом [Yandex Managed Service for Kubernetes](https://cloud.yandex.ru/services/managed-kubernetes)  
  а. С помощью terraform resource для [kubernetes](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/kubernetes_cluster) создать **региональный** мастер kubernetes с размещением нод в разных 3 подсетях      
  б. С помощью terraform resource для [kubernetes node group](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/kubernetes_node_group)

Альтернативный вариант рассмотрен в одном из [домашних заданий](https://github.com/LeonidKhoroshev/clopro-homeworks/blob/main/15.4.md), где бул подготовлен соответствующий [манифест](https://github.com/LeonidKhoroshev/clopro-homeworks/blob/hw-15.4.1/main.tf), но для выполнения дипломного проекта готовый кластер `Yandex Managed Service for Kubernetes` дороже подготовленного самостоятельно в варианте 1.
  
Ожидаемый результат:

1. Работоспособный Kubernetes кластер.
Подключаемся к `control-plane` ноде 
```
ssh leo@51.250.71.251
```
Проверяем, что кластер состоит из одной `control-plane` ноды и двух `worker` нод
```
kubectl get nodes
```

![Alt_text](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/blob/main/screenshots/diplom6.png)
3. В файле `~/.kube/config` находятся данные для доступа к кластеру.
```
cat ~/.kube/config
```

![Alt_text](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/blob/main/screenshots/diplom5.png)

4. Команда `kubectl get pods --all-namespaces` отрабатывает без ошибок.

![Alt_text](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/blob/main/screenshots/diplom7.png)

---

В качестве промежуточного итога прилагаю terraform манифест и файлы, необходимые для создания инфраструктуры, описанной выше:

[main.tf](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/blob/terraform/main.tf)

[variables.tf](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/blob/terraform/variables.tf)

[providers.tf](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/blob/terraform/providers.tf)

[outputs.tf](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/blob/terraform/outputs.tf)

[cloud-init.yaml](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/blob/terraform/cloud-init.yaml)

[inventory.ini](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/blob/terraform/inventory.ini)

### Создание тестового приложения

Для перехода к следующему этапу необходимо подготовить тестовое приложение, эмулирующее основное приложение разрабатываемое вашей компанией.

Способ подготовки:

1. Рекомендуемый вариант:  
   а. Создайте отдельный git репозиторий с простым nginx конфигом, который будет отдавать статические данные.

В соответствии с рекомендуемым вариантом создан репозиторий [nginx-static](https://github.com/LeonidKhoroshev/nginx-static/tree/main)

Далее копируем репозиторий на виртуальную машину в одноименную директорию
```
git init
git clone https://github.com/LeonidKhoroshev/nginx-static.git
```
Создаем внутри проекта директорию `static` и в ней указываем конфигурацию файла основной стартовой страницы [index.html](https://github.com/LeonidKhoroshev/nginx-static/blob/main/static/index.html) и [styles.css](https://github.com/LeonidKhoroshev/nginx-static/blob/main/static/styles.css), созданного для улучшения внешнего вида нашей веб-страницы. Также создаем директорию [images](https://github.com/LeonidKhoroshev/nginx-static/tree/main/images) для хранения там фоновой картинки.
  
   б. Подготовьте Dockerfile для создания образа приложения.  

Переходим в корневую директорию и создаем `Dockerfile` следующей конфигурации
```
FROM nginx:latest

COPY ./static /usr/share/nginx/html

EXPOSE 80
```
Сохраняем изменения в ветке `main` нашего репозитория:
```
git add .
git commit -m "first commit"
git push https://github.com/LeonidKhoroshev/nginx-static main
```
Далее авторизовываемся на [DockerHub](https://hub.docker.com) и в консоли и собираем `docker` образ
```
docker login
docker build -t leonid1984/nginx-static:latest .
```

![Alt_text](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/blob/main/screenshots/diplom12.png)

И размещаем его в нашем хранилище на `DockerHub`
```
docker push leonid1984/nginx-static:latest
```

![Alt_text](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/blob/main/screenshots/diplom13.png)

![Alt_text](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/blob/main/screenshots/diplom14.png)

2. Альтернативный вариант:  
   а. Используйте любой другой код, главное, чтобы был самостоятельно создан Dockerfile.

Ожидаемый результат:

1. [Git репозиторий](https://github.com/LeonidKhoroshev/nginx-static) с тестовым приложением и [Dockerfile](https://github.com/LeonidKhoroshev/nginx-static/blob/main/Dockerfile).
2. Регистри с собранным [docker image](https://hub.docker.com/repository/docker/leonid1984/nginx-static/general). В качестве регистри может быть DockerHub или Yandex Container Registry, созданный также с помощью terraform.

---
### Подготовка cистемы мониторинга и деплой приложения

Уже должны быть готовы конфигурации для автоматического создания облачной инфраструктуры и поднятия Kubernetes кластера.  
Теперь необходимо подготовить конфигурационные файлы для настройки нашего Kubernetes кластера.

Цель:
1. Задеплоить в кластер [prometheus](https://prometheus.io/), [grafana](https://grafana.com/), [alertmanager](https://github.com/prometheus/alertmanager), [экспортер](https://github.com/prometheus/node_exporter) основных метрик Kubernetes.

Выполним установку вышеуказанных мониторингов через `helm`. Сначала установим `helm` на `control-plane` ноду
```
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
```
Создаем отдельное простанство имен для мониторинга
```
kubectl create namespace monitoring
```
Добавляем репозиторий `helm` c `prometheus`
```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
```
Устанавливаем `kube-prometheus-stack` (установка `Prometheus`, `Grafana`, `Alertmanager`, `node-exporter` и `kube-state-metrics`)
```
helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring
```
Проверяем, что все поры работают нормально
```
kubectl get pods -n monitoring
```

![Alt_text](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/blob/main/screenshots/diplom8.png)

Получаем пароль от `Grafana`
```
kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```
Настраиваем доступ к `Grafana` по внешнему ip адресу, для чего создаем файл values.yml
```yml
grafana:
  service:
    type: NodePort
    nodePort: 32000 
```
Обновляем `helm` чарт
```
helm upgrade prometheus prometheus-community/kube-prometheus-stack -n monitoring -f values.yml
```

![Alt_text](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/blob/main/screenshots/diplom9.png)

Далее настраиваем необходимые метрики, так для k8s кластера. Для простоты воспользуемся готовым дашбордом из того, что предлагает `Grafana` - [ID 315](https://grafana.com/grafana/dashboards/315-kubernetes-cluster-monitoring-via-prometheus/)

Проверем наличие новых дашбордов

![Alt_text](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/blob/main/screenshots/diplom10.png)

Видим, что из кластера поступают данные, но в пока мы не деплоили наше приложение, мониторинг не слишком информативен ввиду отсутствия рабочей нагрузки

![Alt_text](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/blob/main/screenshots/diplom11.png)


2. Задеплоить тестовое приложение, например, [nginx](https://www.nginx.com/) сервер отдающий статическую страницу.

Cоздаем деплой `nginx-deployment.yml`, куда прописываем следующую конфигурацию
```yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-static
  labels:
    app: nginx-static
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx-static
  template:
    metadata:
      labels:
        app: nginx-static
    spec:
      containers:
        - name: nginx
          image: leonid1984/nginx-static:latest
          ports:
            - containerPort: 80
```
Также нам необходим сервис `nginx-service.yml`
```yml
piVersion: v1
kind: Service
metadata:
  name: nginx-static
  labels:
    app: nginx-static
spec:
  type: NodePort
  ports:
    - port: 80
      targetPort: 80
      nodePort: 32001
  selector:
    app: nginx-static
```

Применяем изменения и проверяем результат
```
kubectl apply -f nginx-deployment.yml
kubectl apply -f nginx-service.yml
kubectl get pods -l app=nginx-static
```

![Alt_text](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/blob/main/screenshots/diplom15.png)
![Alt_text](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/blob/main/screenshots/diplom16.png)



Способ выполнения:
1. Воспользоваться пакетом [kube-prometheus](https://github.com/prometheus-operator/kube-prometheus), который уже включает в себя [Kubernetes оператор](https://operatorhub.io/) для [grafana](https://grafana.com/), [prometheus](https://prometheus.io/), [alertmanager](https://github.com/prometheus/alertmanager) и [node_exporter](https://github.com/prometheus/node_exporter). Альтернативный вариант - использовать набор helm чартов от [bitnami](https://github.com/bitnami/charts/tree/main/bitnami).

2. Если на первом этапе вы не воспользовались [Terraform Cloud](https://app.terraform.io/), то задеплойте и настройте в кластере [atlantis](https://www.runatlantis.io/) для отслеживания изменений инфраструктуры. Альтернативный вариант 3 задания: вместо Terraform Cloud или atlantis настройте на автоматический запуск и применение конфигурации terraform из вашего git-репозитория в выбранной вами CI-CD системе при любом комите в main ветку. Предоставьте скриншоты работы пайплайна из CI/CD системы.

Ожидаемый результат:
1. [Git репозиторий](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/tree/k8s) с конфигурационными файлами для настройки Kubernetes (в качестве конфигурационных файлов представлены деплой [nginx-deployment.yml](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/blob/k8s/nginx-deployment.yml) и сервис [nginx-service.yml](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/blob/k8s/nginx-service.yml) для развертывания нашей тестовой страницы).
2. Http доступ к [web интерфейсу grafana](http://89.169.145.151:32000/?orgId=1).
3. [Дашборды в grafana](http://89.169.145.151:32000/dashboards) отображающие состояние Kubernetes кластера.
4. Http доступ к [тестовому приложению](http://89.169.145.151:32001/).
   
---
### Установка и настройка CI/CD

Осталось настроить ci/cd систему для автоматической сборки docker image и деплоя приложения при изменении кода.

Цель:

1. Автоматическая сборка docker образа при коммите в репозиторий с тестовым приложением.
2. Автоматический деплой нового docker образа.

Можно использовать [teamcity](https://www.jetbrains.com/ru-ru/teamcity/), [jenkins](https://www.jenkins.io/), [GitLab CI](https://about.gitlab.com/stages-devops-lifecycle/continuous-integration/) или GitHub Actions.

Для настройки CI/CD процессов нашего проекта выбран `Jenkins` как наиболее широко применяемое open-source решение. Ранее в соответствующем модуле обучения установка `Jenkins` была описана посредством  создания двух виртуальных машин `jenkins-master` и `jenkins-agent` на базе следующего [кода terraform](https://github.com/LeonidKhoroshev/terraform-team). В целях экономии вычислительных ресурсов, а также общей архитектуры и логики работы нашей инфраструктуры в данном задании выбран вариант запуска `Jenkins` в k8s по следующей [инструкции](https://www.jenkins.io/doc/book/installing/kubernetes/).

Копируем репозиторий
```
git clone https://github.com/scriptcamp/kubernetes-jenkins
```
Создаем новое пространство имен, чтобы было проще отслеживать работу подов и сервисов
```
kubectl create namespace devops-tools
```
Создаем сервисный аккаунт для `Jenkins`, оставляя без изменений файл `serviceAccount.yaml` из скачанного репозитория
```
kubectl apply -f serviceAccount.yaml
```
Указываем в `deployment.yaml` тома постоянного хранения данных (настройки пользователя, пайплайны и т.д., так как наш кластер использует ради экономии прерываемые виртуальные машины).
```yml
volumeMounts:
            - name: jenkins-data
              mountPath: /var/jenkins_home
            - name: docker-socket
              mountPath: /var/run/docker.sock
            - name: docker-bin
              mountPath: /tmp/docker-bin

volumes:
        - name: jenkins-data
          persistentVolumeClaim:
            claimName: jenkins-pvc
        - name: docker-socket
          hostPath:
            path: /var/run/docker.sock
        - name: docker-bin
          emptyDir: {}
```
И соответственно создаем требуемый `persistent volume`
```yml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: jenkins-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  hostPath:
    path: "/var/jenkins_home"
```
А также `persistent volume claim`
```yml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: jenkins-pvc
  namespace: devops-tools
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```
Для корректной работы необходимо создать директорию `/var/jenkins_home` на всех нодах нашего кластера, для чего необходимо в `deployment.yaml` добавить инитконтейнер, устанавливающий `docker` и `git`
```yml
initContainers:
        - name: install-docker-git
          image: ubuntu:22.04
          command:
          - sh
          - -c
          - |
            apt-get update && \
            apt-get install -y curl gnupg && \
            curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
            echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian bullseye stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
            apt-get update && \
            apt-get install -y docker-ce-cli && \
            mkdir -p /tmp/docker-bin && \
            cp /usr/bin/docker /tmp/docker-bin/docker
            apt-get install -y git
          volumeMounts:
          - name: docker-bin
            mountPath: /tmp/docker-bin
          - name: jenkins-data
            mountPath: /var/jenkins_home
          - name: docker-socket
            mountPath: /var/run/docker.sock
```

Применяем изменения и проверяем успешный запуск `Jenkins`
```
kubectl apply -f pv.yaml
kubectl apply -f pvc.yaml
kubectl apply -f deployment.yaml
kubectl get deployments -n devops-tools
kubectl get pods -n devops-tools
```

![Alt_text](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/blob/main/screenshots/diplom17.png)

Далее создаем соответствующий сервис. Незначительно корректируем дефортный файл `service.yaml` из скачанного [репозитория](https://github.com/scriptcamp/kubernetes-jenkins), указав `nodePort: 32002`, так как дефолтный порт `32000` уже занят мониторингом (Grafana), а на порту `32001` работает наш сервер `nginx`.

Запускаем сервис
```
kubectl apply -f service.yaml
```
Для первого входа через веб-интерфейс определяем пароль
```
kubectl logs jenkins-cf789dc4d-l2v56 --namespace=devops-tools
```

![Alt_text](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/blob/main/screenshots/diplom18.png)

Входим в графический интерфейс и устанавливаем плагины, предлагаемые `Jenkins`.
Далее осуществляем стандартную настройку `Jenkins`, указывая логин, пароль и электронную почту в соответствующих пунктах меню. Далее копирую ссылку url для быстрого доступа (для упрощения задания ip адреса виртуальных машин, участвующих в проекте сделаны статическими). 
```
http://89.169.145.151:32002/
```
Далее необходимо настроить pipeline. Сборка и отправка  в регистр `docker-image` по условиям задания должна осуществляться при любом коммите в [репозитории](https://github.com/LeonidKhoroshev/nginx-static/tree/main).

Для этого переходим в репозиторий и создаем `webhook` в веб-интерфейсе `GitHub`

![Alt_text](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/blob/main/screenshots/diplom19.png)

Также необходимо настроить `Docker Credentials`  в веб-интерфейсе `Jenkins`.

![Alt_text](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/blob/main/screenshots/diplom20.png)

Далее настраиваем агенты для сборки на основе `Kubernetes pod`. Для этого сначала установим плагин `Kubernetes` для `Jenkins`, далее создаем новое облако `Kubernetes`, в настройках прописываем пространство имен `devops-tools`, в котором развернут под с `Jenkins` и также через графический интерфейс тестируем соединение с кластером.

![Alt_text](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/blob/main/screenshots/diplom21.png)

Убедившись в наличии подключения, добавляем шаблон пода, который будет являться нашим сборочным агентом. Задаем название `jenkins-agent`, указываем пространство имен и `image` [inbound-agent](https://hub.docker.com/r/jenkins/inbound-agent)

![Alt_text](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/blob/main/screenshots/diplom22.png)

Подробная инструкция по созданию и настройке агента доступна по [ссылке](https://scmax.ru/articles/707733/). Поскольку после публикации статьи в Jenkins прошел ряд обновлений, то не вся информация в ней актуальна (например названия плагинов), но в целом описанный метод является рабочим (на период сентября 2024 года).

Также для автоматизации нашего проекта необходима организация доступа через токен к `DockerHub`, Получаем токен в личном кабинете на `https://app.docker.com`

![Alt_text](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/blob/main/screenshots/diplom23.png)

Сохраняем токен в `credentials`

![Alt_text](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/blob/main/screenshots/diplom24.png)

После того как предварительная настройка `Jenkins` произведена, создадим `pipeline` для нашего проекта
```
pipeline {
    agent any  

    environment {
        DOCKER_HUB_REPO = 'leonid1984/nginx-static'
        DOCKER_CREDENTIALS_ID = 'docker-hub-credentials'  // ID учетных данных Docker Hub в Jenkins
        KUBECONFIG_CREDENTIALS_ID = 'kubeconfig-credentials'  // ID учетных данных для подключения к Kubernetes в Jenkins
    }

    stages {
        stage('Checkout') {
            steps {
                // Получение кода из GitHub
                git branch: 'main', url: 'https://github.com/LeonidKhoroshev/nginx-static.git'
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    // Получение текущего тега, если есть
                    def tag = env.GIT_TAG_NAME ?: 'latest'
                    // Сборка Docker-образа
                    sh "docker build -t ${DOCKER_HUB_REPO}:${tag} ."
                }
            }
        }
        
        stage('Push to Docker Hub') {
           steps {
             withCredentials([string(credentialsId: 'docker_hub_pat', variable: 'DOCKER_HUB_PAT')]) {
               sh """
               echo $DOCKER_HUB_PAT | docker login -u leonid1984 --password-stdin
               docker push leonid1984/nginx-static:latest
               """
            }
        }
    }
        
        stage('Deploy to Kubernetes') {
            when {
                tag "v*" // Деплой выполняется только при создании тега
            }
            steps {
                script {
                    withCredentials([file(credentialsId: KUBECONFIG_CREDENTIALS_ID, variable: 'KUBECONFIG')]) {
                        def tag = env.GIT_TAG_NAME ?: 'latest'
                        // Применение конфигурации деплоя в Kubernetes
                        sh """
                        kubectl set image deployment/nginx-static-deployment nginx-static=${DOCKER_HUB_REPO}:${tag}
                        kubectl rollout status deployment/nginx-static-deployment
                        """
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
```

Проверяем работу `pipeline`

![Alt_text](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/blob/main/screenshots/diplom25.png)

Сборка прошла успешно

Ожидаемый результат:

1. [Интерфейс ci/cd](http://89.169.145.151:32002/) сервиса доступен по http.
2. При любом коммите в [репозитории с тестовым приложением](https://github.com/LeonidKhoroshev/nginx-static) происходит сборка и отправка в регистр [Docker образа](https://hub.docker.com/r/leonid1984/nginx-static).
3. При создании тега (например, v1.0.0) происходит сборка и отправка с соответствующим label в регистри, а также деплой соответствующего Docker образа в кластер Kubernetes.

---
## Что необходимо для сдачи задания?

1. [Репозиторий с конфигурационными файлами Terraform](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/tree/terraform) и готовность продемонстрировать создание всех ресурсов с нуля.
2. Пример pull request с комментариями созданными atlantis'ом или снимки экрана из Terraform Cloud или вашего CI-CD-terraform pipeline.

![Alt_text](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/blob/main/screenshots/diplom26.png)
![Alt_text](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/blob/main/screenshots/diplom27.png)
![Alt_text](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/blob/main/screenshots/diplom28.png)
![Alt_text](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/blob/main/screenshots/diplom29.png)
![Alt_text](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/blob/main/screenshots/diplom30.png)

3. [Репозиторий с конфигурацией ansible](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/tree/kubespray), если был выбран способ создания Kubernetes кластера при помощи ansible.
4. [Репозиторий с Dockerfile](https://github.com/LeonidKhoroshev/nginx-static) тестового приложения и ссылка на собранный [docker image](https://hub.docker.com/r/leonid1984/nginx-static).
5. Репозиторий с конфигурацией Kubernetes кластера (в моем случае конфигурация кластера задана в репозитории с [kubespray](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/tree/kubespray) в файле [inventory.ini](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/blob/kubespray/inventory/mycluster/inventory.ini) ).
6. Ссылка на тестовое приложение и [веб интерфейс Grafana](http://89.169.145.151:32000) с данными доступа: логин - `admin` пароль - `prom-operator`.
7. Все репозитории рекомендуется хранить на одном ресурсе (github, gitlab).

Дополнительно прилагаю файлы для развертывания `Jenkins` в `k8s`

[deployment.yaml](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/blob/jenkins/deployment.yaml)

[namespace.yaml](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/blob/jenkins/namespace.yaml)

[pv.yaml](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/blob/jenkins/pv.yaml)

[pvc.yaml](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/blob/jenkins/pvc.yaml)

[service.yaml](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/blob/jenkins/service.yaml)

[serviceAccount.yaml](https://github.com/LeonidKhoroshev/devops-diplom-yandexcloud/blob/jenkins/serviceAccount.yaml)
