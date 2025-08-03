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