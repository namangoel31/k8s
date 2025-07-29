#extract the url for knative service.
url=$(kubectl get ksvc -n <namespace> | grep <serviceName> | awk '{print $2}')

#hit the url using curl
curl $url

#hitting knative service using load balancer
curl -H "Host: ${url#http://}" <albAddress>

#hitting knative service from within cluster
curl <serviceName>.<namespaceName>.svc.cluster.local

#watching the scaling up and down
kubectl get pod -l serving.knative.dev/service=<serviceName> -w