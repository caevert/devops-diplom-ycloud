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

![Service accounts](./assets/T-3.png)

![S3 backend for terraform tfstate in YC Object Storage](./assets/T-2.png)

VMS in YC
```
+----------------------+--------+---------------+---------+----------------+----------------+
|          ID          |  NAME  |    ZONE ID    | STATUS  |  EXTERNAL IP   |  INTERNAL IP   |
+----------------------+--------+---------------+---------+----------------+----------------+
| epdjehfpdpfalutkuep9 | slave2 | ru-central1-b | RUNNING | 158.160.12.225 | 192.168.200.14 |
| fhm2630o4n2btldi565o | slave1 | ru-central1-a | RUNNING | 89.169.143.31  | 192.168.100.20 |
| fv485411t4bqp5mff2dt | master | ru-central1-d | RUNNING | 84.252.135.85  | 192.168.10.100 | 
```
2. Полученная конфигурация инфраструктуры является предварительной, поэтому в ходе дальнейшего выполнения задания возможны изменения.

---
## Этап второй - Создание Kubernetes кластера

На данном этапе необходимо развернуть `Kubernetes` кластер, для данной задачи будем использовать набор конфигураций _Ansible_ [`Kubespray`](https://github.com/kubernetes-sigs/kubespray)

1. Клонирем `kubespray` командой `git clone https://github.com/kubernetes-sigs/kubespray`
2. Создаем конфигурацию своего кластера:

```shell
cd kubespray
cp inventory/sample inventory/netology
```

3. Выясняем айпи машин кластера на которые будет производится установка:

![Kube](./assets/K-1.png)

4. Для установки необходимо указать конфигурацию кластера.

```shell
nano inventory/netology/hosts.yaml
all:
  hosts:
    master:
      ansible_host: 84.252.135.85
      ip: 192.168.10.100 
      ansible_user: ubuntu
      kubeconfig_localhost: true
    worker1:
      ansible_host: 89.169.143.31
      ip: 192.168.100.20
      ansible_user: ubuntu
    worker2:
      ansible_host: 158.160.12.225
      ip: 192.168.200.14
      ansible_user: ubuntu
  children:
    kube_control_plane:
      hosts:
        master:
    kube_node:
      hosts:
        master:
        worker1:
        worker2:
    etcd:
      hosts:
        master:
        worker1:
        worker2:
    k8s_cluster:
      children:
        kube_control_plane:
        kube_node:
    calico_rr:
      hosts: {}


```

5. Также необходимо предусмотреть генерацию сертификата для работы `kubectl`, укажем адрес управляющей ноды:

```shell
nano inventory/netology/group_vars/k8s_cluster/k8s-cluster.yml

supplementary_addresses_in_ssl_keys: [84.252.135.85]
```

6. После развертывания кластера скопируем локально в `.kube/config` файл конфигурации кластера Кубернетес `.kube/config` с управляющей ноды
```
piVersion: v1
clusters:
- cluster:
    certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCVENDQWUyZ0F3SUJBZ0lJQXhGOW9nZ1dCZVV3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TkRFd01UWXhNVEE1TWpaYUZ3MHpOREV3TVRReE1URTBNalphTUJVeApFekFSQmdOVkJBTVRDbXQxWW1WeWJtVjBaWE13Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLCkFvSUJBUURXMHBFcWNZL2FEM3hqYXFaVUFRTHA3STZKeVVRMXlORjlqTzF0TVg4cWR3MkNKL1JINGI4cmhlNUoKSlJNbEJSNnIxMEhId3RrLzFmbFh2RHNmdGoyUHBDVVU3aE4zZmtlVWd6cE5BY2xSOHg2eGxJUmorZEkvZFdRMworcDN2R1FhamdXeHRSY0F4YXJ5dVdsby9TMWpSZHUzajNwQTJ0RlNCaWhhWDBTci9BTHgxZ0YrWitzYUdnWnBRCnBVdkVNTGFjRHhLb1FpdlJRYmxteXFwNmd3YWFjbEJ3ZSthYWxpQkFqZlZhUWZPSWlmZWx5ZXQ3NlVBeW9EYXEKNmhXd1c4VFVRdHlKalh4ZUkwUDFVblNjc29HVVBkakN1RGxvQUJkUWhBTGZhT3hSQktyVFFQcUNXaFAwL1c5OQpGYUtuRjlvaUpjd2gwWlpvY3laVEtyV1h6dDlkQWdNQkFBR2pXVEJYTUE0R0ExVWREd0VCL3dRRUF3SUNwREFQCkJnTlZIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJSMjc0Y1FZdmhCZ1BlMU96R25vamxwYUNQdHVqQVYKQmdOVkhSRUVEakFNZ2dwcmRXSmxjbTVsZEdWek1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQzM4YzE1WVViNgpLaEpESmthc1o5dlNySko5NWl5dEhpczdLMmRPb0htQXR2cW5PVmdoMUtnQk9yUzJtLy9GMjdMdzhsZ2JDd1JuCitDb0JvVWFKYVBmVVM0c3RMdnJrVUZWMWRERi8zT285UmcxSzNCNzdaSjVQZldkSUZzZUtXNnJIRjJDVE9vdncKT01vT2xiL3VLcFdFRXBaRncyeFd5MkYrd05WZ0N4RnB6eE9JUVpJR09XeDVleTlpRmRVdkFkbmJ1MXpiNEVEOApPcGNBMTZtcTdYcUZCKzBYTUU3SHNyVTlmMVJxWDR2Sy93V2IvT3pFLzhyRDZBUXd0bnQvclBoVk5nbXBURnhzCklkZ2ZQUEl4czErZjRIZjZtUHJ0T1Jublg4NWNvSFhsenZpQm8yZHNSanZTOHhqVzRObVhwVnV4RkJ5a2pFcUYKcDFnWW1oY2dqRkJiCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K
    server: https://192.168.10.100:6443
  name: cluster.local
contexts:
- context:
    cluster: cluster.local
    user: kubernetes-admin
  name: kubernetes-admin@cluster.local
current-context: kubernetes-admin@cluster.local
kind: Config
preferences: {}
users:
- name: kubernetes-admin
  user:
    client-certificate-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURLVENDQWhHZ0F3SUJBZ0lJQUtlUXlraGNwSWt3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TkRFd01UWXhNVEE1TWpaYUZ3MHlOVEV3TVRZeE1URTBNalphTUR3eApIekFkQmdOVkJBb1RGbXQxWW1WaFpHMDZZMngxYzNSbGNpMWhaRzFwYm5NeEdUQVhCZ05WQkFNVEVHdDFZbVZ5CmJtVjBaWE10WVdSdGFXNHdnZ0VpTUEwR0NTcUdTSWIzRFFFQkFRVUFBNElCRHdBd2dnRUtBb0lCQVFEcHBTdFYKT1dlRGhzRi9LekJBeXpTUG13dFRGWVFhZmROdG13Mmt0dFRTamZjeVdmcjJraTBkT2xIKzNOTmFsYjVNQWJOUQpFZjkvM3U3OXc1d2RZeTMrdUlpRXQvaFJ0V0dpdG42akxQVDF1SmdhQkN5T1JZR1dIUmtYeVJlSjlJNTEvbEVlClRjTDBZM2dJZFBzYXZ1RCtHWjg3RERxVXlOT0lCK0twM3VET0JHY2QxV3FRaHVIaVdGMHhiL2VBckZOZElKRWQKcXpnQ3F0eUZYQXJDbnZydkg2OTd1U015N3RLempGZFBtaTcvVnprelpyTi8vVGRoUFdoRXVKcG9EYmtmQWFINwp0TXczNlBxUXozb3ZnMGxiL2NPYW5ld2tENkFFeklWWmxzUlZKbFFlOUpmMy9WOUt2bVdSWDErbkNyOU10bmhBClVKcERKdHIzbDd2QXBZRWZBZ01CQUFHalZqQlVNQTRHQTFVZER3RUIvd1FFQXdJRm9EQVRCZ05WSFNVRUREQUsKQmdnckJnRUZCUWNEQWpBTUJnTlZIUk1CQWY4RUFqQUFNQjhHQTFVZEl3UVlNQmFBRkhidmh4QmkrRUdBOTdVNwpNYWVpT1dsb0krMjZNQTBHQ1NxR1NJYjNEUUVCQ3dVQUE0SUJBUUNYaEM0WUhpaDMzT3ZuOE9MQ0U3Ym5JdlhFCkNSOE1JQWttQlZPUnlMVmlxSmxpWnQzRG5rQVlkRXZHS1NVKzI4Z0JyNURRT2ZrelJ2TVFITTRRMUtzaEN0K3oKdzFqcHhhTjA2dUQ1a0lRNHpQeHRsTys0Y2psd3VTVHBoWlRWU1pJKzRPc05UQ21mYm9ld0RibHowUm1USktucgpQUEtWS2hIcEpjN0Z0YkFET1VQRUxHdTQzNHRGS08wWUVrL1NBL3V6clJ5U0t0OFBZZE9XRjVQbHRJZmNmOGVUCkM2ZFdYaFlkZGIxMk9jMGk2QXNMRXhpWjRXOWpoVFp3MnV6NmxTejNvNlNpeE0rWFB0RDBsODAvcjErV3h2UU4KUm1INVhwazdqT2RUNGFjemdERkZqaFp0cjJUN1BCMy9BWi83aTZTOXh2T0U1R05LL0dVTUFNUWtSQ0RpCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K
    client-key-data: LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFcEFJQkFBS0NBUUVBNmFVclZUbG5nNGJCZnlzd1FNczBqNXNMVXhXRUduM1RiWnNOcExiVTBvMzNNbG42CjlwSXRIVHBSL3R6VFdwVytUQUd6VUJIL2Y5N3UvY09jSFdNdC9yaUloTGY0VWJWaG9yWitveXowOWJpWUdnUXMKamtXQmxoMFpGOGtYaWZTT2RmNVJIazNDOUdONENIVDdHcjdnL2htZk93dzZsTWpUaUFmaXFkN2d6Z1JuSGRWcQprSWJoNGxoZE1XLzNnS3hUWFNDUkhhczRBcXJjaFZ3S3dwNzY3eCt2ZTdrak11N1NzNHhYVDVvdS8xYzVNMmF6CmYvMDNZVDFvUkxpYWFBMjVId0doKzdUTU4rajZrTTk2TDROSlcvM0RtcDNzSkErZ0JNeUZXWmJFVlNaVUh2U1gKOS8xZlNyNWxrVjlmcHdxL1RMWjRRRkNhUXliYTk1ZTd3S1dCSHdJREFRQUJBb0lCQVFDNWZBS1d1ZWZQcHQ5ZQpVYThSQVVGTThFMWhQQ2VQMEd4VkMwOGRnSGdjWDgvckRUd0xHNmp0Rnl1WkpUNDFIOFBmRzBwN09vNlh1U2dLCkZZeU9WL3BmeWFlM2xVVnh1SWsyWDZMUmNCTllMNSt3cDdlbmlzNkJtY0FkL2VyTi9uUktnQWR1QTFYT0psbFkKZldZTHFaVjhwR0tnd2VpUHpZOEE0eUd5c2RuT01uUkpZWE9OZ1RWWFBMQnNtdng2a3FseWFmUENWOEN0RUZPagp4MlZqU29nejdBY1N0dTdnZ2lHZ2NseWNSblpQdHlEeCsySG1NMTdRSmlLWlRwNU8zYnJzYThZQVBnQW1PMnJ1CmhtOU1WZGZLRGxKUG5BdmRDeUtTR0VJSVNtZGU3S0pBU0FDRXlseUpKZElkOGpKZjBheFJTVTZlcC9mNFROcWQKNGdvL3BhcmhBb0dCQVBTNk5DYlJHRHI0dnRpOE92Nk1FVzh2VExpY00rbHhNSU9mQ2w4c3dYMHFzVGxraU9UWgpubXFRUzVBZm43MnJhdkNPbVZURDJZSEJIa093TDIxdTVCRFhscURHeVRWak9MbzBXUkdaWjY0cEZiZ3NmYjNKCmtZY2QwZGZnZXl5TTU4R0hSSDJ4OXdpTzdQTzRobWwyek1tcDdXYy8zSFZua0x2TjBjMXlTM3lUQW9HQkFQUm8KU1RRK1pTdk5IRG11UDFiamZIYWJDMVpqZEM2dURRTU1LL1JRMTRLeUFoNVErOWZQVnlDZkVodUh2bHlEZDRkVApGUWdncXR2WmgwMytSNWtkOHBsS1pYWlZIcG9zOFlLZXRGYUJRbURyKzV0QkxrYVlrdGY4Wmc5M01rNm9lbVkwCnJZVTRWUERuSlVyYjFtdlE3RnZFOXV6ZHlBM0tHdUZVVjJyZEFVekZBb0dBT0lDQkovRWdzZ1RhTXpvS09Oam4KOFk2dkhQUmJlK3M1TXpwVjc3RnFudFpyZ24rMnAzZWkvcUdBQUs5OGR4TUxwcXlWdEI5ZnFYaUgzMExmUUZuWQo2QmFPWFdKbjlCNkxhMXBJc2lxRDZJN3R4ODdsM1JxYnNlRnRvSFRnbTJHUTVIcXhrbit6TkZPalc0WGY2cHVXCkhuMVFKWVYyQmRrNmJsSFB2YXBFeVdjQ2dZQlplVFFUWkNRMWZNa3dkSkhMaFV3elAxOVBLT21IalVCR05WYUMKQW5aaTZqZk1VV2xoQUE2dGFvNStkWnRDMHY0WEZGdEd0bTdXUFRSRFlTdGs2b205aEhiUWN5alkyRXN4dmxmVwpzMHRSb0JKa0srQjlCNjM2VS9RcEJVSHRlZEFWU29PYm1adSs5Vis1bi9GSFZ4eXdHOU1wczZkaEpQUGlPYlltCjhQRmc0UUtCZ1FEUUxUWUUwaXpwMFdZUXRnalFwL1d5bkJwSm5DZER0SjBlanR4NDVNYVN0OWduclBiRVFhYzgKVlp2SDE1RklkQlAzb0c4dlhaUThSRGFNWGFXemMxK3d4OEVBTUljV0d6bWlhcmxHcVRSL28wRmxaMU16WGptaQpWVnFpQVUxTjExZDhwMmtSRkR3c3Brd2VZODluTDIxUmJTQ0FzRnRwS3Zsc2hYd1p2emI2U3c9PQotLS0tLUVORCBSU0EgUFJJVkFURSBLRVktLS0tLQo=

```
7. Команда `kubectl get pods --all-namespaces` отрабатывает без ошибок

![Kube](./assets/K-4_Namespces.png)



## Итог: кластер `Kubernetes` запущен и работает на инстансах YandexCloud подготовленных при помощи `Terraform`
---


### Этап третий - подготовка тестового приложения

1. Создаем [`Dockerfile`](docker/Dockerfile) с простой конфигураций сервера `nginx` отдающим статическую страницу c именем хоста(контейнера) и версией сборки(тэгом).

```
# Pull the minimal Ubuntu image
FROM nginx

# Copy the Nginx config
COPY default.conf /etc/nginx/conf.d/

# Expose the port for access
EXPOSE 80/tcp

# Run the Nginx server
CMD ["/usr/sbin/nginx", "-g", "daemon off;"]
```

2. Также добавляем в репозиторий файл конфигурации ![Dock](./III.Application/default.conf) и файл ![Dock](./III.Application/index.html)

3. Далее следует собрать образ и отправить его в registry DockerHub

```shell
$ cd docker
$ docker build -t rowhe/nginx_static_index:0.0.2 .

Sending build context to Docker daemon  4.096kB
Step 1/4 : FROM nginx:alpine
alpine: Pulling from library/nginx
63b65145d645: Pull complete
51f129e7c3f1: Pull complete
f32490ce40c5: Pull complete
d18f1b67600c: Pull complete
b793aaf052d0: Pull complete
10b0102e5979: Pull complete
ec50f2776186: Pull complete
Digest: sha256:ff07dba791a114f5d944c8455e8236ca4b184bfd8d21d90b7755a4ba0a119b06
Status: Downloaded newer image for nginx:alpine
 ---> fddf8c2fcb06
Step 2/4 : COPY default.conf /etc/nginx/conf.d/
 ---> 76d6eac0e768
Step 3/4 : COPY index.html /usr/share/nginx/html/
 ---> 9d9f6ac461fe
Step 4/4 : CMD ["nginx", "-g", "daemon off;"]
 ---> Running in 9bea7252bf6f
Removing intermediate container 9bea7252bf6f
 ---> 4f80752a2eb2
Successfully built 4f80752a2eb2
Successfully tagged rowhe/nginx_static_idex:0.0.2
```


```shell
$ docker push rowhe/nginx_static_index

The push refers to repository [docker.io/rowhe/nginx_static_index]
f0756d312c74: Pushed
175495e4dc90: Pushed
a7fcaf3114d5: Mounted from library/nginx
dff076fb6916: Mounted from library/nginx
d280bc8e13e2: Mounted from library/nginx
07a0bc54bc50: Mounted from library/nginx
2b5f63e9fb78: Mounted from library/nginx
3b6b66b66e55: Mounted from library/nginx
7cd52847ad77: Mounted from library/nginx
0.0.2: digest: sha256:91efabe17ece024823f470e9d4e25eb0d53d5c0f0a7fc326e086176d0f6a6671 size: 2195
```

3.1 Проверим, что образ загрузился на DockerHub

![DockerHub](img/img.png)

4. Запустим контейнер и проверим его работу

```shell
$ docker run -d --rm -p 80:80 --name nginx rowhe/nginx_static_index:0.0.2
778777812dc6f19f22f1baa0cc192afb1dac22ba67cc093d18bffc580a7c55d1 
```

5. Проверим работу сервера
```shell
$ curl localhost

<html>
<body>
        <h1>Host: 778777812dc6</h1>
        Version: 1.1
</body>
</html>
```

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
