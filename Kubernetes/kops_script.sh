#This is for kops > Run the script twice > 1 without AWS configure > 2 with AWS configure
#!/bin/bash

#updating packages and installing aws cli
sudo apt update -y

#AWS CLI installation
sudo apt install awscli -y

#Kubectl installation
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client

#Kops installation
curl -Lo kops https://github.com/kubernetes/kops/releases/latest/download/kops-linux-amd64
chmod +x kops
sudo mv kops /usr/local/bin/


#Create SSH key pair for kops
ssh-keygen -t ed25519 -f ~/.ssh/kops-key -N "" && ls -l ~/.ssh/kops-key ~/.ssh/kops-key.pub

#Create S3 bucket for kops state store
export AWS_REGION=us-east-1

aws s3api create-bucket \
--bucket test-kops-state-2026 \
--region us-east-1
#Enable Versioning:
aws s3api put-bucket-versioning \
--bucket test-kops-state-2026 \
--versioning-configuration Status=Enabled
#Before Deleting S3 : stop versioning and Empty the bucket.
#Export Variable:
export KOPS_STATE_STORE=s3://test-kops-state-2026
#Verify:
echo $KOPS_STATE_STORE


#create cluster
export CLUSTER_NAME=test.k8s.local
#Availability Zone:
export ZONE=us-east-1a
#Create Cluster:
kops create cluster \
--name ${CLUSTER_NAME} \
--state ${KOPS_STATE_STORE} \
--zones ${ZONE} \
--node-count 2 \
--control-plane-count 1 \
--node-size t3.medium \
--control-plane-size t3.medium \
--networking calico \
--ssh-public-key ~/.ssh/kops-key.pub \
--yes

#Validate:
kops validate cluster \
--name ${CLUSTER_NAME}
