echo "Installing CRDs"
kubectl create -f https://download.elastic.co/downloads/eck/2.16.1/crds.yaml

echo "Installing ECK operator"
kubectl apply -f https://download.elastic.co/downloads/eck/2.16.1/operator.yaml

echo "Checking ECK operator status"
kubectl get statefulset elastic-operator -n elastic-system

echo "Creating ElasticSearch cluster"
kubectl apply -f ./manifests/server.yml

while true; do
    echo "Waiting for ElasticSearch cluster to be healthy..."
    sleep 10
    health_status=$(kubectl get elasticsearch server -o=jsonpath='{.status.health}')
    if [ "$health_status" == "green" ]; then
        echo "ElasticSearch cluster is healthy"
        break
    fi
done

while true; do
    echo "Waiting for ingress IP to be ready..."
    sleep 10
    IP_ADDRESS=$(kubectl get service server-es-http -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
    if [ -n "$IP_ADDRESS" ]; then
        echo "Ingress IP is ready: $IP_ADDRESS"
        break
    fi
done

PASSWORD=$(kubectl get secret server-es-elastic-user -o=jsonpath='{.data.elastic}' | base64 --decode)
curl -u "elastic:$PASSWORD" -k "https://$IP_ADDRESS:9200"