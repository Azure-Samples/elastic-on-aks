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
    SERVER_PUBLIC_IP=$(kubectl get service server-es-http -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
    if [ -n "$SERVER_PUBLIC_IP" ]; then
        echo "Ingress IP is ready: $SERVER_PUBLIC_IP"
        break
    fi
done
export SERVER_PUBLIC_IP
echo "Server public IP: ${SERVER_PUBLIC_IP}"

SERVER_PASSWORD=$(kubectl get secret server-es-elastic-user -o=jsonpath='{.data.elastic}' | base64 --decode)
export SERVER_PASSWORD
