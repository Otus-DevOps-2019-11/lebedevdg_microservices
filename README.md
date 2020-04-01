[![Build Status](https://travis-ci.com/Otus-DevOps-2019-11/lebedevdg_microservices.svg?branch=master)](https://travis-ci.com/Otus-DevOps-2019-11/lebedevdg_microservices)

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


## ДЗ №2


# Переопределение переменных ENV

Файл с переменными /root/lebedevdg_microservices/src/.env

Содержимое:

COMMENT_DATABASE_HOST=comment_db2
COMMENT_DATABASE=comments2

POST_DATABASE_HOST=post_db2
POST_DATABASE=posts2

POST_SERVICE_HOST=post2
POST_SERVICE_PORT=5000
COMMENT_SERVICE_HOST=comment2
COMMENT_SERVICE_PORT=9292


# Запуск новых контейнеров с измененными переменными


docker run -d --network=reddit \
--network-alias=comment2 --env-file=.env lebedevdg/comment:1.0


docker run -d --network=reddit \
-p 9292:9292 --env-file=.env lebedevdg/ui:1.0


docker run -d --network=reddit \
--network-alias=post2 --env-file=.env lebedevdg/post:1.0

docker run -d --network=reddit \
--network-alias=post_db2 --network-alias=comment_db mongo:latest


# Собран образ для ui на основе alpine с оптимизацией сборки.


FROM ruby:2.2-alpine

ENV APP_HOME /app
WORKDIR $APP_HOME

COPY . $APP_HOME

RUN apk --no-cache --update add build-base=0.4-r1 && \
    bundle instal && \
    apk del build-base

ENV POST_SERVICE_HOST post
ENV POST_SERVICE_PORT 5000
ENV COMMENT_SERVICE_HOST comment
ENV COMMENT_SERVICE_PORT 9292

CMD ["puma"]


# Контейнеры запущены с новым образом ui и volume

docker run -d --network=reddit \
--network-alias=comment2 --env-file=.env lebedevdg/comment:1.0


docker run -d --network=reddit \
-p 9292:9292 --env-file=.env lebedevdg/ui:1.9


docker run -d --network=reddit \
--network-alias=post2 --env-file=.env lebedevdg/post:1.0

docker run -d --network=reddit \
--network-alias=post_db2 --network-alias=comment_db -v reddit_db:/data/db mongo:latest


## ДЗ №3

- изучены варианты сетей в Docker

- проект запущен в двух bridge сетях

```
# создание сетей
docker network create back_net --subnet=10.0.2.0/24
docker network create front_net --subnet=10.0.1.0/24

# запуск контейнеров
docker run -d --network=back_net --name mongo_db --network-alias=post_db --network-alias=comment_db --volume reddit_db:/data/db mongo:latest
docker run -d --network=back_net --name post lebedevdg/post:2.0
docker run -d --network=back_net --name comment lebedevdg/comment:2.0
docker run -d --network=front_net -p 9292:9292 --name ui lebedevdg/ui:3.0

# подключение нужных контейнеров ко второй сети
docker network connect front_net post
docker network connect front_net comment
```

- написан compose файл; освоена работа с утилитой docker-compose

- compose файл дополнительно параметризован и изменен под кейс с двумя сетями; значения параметров в .env файле

```
# валидация compose файла
docker-compose config
# создание и старт контейнеров
docker-compose up -d
```

- изучены способы задания базового имени проекта для compose:

  - через переменную окружения COMPOSE_PROJECT_NAME
  - через запуск docker-compose с флагом -p

- (*) создан override compose файл, в котором:

  - подключен volume с кодом приложения внутрь контейнера
  - puma запущена в debug режиме с двумя worker

```
# создание и старт контейнеров
# будет подхвачен и docker-compose.override.yml
# для корректной работы папки с кодом, которые мапятся внутрь контейнеров, должны существовать на docker host
docker-compose up -d
# создание и старт контейнеров без применения docker-compose.override.yml
docker-compose -f docker-compose.yml up -d
```
