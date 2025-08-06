#!/bin/sh

#Steps: 
# 1. edit kourier service from loadBalancer to Cluster ip
# 2. in the kourier domain config, add you public alb DNS
# 3. then curl from within the container: curl -vk --http2 http://<kourier-service-cluster-ip   -H "Host: <serviceName>.<namespace>.<alb-dns>"

##################### curl from external sources 
# create a target group
    # target_type: IP 
    # protocol: Http
    # port: 80
    # protocol_version: HTTP1

# crete a target group binding
    # apiVersion: elbv2.k8s.aws/v1beta1
    # kind: TargetGroupBinding
    # metadata:
    #   name: test-tg-binding-for-knative-http
    #   namespace: kourier-system # Must be in the same namespace as your Service
    # spec:
    #   serviceRef:
    #     name: kourier
    #     port: 80 # The 'port' of the Kubernetes Service that corresponds to the target group port
    #   targetGroupARN: <arn-of-target-group-created-above>
    #   targetType: ip

# add an http listener to your alb and forward all requests to this target group.

ALB_NAME=''
SCHEME="internet-facing"   # or "internal"
VPC_ID=""
SUBNETS="subnet-aaa subnet-bbb"   # space-separated list. DO NOT LISTEN TO CHATGPT
SECURITY_GROUPS=""
TAGS="Key=<keyName>,Value=<Value>"
TG_NAME=""
CLIENT_NAME=""
BINDING_NAME="${CLIENT_NAME}-tgbinding" #should be lowecase


#patching kourier service to use ClusterIP type service instead of LoadBalancer type svc
kubectl patch svc kourier -n kourier-system -p '{"spec":{"type":"ClusterIP"}}'
kubectl get svc -n kourier-system


#checking if alb exists with the provided name. if not, one will be created.
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

#fetching alb DNS for our newly created ALB. We need this to update out knative-serving config-domain config map
ALB_DNS=$(aws elbv2 describe-load-balancers \
  --load-balancer-arns "$ALB_ARN" \
  --query 'LoadBalancers[0].DNSName' \
  --output text)

echo "ALB DNS: $ALB_DNS"

# FOR ONE ALB PER CLUSTER
# Updating knative serving config-domain config map with our ALB DNS
# kubectl patch configmap config-domain -n knative-serving \
#   --type merge \
#   -p "{\"data\": {\"$ALB_DNS\": \"\"}}"

#FOR MULTIPLE ALBs PER CLUSTER
#####################################################################################################
# If using multiple ALBs per cluster, make sure to add appropriate selector to your knative service #
#####################################################################################################
# Updating knative serving config-domain config map with our ALB DNS
kubectl patch configmap config-domain \
  -n knative-serving \
  --type merge \
  --patch "
data:
  ${ALB_DNS}: |
    selector:
      client: ${CLIENT_NAME}
"


#Creating a target group
TG_ARN=$(aws elbv2 create-target-group \
  --name $TG_NAME \
  --protocol HTTP \
  --port 80 \
  --target-type ip \
  --vpc-id $VPC_ID \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

#checking if a listener exists fro port 80 (http)
LISTENER_ARN=$(aws elbv2 describe-listeners \
  --load-balancer-arn "$ALB_ARN" \
  --query "Listeners[?Port==\`80\`].ListenerArn" \
  --output text)

#if http listener doesn'r exist, create one.
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

#create a rule for listener and register the target group to forward the requests to.
aws elbv2 create-rule --listener-arn "$LISTENER_ARN" --priority 1 \
--conditions 'Field=path-pattern,Values="/filemanager/*","/filemanager"' \
--actions Type=forward,TargetGroupArn="$TG_ARN"

#create a targetGroupBindingFile
cat > "tgBinding.yaml" <<EOF
apiVersion: elbv2.k8s.aws/v1beta1
kind: TargetGroupBinding
metadata:
  name: ${BINDING_NAME}
  namespace: kourier-system
spec:
  serviceRef:
    name: kourier
    port: 80
  targetGroupARN: ${TG_ARN}
  targetType: ip
EOF

#create a target group binging using the manifest file created above
kubectl create -f tgBinding.yaml

# create you knative service 
# AND CURL!!!
# curl http://<alb-DNS> -H <serviceName>.<namespace>.<alb-DNS>


#####################################################################################################
# to stop passing header, we need to put up DNS records.
# To access with curl without a header:

# make a DNS Aname entry with desired domain which resolves to your alb. "*.something.someDomain.com"
# put this domain in your knative-serving config-domain config map -> something.someDomain.com
# now curl: curl <serviceName>.<namespace>.something.someDomain.com
######################################################################################################