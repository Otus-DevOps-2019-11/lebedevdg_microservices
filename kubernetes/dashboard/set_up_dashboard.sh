#!/bin/bash
set -evx

# Web UI (Dashboard)
# https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/
# https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/creating-sample-user.md

kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml
kubectl apply -f dashboard-admin-user.yml
