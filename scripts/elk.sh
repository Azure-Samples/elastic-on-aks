helm repo add elastic https://helm.elastic.co
helm repo update

if helm ls -n elastic-system | grep -q elastic-operator; then
    echo "elastic-operator already exists"
else
    helm install elastic-operator elastic/eck-operator -n elastic-system --create-namespace
fi

kubectl apply -f ./manifests/elastic-cluster.yml