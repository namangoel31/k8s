#!/bin/sh

#Steps: 
# 1. edit kourier service from loadBalancer to Cluster ip
# 2. in the kourier domain config, add you public alb DNS
# 3. then curl from within the container: curl -vk --http2 http://<kourier-service-cluster-ip   -H "Host: <serviceName>.<namespace>.<alb-dns>"

##################### curl from external sources still pending