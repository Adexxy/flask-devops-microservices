#!/bin/bash

# Set your VPC ID manually or pass as argument
VPC_ID="${1:-vpc-xxxxxxxxxxxxxxxxx}"

echo "🔍 Cleaning up resources in VPC: $VPC_ID"

# Get all subnet IDs in the VPC
SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" \
  --query "Subnets[*].SubnetId" --output text)

echo "📍 Subnets found: $SUBNET_IDS"

# --- Step 1: Terminate EC2 instances in the VPC ---
INSTANCE_IDS=$(aws ec2 describe-instances \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query "Reservations[*].Instances[*].InstanceId" --output text)

if [[ -n "$INSTANCE_IDS" ]]; then
  echo "🛑 Terminating EC2 Instances: $INSTANCE_IDS"
  aws ec2 terminate-instances --instance-ids $INSTANCE_IDS
  echo "⏳ Waiting for instances to terminate..."
  aws ec2 wait instance-terminated --instance-ids $INSTANCE_IDS
else
  echo "✅ No EC2 instances found."
fi

# --- Step 2: Delete NAT Gateways ---
for SUBNET_ID in $SUBNET_IDS; do
  NAT_IDS=$(aws ec2 describe-nat-gateways --filter "Name=subnet-id,Values=$SUBNET_ID" \
    --query "NatGateways[*].NatGatewayId" --output text)

  if [[ -n "$NAT_IDS" ]]; then
    for NAT_ID in $NAT_IDS; do
      echo "🧨 Deleting NAT Gateway: $NAT_ID"
      aws ec2 delete-nat-gateway --nat-gateway-id "$NAT_ID"
    done
  fi
done

# Wait for NAT Gateways to be deleted
echo "⏳ Waiting for NAT Gateway deletion..."
sleep 60

# --- Step 3: Release Elastic IPs ---
ALLOC_IDS=$(aws ec2 describe-addresses \
  --query "Addresses[?VpcId=='$VPC_ID'].AllocationId" --output text)

if [[ -n "$ALLOC_IDS" ]]; then
  for ALLOC_ID in $ALLOC_IDS; do
    echo "🔓 Releasing Elastic IP: $ALLOC_ID"
    aws ec2 release-address --allocation-id "$ALLOC_ID"
  done
else
  echo "✅ No Elastic IPs found."
fi

# --- Step 4: Delete Load Balancers (Classic + ALB) ---
CLB_NAMES=$(aws elb describe-load-balancers \
  --query "LoadBalancerDescriptions[?VPCId=='$VPC_ID'].LoadBalancerName" --output text)

if [[ -n "$CLB_NAMES" ]]; then
  for NAME in $CLB_NAMES; do
    echo "🗑️ Deleting Classic Load Balancer: $NAME"
    aws elb delete-load-balancer --load-balancer-name "$NAME"
  done
fi

ALB_ARNs=$(aws elbv2 describe-load-balancers \
  --query "LoadBalancers[?VpcId=='$VPC_ID'].LoadBalancerArn" --output text)

if [[ -n "$ALB_ARNs" ]]; then
  for ARN in $ALB_ARNs; do
    echo "🗑️ Deleting Application Load Balancer: $ARN"
    aws elbv2 delete-load-balancer --load-balancer-arn "$ARN"
  done
fi

# --- Step 5: Delete Network Interfaces (ENIs) ---
ENI_IDS=$(aws ec2 describe-network-interfaces \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query "NetworkInterfaces[*].NetworkInterfaceId" --output text)

if [[ -n "$ENI_IDS" ]]; then
  for ENI_ID in $ENI_IDS; do
    echo "🧹 Deleting ENI: $ENI_ID"
    aws ec2 delete-network-interface --network-interface-id "$ENI_ID" || echo "❗Failed to delete $ENI_ID, may be in use"
  done
else
  echo "✅ No ENIs found."
fi

# --- Step 6: Detach & Delete Internet Gateway ---
IGW_ID=$(aws ec2 describe-internet-gateways \
  --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
  --query "InternetGateways[*].InternetGatewayId" --output text)

if [[ -n "$IGW_ID" ]]; then
  echo "🔌 Detaching Internet Gateway: $IGW_ID"
  aws ec2 detach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID"
  echo "🗑️ Deleting Internet Gateway..."
  aws ec2 delete-internet-gateway --internet-gateway-id "$IGW_ID"
else
  echo "✅ No Internet Gateway found."
fi

echo "✅ Cleanup complete. You can now run: terraform destroy"
