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


## ДЗ №4


    подготовлена инсталляция Gitlab CI на docker-host в GCP
    подготовлен репозиторий с кодом приложения
    описаны для приложения этапы пайплайна и определены окружения
    (*) на шаге build добавлена сборка образа с приложением reddit и загрузка образа на Docker Hub
    (*) на шаге review добавлен деплой приложения на docker-host, а также добавлен job удаления динамического окружения
    (*) написан скрипт для поднятия Gitlab CI Runner
    (*) настроена интеграция пайплайна с каналом Slack

# установка и настройка Gitlab CE

# исходно на нашей управляющей машине должны стоять docker, docker-compose, docker-machine

# задаем переменную со значением ID проекта в GCP
export GOOGLE_PROJECT=<your_GCP_project_id>

# поднимаем docker-host на Ubuntu в GCP
# (на нем дальше и будем разворачивать Gitlab CE и минимум один Gitlab Runner)
docker-machine create --driver google \
  --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
  --google-machine-type n1-standard-1 \
  --google-zone europe-north1-a \
  --google-disk-size 50 \
  docker-host

# создаем firewall правило для будущего доступа к Gitlab по 80-ому порту
gcloud compute firewall-rules create docker-machine-allow-http \
  --allow tcp:80 \
  --target-tags=docker-machine \
  --description="Allow http connections" \
  --direction=INGRESS

# создаем сразу и firewall правило для будущего доступа к нашему reddit-app по порту 9292
gcloud compute firewall-rules create reddit-app \
  --allow tcp:9292 \
  --target-tags=docker-machine \
  --description="Allow PUMA connections" \
  --direction=INGRESS

# переключаем docker окружение на работу с docker-host
eval $(docker-machine env docker-host)

# выводим список docker machine
# убеждаемся, что docker-host сейчас является активной (той, на которую переключено docker окружение),
# а также запоминаем внешний IP-адрес docker-host
docker-machine ls

# задаем значение переменной с участием внешнего IP-адреса docker-host
# это будет адрес, по которому будет доступен наш Gitlab
export GITLAB_CI_URL=http://<docker-host_external_IP>

# поднимаем на docker-host контейнер с Gitlab
# docker-compose -f ./gitlab-ci/docker-compose.yml config
docker-compose -f ./gitlab-ci/docker-compose.yml up -d

# заходим в наш Gitlab по адресу http://<docker-host_external_IP> и задаем пароль пользователю root
# затем логинимся в Gitlab под пользователем root,
# там в Admin Area идем в Settings, там в Sign-up restrictions выключаем Sign-up enabled, делаем Save changes
# далее в Groups создаем новую Group, например, homework, а в ней новый blank Project, например, example

# затем в Project, который мы создали, в Settings -> CI / CD -> Runners находим значение registration token
# и задаем значение переменной
export GITLAB_CI_TOKEN=<gitlab_registration_token>

# set up-им новый Gitlab Runner
# (можно повторить этот шаг для создания нескольких runner; имя контейнера значения не имеет, лишь бы оно было уникальным)
./gitlab-ci/set_up_runner.sh <gitlab-runner_container_name>
# при регистрации runner были добавлены следующие опции для корректной работы Docker-in-Docker:
#  --docker-privileged
#  --docker-volumes "docker-certs-client:/certs/client"
#  --env "DOCKER_TLS_CERTDIR=/certs"

# состояние созданного runner можно проверить там же в Project, который мы создали, в Settings -> CI / CD -> Runners

# в Project, который мы создали, в Settings -> Integrations -> Slack notifications добавляем Webhook
# из предварительно добавленного в нужный канал Slack приложения Incoming WebHooks

# в Project, который мы создали, в Settings -> CI / CD -> Variables добавляем переменные
# DOCKER_HUB_LOGIN и DOCKER_HUB_PASSWORD (для этой включить Masked)
# это нужно, соответственно, для загрузки собранных image на Docker Hub

# на нашей управляющей машине выполняем
docker-machine env docker-host
# по пути DOCKER_CERT_PATH нас интересуют три файла: ca.pem, cert.pem, key.pem
# в Project, который мы создали, в Settings -> CI / CD -> Variables добавляем переменные типа File
# DOCKER_HOST_CA_FILE, DOCKER_HOST_CERT_FILE, DOCKER_HOST_KEY_FILE
# со значениями, равными содержимому, соответственно, наших трех файлов: ca.pem, cert.pem, key.pem

# в клоне нашего рабочего репозитория создаем какой-нибудь новый branch, например, gitlab-ci-1
# потом добавляем в репозиторий remote на наш Gitlab
# и пушим в наш Gitlab
git checkout -b gitlab-ci-1
git remote add gitlab http://<docker-host_external_IP>/<your_group>/<your_project>.git
git push gitlab gitlab-ci-1

# проверяем в нашем Gitlab состояние запустившегося pipeline в Project, который мы создали, в CI / CD -> Pipelines
# проверяем также в нашем канале Slack, что туда приходят оповещения от нашего Gitlab

# затем заходим по адресу нашего environment branch/gitlab-ci-1: http://<docker-host_external_IP>:9292
# и убеждаемся, что наше собранное и задеплоенное приложение работает корректно


# по окончании экпериментов с нашим Gitlab убираем за собой
# переключаем docker окружение обратно на локальное
eval $(docker-machine env --unset)
# удаляем машину docker-host в GCP
docker-machine rm docker-host


## ДЗ №5

- запущены приложение reddit и Prometheus на docker-host в GCP
- настроен мониторинг микросервисов
- настроен сбор метрик хоста с использованием prom/node-exporter
- (*) настроен мониторинг MongoDB с использованием mongodb-exporter (https://github.com/percona/mongodb_exporter)
- (*) настроен мониторинг сервисов comment, post, ui с использованием prom/blackbox-exporter
- (*) написан Makefile для сборки и публикации образов, а также для запуска всего через docker-compose

ссылки на Docker Hub с собранными образами:
https://hub.docker.com/repository/docker/lebedevdg/ui
https://hub.docker.com/repository/docker/lebedevdg/post
https://hub.docker.com/repository/docker/lebedevdg/comment
https://hub.docker.com/repository/docker/lebedevdg/prometheus
https://hub.docker.com/repository/docker/lebedevdg/mongodb-exporter

```
# поднять docker-host в GCP, открыть порты 9090 и 9292
# переключить docker окружение на работу с docker-host

# далее из корня репозитория выполнить
make build --directory=./monitoring
make up --directory=./monitoring
```

## ДЗ №6

- настроен мониторинг docker контейнеров с помощью cAdvisor
- изучена визуализация метрик с помощью Grafana
- сделаны дашборды для визуализации метрик работы приложения и бизнес-метрик
- настроены и проверены правила алертинга через Alertmanager в канал Slack
- (*) доработан Makefile для работы со всеми новыми сервисами
- (*) настроен сбор метрик в экспериментальном режиме с самого Docker и создан дашборд (Experimental_Docker_daemon_Monitoring.json)
- (*) настроен сбор метрик с Docker с помощью Telegraf и создан дашборд (Telegraf_Docker_Monitoring.json)
- (*) добавлены еще правила алертов и настроен алертинг через Alertmanager по email
- (**) реализовано автоматическое добавление в Grafana источника данных (Prometheus) и всех созданных дашбордов

ссылки на Docker Hub с новыми собранными образами:
https://hub.docker.com/repository/docker/lebedevdg/prometheus
https://hub.docker.com/repository/docker/lebedevdg/grafana
https://hub.docker.com/repository/docker/lebedevdg/alertmanager
https://hub.docker.com/repository/docker/lebedevdg/telegraf

```
# поднять docker-host в GCP, открыть порты 9090 (Prometheus), 9292 (reddit app), 8080 (cAdvisor), 3000 (Grafana), 9093 (Alertmanager)
# переключить docker окружение на работу с docker-host

# далее из корня репозитория выполнить
make build --directory=./monitoring
make up --directory=./monitoring
make upmon --directory=./monitoring
```
```
# включение экспериментальных метрик на docker
# подключиться к docker-host
docker-machine ssh docker-host

# создать (добавить в) файл /etc/docker/daemon.json
{
  "metrics-addr" : "0.0.0.0:9323",
  "experimental" : true
}
# перезапустить docker
sudo systemctl restart docker
```


## ДЗ №7

- установлен и настроен стек EFK
- во Fluentd задействованы плагины fluent-plugin-elasticsearch и fluent-plugin-grok-parser
- рассмотрен сбор через fluentd docker драйвер структурированных логов (json) на примере сервиса post
- настроен фильтр парсинга во Fluentd приходящих json-логов от сервиса post
- рассмотрен сбор через fluentd docker драйвер неструктурированных логов на примере сервиса ui
- настроен фильтр во Fluentd парсинга логов ((*) двух форматов) сервиса ui с помощью grok-шаблонов
- добавлен сервис распределенного трейсинга Zipkin
- (*) при работе со "сломанным" приложением с помощью Zipkin удалось понять, что задержка при открытии любого поста происходит в сервисе post при обработке запроса /post/-id-;<br/>далее по коду сервиса post в find_post был найден вызов time.sleep(3), что и было причиной задержки
- для логов сервиса ui настроен также парсинг json-данных поля params
- настроен также сбор через fluentd docker драйвер неструктурированных логов сервиса comment
- с помощью плагина fluent-plugin-concat настроена склейка многострочных логов сервиса comment, а затем выполнен парсинг аналогично логам сервиса ui

ссылки на Docker Hub с новыми собранными образами:
https://hub.docker.com/repository/docker/lebedevdg/ui
https://hub.docker.com/repository/docker/lebedevdg/post
https://hub.docker.com/repository/docker/lebedevdg/comment
https://hub.docker.com/repository/docker/lebedevdg/fluentd
```

# Kibana
http://docker-host_ip:5601
# в Index Patterns -> Create index pattern, Index pattern = fluentd-*, Time Filter field name = @timestamp
# далее Discover и можно смотреть полученные логи
```


sergetol microservices repository

# ДЗ №8

- развернуты вручную компоненты Kubernetes v1.18.2, используя The Hard Way (https://github.com/kelseyhightower/kubernetes-the-hard-way)
- созданы деплойменты для компонентов ui, post, mongo, comment; проверено, что поды запускаются

```
kubectl apply -f kubernetes/reddit

kubectl get deployments
kubectl get pods

kubectl logs $(kubectl get pods -l app=comment -o jsonpath="{.items[0].metadata.name}")
kubectl logs $(kubectl get pods -l app=mongo -o jsonpath="{.items[0].metadata.name}")
kubectl logs $(kubectl get pods -l app=post -o jsonpath="{.items[0].metadata.name}")
kubectl logs $(kubectl get pods -l app=ui -o jsonpath="{.items[0].metadata.name}")

kubectl delete -f kubernetes/reddit
```


# ДЗ №9

- запущен локально minikube на VirtualBox
- написаны манифесты для развертывания в k8s компонентов приложения
- запущено приложение в minikube
- развернут k8s кластер в GKE вручную и на нем запущено приложение
- (*) развернут k8s кластер в GKE с помощью Terraform и на нем запущено приложение
- (*) добавлен деплой k8s dashboard в кластер

```
# https://kubernetes.io/docs/tasks/tools/install-minikube/
minikube start --driver='virtualbox' --disk-size='4096mb'

kubectl apply -f ./kubernetes/reddit/dev-namespace.yml
kubectl apply -f ./kubernetes/reddit/ -n dev

# kubectl get all -n dev
minikube service ui -n dev

#-----
minikube stop
minikube delete
```

```
# https://www.terraform.io/docs/providers/google/r/container_cluster.html

cd ./kubernetes/terraform && terraform init && terraform apply -auto-approve && cd -

gcloud container clusters get-credentials <cluster_name>

kubectl apply -f ./kubernetes/reddit/dev-namespace.yml
kubectl apply -f ./kubernetes/reddit/ -n dev

# kubectl get all -n dev
kubectl get nodes -o wide
kubectl describe service ui -n dev | grep NodePort

# http://<EXTERNAL-IP>:<NodePort>

#-----
cd ./kubernetes/terraform && terraform destroy -auto-approve && cd -
```

```
# Web UI (Dashboard)
# https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/

kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml
kubectl apply -f ./kubernetes/dashboard/dashboard-admin-user.yml

# getting a Bearer Token:
kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')

kubectl proxy

# http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

# ДЗ №10


- изучили LoadBalancer Service, Ingress, Secret (* TLS), NetworkPolicy, PersistentVolume, PersistentVolumeClaim, StorageClass

```
cd ./kubernetes/terraform && terraform init && terraform apply -auto-approve && cd -

gcloud container clusters get-credentials <cluster_name>

kubectl apply -f ./kubernetes/reddit/dev-namespace.yml
kubectl apply -f ./kubernetes/reddit/ -n dev

# kubectl get all -n dev
kubectl get ingress -n dev

# https://<EXTERNAL-IP-ADDRESS>

#-----
cd ./kubernetes/terraform && terraform destroy -auto-approve && cd -
```

# ДЗ №10

- изучена работа с helm2, helm2 tiller plugin, helm3
- созданы helm чарты для развертывания приложения в k8s
- развернут Gitlab CI в k8s
- написаны CI/CD пайплайны для сборки docker образов компонентов приложения и пайплайн развертывания приложения в k8s

  - пайплайн компоненты ui сделан без auto_devops и использует для деплоя helm2
  - пайплайн comment использует для деплоя helm2 вместе с helm-tiller plugin (https://github.com/rimusz/helm-tiller)
  - пайплайн post использует для деплоя helm3
  - пайплайн reddit-deploy сделан без auto_devops и использует helm3
  - (*) в пайплайны ui, post, comment добавлен стэйдж trigger_deploy, выполняющий запуск пайплайна reddit-deploy (POST request to GitLab API endpoint)

```
cd ./kubernetes/terraform && terraform init && terraform apply -auto-approve && cd -

gcloud container clusters get-credentials <cluster_name>

# install Gitlab CI in k8s
helm3 install gitlab ./kubernetes/Charts/gitlab-omnibus/ -f ./kubernetes/Charts/gitlab-omnibus/values.yaml

# watch the status with:
kubectl get svc -w --namespace nginx-ingress nginx
# then:
echo "$(kubectl get svc --namespace nginx-ingress nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}') gitlab-gitlab staging production" >> /etc/hosts

# http://gitlab-gitlab
# set password for root, then sign in
# follow Admin Area -> Settings, Sign-up restrictions, disable Sign-up enabled, Save
# follow Groups -> New group, in Group path add your DockerHub login, make group Public, disable Create a Mattermost team for this group
# in the group follow Settings -> CI / CD, add CI_REGISTRY_USER and CI_REGISTRY_PASSWORD variables with your DockerHub login and password

# in the group make New project with Project name 'reddit-deploy', make it Public
# add to group more public projects: comment, post, ui

# in the 'reddit-deploy' project follow Settings -> CI / CD, Pipeline triggers, Add trigger, copy trigger token and remember project_id
# in the group follow Settings -> CI / CD, add REDDIT_DEPLOY_TRIGGER_TOKEN and REDDIT_DEPLOY_PROJECT_ID variables with your trigger token and project_id
# for example:
# REDDIT_DEPLOY_TRIGGER_TOKEN = ef798205940eed3d02575213cb1298
# REDDIT_DEPLOY_PROJECT_ID = 1

# push component's sorce code and helm charts to the appropriate gitlab project

# check pipeline statuses and environments

# helm ls --all
# helm3 ls --all --namespace review
# helm3 ls --all --namespace=staging
# helm3 ls --all --namespace=production

#-----
# in gitlab stop all review environments
helm3 uninstall staging --namespace=staging
helm3 uninstall production --namespace=production

kubectl delete ns review
kubectl delete ns staging
kubectl delete ns production

helm3 uninstall gitlab

cd ./kubernetes/terraform && terraform destroy -auto-approve && cd -
```
