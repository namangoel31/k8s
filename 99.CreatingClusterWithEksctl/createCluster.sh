#!/bin/sh

eksctl create cluster -f clusterConfig.yaml #creates a cluster and associated an OIDC provider to it

aws eks update-cluster-config \
  --region ap-south-1 \
  --name testCluster \
  --resources-vpc-config additionalSecurityGroupIds=<"security_group_id">

aws iam attach-role-policy \
--role-name my-worker-node-role \
--policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy

#Installing helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

#Intalling cloudwatch container insights using helm
helm repo add aws-observability https://aws-observability.github.io/helm-charts
helm repo update aws-observability
helm install --wait --create-namespace --namespace amazon-cloudwatch amazon-cloudwatch aws-observability/amazon-cloudwatch-observability\
    --set clusterName=my-cluster-name\
    --set region=my-cluster-region