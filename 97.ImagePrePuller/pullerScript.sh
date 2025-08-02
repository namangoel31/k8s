#!/bin/bash
set -e

AWS_REGION="ap-south-1"
SOCKET_PATH="/run/containerd/containerd.sock"

while true; do
  echo "[$(date)] Starting image pull cycle..."
  
  ECR_PASSWORD=$(aws ecr get-login-password --region $AWS_REGION)

  while IFS= read -r image; do
    if [ -n "$image" ]; then
      echo "Pulling: $image"
      ctr --address ${SOCKET_PATH} \
          images pull --user AWS:$ECR_PASSWORD "$image" \
          || echo "Failed to pull $image"
    fi
  done < /etc/images.txt
  
  echo "[$(date)] Pull cycle complete. Sleeping 30 minutes..."
  sleep 1800
done