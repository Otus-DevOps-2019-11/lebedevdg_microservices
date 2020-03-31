# lebedevdg_microservices
lebedevdg microservices repository

## ДЗ №1

docker run --rm -ti tehbilly/htop - отображает процессы внутри контейнера
docker run --rm --pid host -ti tehbilly/htop - прокидывает внутрь контейнера пиды хост процессов и отображет их. В данном случае хост система, это виртуалка GCP

- установлены docker и docker-machine

- изучены основные команды docker для работы с образами и контейнерами

- создан новый проект docker в GCP

- поднят docker host в GCE

```
# создание docker-host
docker-machine create --driver google \
  --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
  --google-machine-type g1-small \
  --google-zone europe-north1-a \
  docker-host
# переключение окружения на работу с docker-host
eval $(docker-machine env docker-host)
# переключение на локальное окружение
eval $(docker-machine env --unset)
# удаление docker-host
docker-machine rm docker-host
```

- подготовлено все необходимое для сборки своего образа на docker host

```
docker build -t reddit:latest .
```

- собранный образ залит на Docker Hub

```
docker tag reddit:latest lebedevdg/otus-reddit:1.0
docker push lebedevdg/otus-reddit:1.0
```

- (*) подготовлены для тестирования собранного docker образа:

  - количество VM указывается в переменной app_vm_count
```

  - ansible провижининг на terraform инфраструктуре, dynamic inventory сделан через плагин gcp_compute
```

  - packer сборка образа docker-base VM с установленным docker; провижининг выполняется с помощью ansible
