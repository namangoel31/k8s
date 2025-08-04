#!/bin/sh

#Steps
#-> setup knative but do not configureDNS
#-> in the kourier domain config, add you public alb DNS
#-> create a TG and add kouries alb private IP as targets. (nslookup)
#-> create a rule in in you public alb with this new TG as listener.
#-> hit the public alb for newly created rule with with knative svc url as header Host. strip 'http://' from knative svc url


#add our load balancer to domain config of kourier service
######## ALB NAME NEEDS TO BE PROVIDEDE by USER ########

ALB_NAME=''
SCHEME="internet-facing"   # or "internal"
VPC_ID=""
SUBNETS="subnet-aaa subnet-bbb"   # space-separated list. DO NOT LISTEN TO CHATGPT
SECURITY_GROUPS=""
TAGS="Key=<keyName>,Value=<Value>"
TG_NAME=""

echo "Checking if ALB '${ALB_NAME}' exists..."
ALB_ARN=$(aws elbv2 describe-load-balancers \
    --names "${ALB_NAME}" \
    --query "LoadBalancers[0].LoadBalancerArn" \
    --output text 2>/dev/null)

if [[ "$ALB_ARN" != "None" && -n "$ALB_ARN" ]]; then
    echo "ALB already exists: $ALB_ARN"
else
    echo "ALB not found. Creating..."
    ALB_ARN=$(aws elbv2 create-load-balancer \
        --name "${ALB_NAME}" \
        --scheme "${SCHEME}" \
        --type application \
        --subnets ${SUBNETS} \
        --security-groups ${SECURITY_GROUPS} \
        --tags ${TAGS} \
        --query "LoadBalancers[0].LoadBalancerArn" \
        --output text)

    if [[ $? -eq 0 ]]; then
        echo "ALB created successfully: $ALB_ARN"
    else
        echo "Failed to create ALB"
    fi
fi

# ALB_ARN=$(aws elbv2 describe-load-balancers \
#   --names "$ALB_NAME" \
#   --query 'LoadBalancers[0].LoadBalancerArn' \
#   --output text)

# if [ "$ALB_ARN" == "None" ]; then
#     echo "ERROR: ALB '$ALB_NAME' not found."
#     exit 1
# fi

ALB_DNS=$(aws elbv2 describe-load-balancers \
  --load-balancer-arns "$ALB_ARN" \
  --query 'LoadBalancers[0].DNSName' \
  --output text)

echo "ALB DNS: $ALB_DNS"

kubectl patch configmap config-domain -n knative-serving \
  --type merge \
  -p "{\"data\": {\"$ALB_DNS\": \"\"}}"

#get kourier loadBalancer DNS name
lbDNS=$(kubectl get svc -n kourier-system --no-headers | awk '$2=="LoadBalancer" {print $4}')

#get IP for fetched DNS
nslookup $lbDNS

#extract the private IPs of knative LoadBalancer
mapfile -t lbips < <(
  nslookup "$lbDNS" |
  awk -v dns="$lbDNS" '
    $0 ~ "^Name:[ \t]*"dns {getline; if ($1=="Address:") print $2}
  '
)

lbip1=${lbips[0]}
lbip2=${lbips[1]}

#now create a target group and register these IPs at targets in the target group
TG_ARN=$(aws elbv2 create-target-group \
  --name $TG_NAME \
  --protocol HTTP \
  --port 80 \
  --target-type ip \
  --vpc-id $VPC_ID \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

aws elbv2 register-targets \
  --target-group-arn "$TG_ARN" \
  --targets Id=$lbip1 Id=$lbip2


LISTENER_ARN=$(aws elbv2 describe-listeners \
  --load-balancer-arn "$ALB_ARN" \
  --query "Listeners[?Port==\`80\`].ListenerArn" \
  --output text)

if [ -z "$LISTENER_ARN" ]; then
    echo "Listener on port $PORT not found. Creating..."
    LISTENER_ARN=$(aws elbv2 create-listener \
      --load-balancer-arn "$ALB_ARN" \
      --protocol HTTP \
      --port 80 \
      --default-actions Type=fixed-response,FixedResponseConfig="{StatusCode=404,ContentType=text/plain,MessageBody=\"Not Found\"}" \
      --query 'Listeners[0].ListenerArn' \
      --output text)
    echo "Listener created with 404 default action: $LISTENER_ARN"
else
    echo "Listener already exists: $LISTENER_ARN"
fi

#create a new listener rule in Public ALB which points to this TG
aws elbv2 create-rule --listener-arn "$LISTENER_ARN" --priority 1 \
--conditions 'Field=path-pattern,Values="/filemanager/*","/filemanager"' \
--actions Type=forward,TargetGroupArn="$TG_ARN"


#et voila!! Now you can hit your knative service using curl.
