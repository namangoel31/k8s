#creating a pod (imperative)
kubectl run <podName> --image=<imageURI_or_Name>

#creating a pod from file (decalrative)
kubectl create -f <fileName>.yaml

#get pods
kubectl get pods

#get pods in a namecspace
kubectl get po -n <namespace>

#get pods with extra details like host node, ip, etc
kubectl -n <namespace> get po <podName> -o wide

#get pod details
kubectl -n <namespace> describe po <podName>

#save pod definition to file
kubectl get po <podname> -o yaml > <fileName>.yaml

#delete a pod (imperative)
kubectl -n <namespace> delete po <podName>

#delete a pod (declerative)
kubectl delete -f <fileName>.yaml

#edit a pod on the fly
kubectl -n <namespace> edit po <podName>
(NOTE: not all configuration can be edited on the fly. Some property changes require the pod to be rescheduled.)

#edit a pod (reschedule)
    1. extract pod yaml file:
        kubectl get po <podname> -o yaml > <fileName>.yaml
    2. edit the yaml file 
        nano <fileName>.yaml
        (NOTE: yaml file contains readOnly properties which need to be deleted before proceeding)
    3. delete the existing pod
        kubectl -n <namespace> delete po <podName>
    4. create a new pod using the extracted pod definition
        kubectl create -f <fileName>.yaml

#get inside the pod
kubectl -n <namespace> exec -it <podName> <command>

#view logs of a pod
kubectl -n <namespace> logs <podName>
