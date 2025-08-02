#!/bin/sh

cluster_name=''

#Determine the OIDC issuer ID for your cluster
oidc_id=$(aws eks describe-cluster --name $cluster_name --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)
echo $oidc_id

#Determine whether an IAM OIDC provider with your cluster’s issuer ID is already in your account.
aws iam list-open-id-connect-providers | grep $oidc_id | cut -d "/" -f4

#If output is returned, then you already have an IAM OIDC provider for your cluster and you can skip the next step.
#If no output is returned, then you must create an IAM OIDC provider for your cluster.

eksctl utils associate-iam-oidc-provider --cluster $cluster_name --approve