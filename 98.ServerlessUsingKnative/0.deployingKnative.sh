#!/bin/sh

#deploying knative serving CRDs
kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.18.1/serving-crds.yaml

#deploying knative serving core
kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.18.1/serving-core.yaml

#installing the network layer (kourier) and configuring knative serving to use it
    #installing kourier
    kubectl apply -f https://github.com/knative/net-kourier/releases/download/knative-v1.18.0/kourier.yaml

    #configuring knative serving to use kourier
    kubectl patch configmap/config-network \
    --namespace knative-serving \
    --type merge \
    --patch '{"data":{"ingress-class":"kourier.ingress.networking.knative.dev"}}'

    #Fetch the External IP address or CNAME
    kubectl --namespace kourier-system get service kourier

#Verify the installation
kubectl get pods -n knative-serving

#Configuring DNS (Magic DNC (sslip.io))
# kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.18.1/serving-default-domain.yaml

#creating knative hpa
kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.19.0/serving-hpa.yaml
