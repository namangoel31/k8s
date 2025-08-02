# IRSA

## PRE-REQUISITE: OIDC PROVIDER FOR THE CLUSTER

## Create a policy
-> create a JSON policy doc with all the required permissions
-> create iam policy using aws-cli

## Create IAM role for service account

### using eksctl
-> create a policy withe the required permissions
-> using a single eksctl command, 
  - we create a role with appropriate trust policy
  - attach the policy above to the role
  - create a serrvice account in out kubernetes cluster
  - annotate the service account to use the IAM role.
REFER TO: /autoWithEksctl/IRSAusingEksctl.yaml

### manually
-> create a policy withe the required permissions
-> create a role using an appropriate trust policy so that the kubernetes resources can utilise the IAM role
-> attach the newly created policy to the role.
-> create a service account
-> annotate the service account to use the role we just created.
REFER TO: /manually/IRSAmanuallyDeclarative.yaml or /manually/IRSAmanuallyImperative.yaml