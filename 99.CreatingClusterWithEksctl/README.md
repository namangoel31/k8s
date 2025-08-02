1. VPC considerations:
    - select the application VPC as the VPC of choice for EKS
    - include both public and private subnets from the VPC
2. Security Group considerations:
    - EKS creats its own security group but we'll attach a custom SG with it for out apps and extra nodes to be able to connect.
    - Custom SG considerations:
        - allow all incoming and outgoing traffic.
        - putiing this SG in cluster config will result in this SG being selected as the additional SG.
3. AddOns:
    - EKS auto mode already has coreDNS, VPC CNI Plugin, kube-proxy, EKS Pod Identity Agent, and EBS SCI Driver
4. Endoint considerations:
    - do not expose endpoints for public access.

5. For custom NodeGroups
    - create VPC CNI