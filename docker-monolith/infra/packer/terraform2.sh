#!/bin/sh

#gcloud compute images list | grep infra-265717 | cut -c 1-22 | xargs gcloud compute images delete --quiet

cd ..
packer build -var-file=./packer/variables.json ./packer/microservices-docker.json
