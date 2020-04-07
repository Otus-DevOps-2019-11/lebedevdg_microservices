#!/bin/bash

echo "Enter machine name"

#read name

name=${1:-docker-host}
echo $name

docker-machine create --driver google --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
--google-machine-type n1-standard-1 --google-project docker3-273507 --google-zone europe-north1-b --google-open-port 9292/tcp --google-open-port 9090/tcp $name

eval $(docker-machine env $name)
