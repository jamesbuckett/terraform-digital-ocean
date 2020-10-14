# Author:  James Buckett
# eMail: james.buckett@gmail.com
# Script to install various components onto the cluster

#!/bin/bash

# doctl - DigitalOcean command-line client authorize access to the Kubernetes Cluster
doctl auth init --access-token "xxx"
doctl kubernetes cluster kubeconfig save digital-ocean-cluster

kubectl config use-context do-sgp1-digital-ocean-cluster

# metrics server - container resource metrics
kubectl create namespace ns-metrics-server
kubectl apply -f "https://raw.githubusercontent.com/jamesbuckett/kubernetes-tools/master/components.yaml"

# Contour - Ingress
# helm upgrade --install contour-release stable/contour 
#--set service.loadBalancerType=LoadBalancer \
#--namespace=ns-contour \
#--create-namespace

# NGINX Ingress - Ingress 
# helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
# helm install nginx-release ingress-nginx/ingress-nginx \
#--namespace=ns-nginx \
#--create-namespace

# Online Boutique - Sample Microservices Application
kubectl create namespace ns-microservices-demo
kubectl apply -n ns-microservices-demo -f "https://raw.githubusercontent.com/jamesbuckett/microservices-metrics-chaos/master/complete-demo.yaml"

# Gremlin - Managed Chaos Engineering Platfom
helm repo remove gremlin
helm repo add gremlin https://helm.gremlin.com

# Loki -  Distributed Log Aggregation
helm repo remove loki
helm repo add loki https://grafana.github.io/loki/charts
helm repo update
helm upgrade \
--install loki-release loki/loki-stack -f  "https://raw.githubusercontent.com/jamesbuckett/terraform-digital-ocean/master/values/loki-values.yml" \
--namespace=ns-loki \
--create-namespace

# Chaos Mesh - Chaos Engineering Platfom
#Link: https://pingcap.com/blog/Chaos-Mesh-1.0-Chaos-Engineering-on-Kubernetes-Made-Easier
helm repo remove chaos-mesh 
helm repo add chaos-mesh https://charts.chaos-mesh.org
curl -sSL https://mirrors.chaos-mesh.org/v1.0.0/crd.yaml | kubectl apply -f -

helm upgrade \
--install chaos-mesh-release chaos-mesh/chaos-mesh \
--set dashboard.create=true \
--namespace=ns-chaos-mesh \
--create-namespace
# Cannot remember why i put this sleep in
sleep 30s

# GraphQL - Convert Kubernetes API server into GraphQL API
# https://github.com/onelittlenightmusic/kubernetes-graphql
helm repo remove kubernetes-graphql  
helm repo add kubernetes-graphql https://onelittlenightmusic.github.io/kubernetes-graphql/helm-chart

helm upgrade \
--install kubernetes-graphql-release kubernetes-graphql/kubernetes-graphql \
--namespace=ns-graphql  \
--create-namespace

# Vertical Pod Autoscaler and Goldilocks - Vertical Pod Autoscaler recommendations
# Link: https://learnk8s.io/setting-cpu-memory-limits-requests
helm repo remove fairwinds-stable
helm repo add fairwinds-stable https://charts.fairwinds.com/stable

helm upgrade \
--install vpa-release fairwinds-stable/vpa \
--namespace=ns-vpa \
--create-namespace

helm upgrade \
--install goldilocks-release fairwinds-stable/goldilocks \
--set dashboard.service.type=LoadBalancer \
--namespace =ns-goldilocks \
--create-namespace

kubectl label namespace default goldilocks.fairwinds.com/enabled=true
kubectl label namespace kube-node-lease goldilocks.fairwinds.com/enabled=true
kubectl label namespace kube-public goldilocks.fairwinds.com/enabled=true
kubectl label namespace kube-system goldilocks.fairwinds.com/enabled=true
kubectl label namespace ns-chaos-mesh goldilocks.fairwinds.com/enabled=true
kubectl label namespace ns-loki  goldilocks.fairwinds.com/enabled=true
kubectl label namespace ns-goldilocks goldilocks.fairwinds.com/enabled=true
kubectl label namespace ns-metrics-server goldilocks.fairwinds.com/enabled=true
kubectl label namespace ns-microservices-demo goldilocks.fairwinds.com/enabled=true
kubectl label namespace ns-vpa goldilocks.fairwinds.com/enabled=true
kubectl label namespace ns-graphql  goldilocks.fairwinds.com/enabled=true

# Export the Public IP where Octant can be located
DROPLET_ADDR=$(doctl compute droplet list | awk 'FNR == 2 {print $3}')
export DROPLET_ADDR

# Update .bashrc
cd ~
# echo "source <(kubectl completion bash)" >>~/.bashrc
echo "alias cls='clear'" >> ~/.bashrc
echo "alias k='kubectl'" >> ~/.bashrc
echo "alias kga='kubectl get all'" >> ~/.bashrc
echo "KUBE_PS1_SYMBOL_ENABLE=false" >>~/.bashrc
echo "source /opt/kube-ps1/kube-ps1.sh" >>~/.bashrc
echo "export DROPLET_ADDR=$DROPLET_ADDR" >> ~/.bashrc
echo "export OCTANT_ACCEPTED_HOSTS=$DROPLET_ADDR" >> ~/.bashrc
echo "export OCTANT_DISABLE_OPEN_BROWSER=1" >> ~/.bashrc
echo "export OCTANT_LISTENER_ADDR=0.0.0.0:8900" >> ~/.bashrc

reboot

#End of Script