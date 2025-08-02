#!/bin/sh

policy_name=''
role_name=''
cluster=''
namespace=''
service_account=''
account_id=$(aws sts get-caller-identity --query Account --output text)
echo $account_id

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
  --policy-name $policy_name \
  --policy-document file://policy.json \
  --query 'Policy.Arn' \
  --output text)
echo $policy_arn

oidc_provider=$(aws eks describe-cluster --name $cluster --query "cluster.identity.oidc.issuer" --output text | sed -E 's/^\s*.*:\/\///g')
echo $oidc_provider

cat > trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::$account_id:oidc-provider/$oidc_provider"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "$oidc_provider:sub": "system:serviceaccount:$namespace:$service_account"
        }
        
      }
    }
  ]
}
EOF

role_arn=$(aws iam create-role \
  --role-name $role_name \
  --assume-role-policy-document file://trust-policy.json \
  --query 'Role.Arn' \
  --output text)
echo $role_arn

aws iam attach-role-policy \
  --role-name $role_name \
  --policy-arn "$policy_arn"

kubectl create sa $service_account -n $namespace

kubectl annotate serviceaccount $service_account -n $namespace eks.amazonaws.com/role-arn=$role_arn
