FROM alpine:3.20

# Install bash, wget, tar, AWS CLI
RUN apk add --no-cache bash wget tar aws-cli containerd-ctr

# Install crictl (stable Kubernetes CRI client)
RUN CRICTL_VERSION="v1.30.0" && \
    wget -q https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz && \
    tar -C /usr/local/bin -xzf crictl-${CRICTL_VERSION}-linux-amd64.tar.gz && \
    rm crictl-${CRICTL_VERSION}-linux-amd64.tar.gz

RUN crictl --version
RUN ctr --version

# Copy puller script
COPY pullerScript.sh /pull-images.sh
RUN chmod +x /pull-images.sh

ENTRYPOINT ["/pull-images.sh"]
