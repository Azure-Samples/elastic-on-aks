# Elastic on AKS

## Create AKS cluster
```
bash ./scripts/aks.sh
```

## Create ElasticSearch Cluster
```
bash ./scripts/elk.sh
```

## Create Client VM
```
bash ./scripts/vm.sh
```

## Setup Rally
```
ssh azueruser@VM_PUBLIC_IP
sudo apt update
sudo apt install python3-pip
pip3 install esrally
echo 'export PATH=$PATH:~/.local/bin' >> ~/.bashrc
source ~/.bashrc
esrally list tracks
```
