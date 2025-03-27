#!/bin/bash

set -eo pipefail

SUBSCRIPTION=137f0351-8235-42a6-ac7a-6b46be2d21c7
RESOURCE_GROUP=elk-test
LOCATION=eastus2
VM_NAME=client
VM_SIZE=Standard_D32s_v5
VNET_NAME=${VM_NAME}-net
VNET_CIDR="192.168.0.0/16"
SUBNET_CIDR="192.168.1.0/24"

az account set -s ${SUBSCRIPTION}

# Create VNET and subnet for the client
if az network vnet show -g ${RESOURCE_GROUP} -n ${VNET_NAME} &>/dev/null; then
    echo "VNET already exists."
else
    echo "Creating client VNET..."
    az network vnet create \
        -g ${RESOURCE_GROUP} \
        -n ${VNET_NAME} \
        --address-prefix ${VNET_CIDR} \
        --subnet-name default \
        --subnet-prefix ${SUBNET_CIDR}
fi

# Create public IP
IP_NAME=${VM_NAME}-ip
if az network public-ip show -g ${RESOURCE_GROUP} -n ${IP_NAME} &>/dev/null; then
    echo "Public IP already exists."
else
    echo "Creating public IP..."
    az network public-ip create \
        -g ${RESOURCE_GROUP} \
        -n ${IP_NAME} \
        --sku Standard \
        --allocation-method Static
fi

# Create NSG
NSG_NAME=${VM_NAME}-nsg
if az network nsg show -g ${RESOURCE_GROUP} -n ${NSG_NAME} &>/dev/null; then
    echo "NSG already exists."
else
    echo "Creating NSG..."
    az network nsg create \
        -g ${RESOURCE_GROUP} \
        -n ${NSG_NAME}

    # Add SSH rule
    az network nsg rule create \
        -g ${RESOURCE_GROUP} \
        --nsg-name ${NSG_NAME} \
        -n allow-ssh \
        --priority 1000 \
        --protocol Tcp \
        --destination-port-range 22 \
        --access Allow
fi

# Create NIC
NIC_NAME=${VM_NAME}-nic
if az network nic show -g ${RESOURCE_GROUP} -n ${NIC_NAME} &>/dev/null; then
    echo "NIC already exists."
else
    echo "Creating NIC..."
    az network nic create \
        -g ${RESOURCE_GROUP} \
        -n ${NIC_NAME} \
        --vnet-name ${VNET_NAME} \
        --subnet default \
        --network-security-group ${NSG_NAME} \
        --public-ip-address ${IP_NAME}
fi

# Create VM
if az vm show -g ${RESOURCE_GROUP} -n ${VM_NAME} &>/dev/null; then
    echo "VM already exists."
else
    echo "Creating VM..."
    az vm create \
        -g ${RESOURCE_GROUP} \
        -n ${VM_NAME} \
        --image Ubuntu2204 \
        --size ${VM_SIZE} \
        --admin-username azureuser \
        --generate-ssh-keys \
        --nics ${NIC_NAME}
fi

# Show public IP
echo "VM public IP:"
az network public-ip show -g ${RESOURCE_GROUP} -n ${IP_NAME} --query ipAddress -o tsv
