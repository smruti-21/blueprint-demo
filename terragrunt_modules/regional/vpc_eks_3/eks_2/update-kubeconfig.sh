#!/usr/bin/env bash
set +e

if [[ $# -lt 3 ]];
then
    echo "$0 CLUSTER_NAME AWS_PROFILE AWS_REGION"
    echo "$0 cicd toolchain eu-west-1"
    exit 1
fi

CLUSTER_NAME=$1
AWS_PROFILE=$2
AWS_REGION=$3

aws eks update-kubeconfig --name ${CLUSTER_NAME} --profile ${AWS_PROFILE} --region ${AWS_REGION} && \
echo "update-kubeconfig done"
