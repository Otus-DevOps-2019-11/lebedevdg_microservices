#!/bin/bash

rm build_info.txt

echo `git show --format="%h" HEAD | head -1` > build_info.txt
echo `git rev-parse --abbrev-ref HEAD` >> build_info.txt

export USER_NAME=lebedevdg

cd /root/lebedevdg_microservices/monitoring/prometheus && docker build -t $USER_NAME/prometheus .

#cd /root/lebedevdg_microservices
#cd /root/lebedevdg_microservices/monitoring && docker build -t $USER_NAME/percona:0.10.0 .

cd /root/lebedevdg_microservices
cd src/comment && ./docker_build.sh && cd /root/lebedevdg_microservices
cd src/post-py && ./docker_build.sh && cd /root/lebedevdg_microservices
cd src/ui && ./docker_build.sh && cd /root/lebedevdg_microservices

cd logging/fluentd && docker build -t $USER_NAME/fluentd . && cd /root/lebedevdg_microservices

rm build_info.txt
