################################################################################
# Author: James Buckett
# email: james.buckett@gmail.com
# Script to setup post-install tasks
################################################################################

#!/bin/bash

################################################################################
# Check that you are on jump host and not local host
################################################################################
if [ "$HOSTNAME" = "digital-ocean-droplet" ]; then


################################################################################
# Clear any previous installations
################################################################################
cd ~/ && rm -R ~/locust
clear


################################################################################
# Stop the script on errors
################################################################################
set -euo pipefail


################################################################################
# Clone Useful Repositories
################################################################################
git clone https://github.com/jamesbuckett/intro-to-k8s.git
#kubectl apply -f ~/intro-to-k8s/src

################################################################################
# Contour Ingress - Export the Public IP address of Contour Ingress 
################################################################################

# The host names, like "demo.jamesbuckett.com" are CNAME records 
# to the "do.jamesbuckett.com" A record  

INGRESS_LB=$(doctl compute load-balancer list | awk 'FNR == 2 {print $2}')
export INGRESS_LB

doctl compute domain records create --record-type A --record-name www --record-data $INGRESS_LB jamesbuckett.com --record-ttl=43200
doctl compute domain records create jamesbuckett.com --record-type CNAME --record-name demo --record-data www. --record-ttl=43200
doctl compute domain records create jamesbuckett.com --record-type CNAME --record-name loki --record-data www. --record-ttl=43200
doctl compute domain records create jamesbuckett.com --record-type CNAME --record-name vpa --record-data www. --record-ttl=43200
doctl compute domain records create jamesbuckett.com --record-type CNAME --record-name chaos --record-data www. --record-ttl=43200


################################################################################
# Loki - Export the Public IP address of Loki and display the password to login
################################################################################
# LOKI_LB=$(doctl compute load-balancer list | awk 'FNR == 3 {print $2}')
# export LOKI_LB
LOKI_PWD=$(kubectl get secret --namespace ns-loki loki-release-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo)
export LOKI_PWD


################################################################################
# Update .bashrc
################################################################################
cd ~
cp .bashrc .bashrc-original
echo "export LOKI_PWD=$LOKI_PWD" >> ~/.bashrc


################################################################################
# Update Message of the Day
################################################################################
echo "*################################################################################"
echo "* Reference URLs in this tutorial" >> /etc/motd
echo "*################################################################################"
echo "**********************************************************************************************" >> /etc/motd
echo "* Real-time Kubernetes Dashboard - Octant is here: $DROPLET_ADDR:8900 or octant.jamesbuckett.com " >> /etc/motd
echo "* Sample Microservices Application - Online Boutique is here: demo.jamesbuckett.com " >> /etc/motd
echo "* Chaos Engineering Platfom - Chaos Mesh is here: chaos.jamesbuckett.com " >> /etc/motd
echo "* Vertical Pod Autoscaler recommendations - Goldilocks is here: vpa.jamesbuckett.com " >> /etc/motd
echo "* Distributed Log Aggregation - Loki is here: loki.jamesbuckett.com " >> /etc/motd
echo "* Loki User:  admin   Loki Password: $LOKI_PWD" >> /etc/motd
echo "* Load Testing Tool - Locust is here: $DROPLET_ADDR:8089 " >> /etc/motd
echo "* Locust values are Spawn:100 & URL: demo.jamesbuckett.com " >> /etc/motd                      
echo "* To start Locust & Octant, open another shell and execute: sh /root/locust/startup-locust.sh " >> /etc/motd      
echo "* PS1='[\u@\h \w $(kube_ps1)]\$ ' to .bashrc"  >> /etc/motd
echo "**********************************************************************************************" >> /etc/motd


################################################################################
# Locust - Setup Locust
################################################################################
cd ~/ && mkdir locust && cd locust
wget https://raw.githubusercontent.com/jamesbuckett/microservices-metrics-chaos/master/locustfile.py
wget https://raw.githubusercontent.com/jamesbuckett/terraform-digital-ocean/master/service/startup-locust.sh
chmod +x startup-locust.sh


################################################################################
# Octant Load Balancer - octant.jamesbuckett.com
################################################################################
doctl compute load-balancer create \
    --name digitalocean-loadbalancer \
    --region sgp1 \
    --tag-name digital-ocean-droplet \
    --forwarding-rules entry_protocol:http,entry_port:80,target_protocol:http,target_port:8900
   
OCTANT_LB=$(doctl compute load-balancer list | awk 'FNR == 3 {print $2}')
export OCTANT_LB

doctl compute domain records create --record-type A --record-name www --record-data $OCTANT_LB octant --record-ttl=43200

# octant.jamesbuckett.com
# maps to
# digitalocean-loadbalancer
# maps to
# digital-ocean-droplet

# To Do
# Add the Health Check to Port 8900 the Octant Port
#doctl compute load-balancer add-droplets digitalocean-loadbalancer digital-ocean-droplet


################################################################################
# Under Development
################################################################################

# Nothing here


################################################################################
# Clear terminal history
################################################################################
history -c

clear
echo " "
echo " "
echo "03-post-install-prep.sh complete...rebooting"
sleep 5s

# Reboot Jump Host
sudo reboot

else
    echo "You are not on the jump host : digital-ocean-droplet"
    exit
fi

# End of Script
