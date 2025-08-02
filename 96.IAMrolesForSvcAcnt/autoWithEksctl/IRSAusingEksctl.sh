#!/bin/sh

policyName=''
cluster=''
namespace=''
service_account=''

cat > policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer"
      ],
      "Resource": "*"
    }
  ]
}
EOF

policy_arn=$(aws iam create-policy \
  --policy-name $policyName\
  --policy-document file://policy.json \
  --query 'Policy.Arn' \
  --output text)

eksctl create iamserviceaccount \
  --cluster $cluster \
  --namespace $namespace \
  --name $service_account \
  --attach-policy-arn $policy_arn \
  --approve