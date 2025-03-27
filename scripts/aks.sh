#!/bin/bash

set -eo pipefail

SUBSCRIPTION=137f0351-8235-42a6-ac7a-6b46be2d21c7
RESOURCE_GROUP=elk-test
LOCATION=eastus2
CLUSTER_NAME=elk-test
SYSTEM_POOL_NAME=system
SYSTEM_VM_SIZE=Standard_D8ds_v5
SYSTEM_POOL_SIZE=3
SERVER_POOL_NAME=server
SERVER_VM_SIZE=Standard_D32Ps_v5
SERVER_POOL_SIZE=3
VNET_CIDR="10.0.0.0/8"
SUBNET_CIDR="10.1.0.0/16"

az account set -s ${SUBSCRIPTION}
if az group show -n ${RESOURCE_GROUP} &>/dev/null; then
    echo "Resource group already exists."
else
    echo "Resource group does not exist. Creating ..."
    az group create -l ${LOCATION} -n ${RESOURCE_GROUP}
fi

IP_NAME=${CLUSTER_NAME}-ip
if az network public-ip show -g ${RESOURCE_GROUP} -n ${IP_NAME} &>/dev/null; then
    echo "Public IP already exists."
else
    echo "Public IP does not exist. Creating ..."
    az network public-ip create -g ${RESOURCE_GROUP} \
        -n ${IP_NAME} \
        --sku Standard
fi
PUBLIC_IP_ID=$(az network public-ip show -g ${RESOURCE_GROUP} -n ${IP_NAME} | jq -r '.id')

GATEWAY_NAME=${CLUSTER_NAME}-gateway
if az network nat gateway show -g ${RESOURCE_GROUP} -n ${GATEWAY_NAME} &>/dev/null; then
    echo "NAT gateway already exists."
else
    echo "NAT gateway does not exist. Creating ..."
    az network nat gateway create -g ${RESOURCE_GROUP} \
        -n ${GATEWAY_NAME} \
        --public-ip-addresses ${PUBLIC_IP_ID}
fi
NAT_GATEWAY_ID=$(az network nat gateway show -g ${RESOURCE_GROUP} -n ${GATEWAY_NAME} | jq -r '.id')

VNET_NAME=${CLUSTER_NAME}-net
if az network vnet show -g ${RESOURCE_GROUP} -n ${VNET_NAME} &>/dev/null; then
    echo "VNET already exists."
else
    echo "VNET does not exist. Creating ..."
    az network vnet create -g ${RESOURCE_GROUP} \
        -n ${VNET_NAME} \
        --address-prefixes ${VNET_CIDR}
fi

if az network vnet subnet show -g ${RESOURCE_GROUP} --vnet-name ${VNET_NAME} --name nodes &>/dev/null; then
    echo "Nodes subnet already exists."
else
    echo "Nodes subnet does not exist. Creating ..."
    az network vnet subnet create -g ${RESOURCE_GROUP} \
        --vnet-name ${VNET_NAME} \
        --name nodes \
        --address-prefixes ${SUBNET_CIDR} \
        --nat-gateway ${NAT_GATEWAY_ID}
fi
NODE_SUBNET_ID=$(az network vnet subnet show -g ${RESOURCE_GROUP} --vnet-name ${VNET_NAME} --name nodes | jq -r '.id')

if az aks show -g ${RESOURCE_GROUP} -n ${CLUSTER_NAME} &>/dev/null; then
    echo "Managed cluster already exists."
else
    echo "Managed cluster does not exist. Creating ..."
    az aks create -l ${LOCATION} \
        -g ${RESOURCE_GROUP} \
        -n ${CLUSTER_NAME} \
        --tier standard \
        --nodepool-name ${SYSTEM_POOL_NAME} \
        --node-vm-size ${SYSTEM_VM_SIZE} \
        --node-count ${SYSTEM_POOL_SIZE} \
        --outbound-type userAssignedNATGateway \
        --network-plugin azure \
        --network-plugin-mode overlay \
        --network-dataplane cilium \
        --network-policy cilium \
        --vnet-subnet-id ${NODE_SUBNET_ID}
fi

if az aks nodepool show --resource-group ${RESOURCE_GROUP} --cluster-name ${CLUSTER_NAME} --name ${SERVER_POOL_NAME} &>/dev/null; then
    echo "Server pool already exists."
else
    echo "Server pool does not exist. Creating ..."
    az aks nodepool add \
        --resource-group ${RESOURCE_GROUP} \
        --cluster-name ${CLUSTER_NAME} \
        --name ${SERVER_POOL_NAME} \
        --node-vm-size ${SERVER_VM_SIZE} \
        --node-count ${SERVER_POOL_SIZE} \
        --vnet-subnet-id ${NODE_SUBNET_ID}
fi

az aks get-credentials --resource-group ${RESOURCE_GROUP} \
    --name ${CLUSTER_NAME} \
    --overwrite-existing