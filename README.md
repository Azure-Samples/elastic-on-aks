# Elastic on AKS

## Setup Server

### Create AKS cluster
```
bash ./scripts/aks.sh
```

### Create ElasticSearch Cluster
```
bash ./scripts/elk.sh
```

### Verify Server Setup
```
curl -u "elastic:$SERVER_PASSWORD" -k "https://$SERVER_PUBLIC_IP:9200"
{
  "name" : "server-es-server-2",
  "cluster_name" : "server",
  "cluster_uuid" : "Sq883dI0TdWRZXoNsbvbcg",
  "version" : {
    "number" : "8.17.3",
    "build_flavor" : "default",
    "build_type" : "docker",
    "build_hash" : "a091390de485bd4b127884f7e565c0cad59b10d2",
    "build_date" : "2025-02-28T10:07:26.089129809Z",
    "build_snapshot" : false,
    "lucene_version" : "9.12.0",
    "minimum_wire_compatibility_version" : "7.17.0",
    "minimum_index_compatibility_version" : "7.0.0"
  },
  "tagline" : "You Know, for Search"
}
```

## Setup Client

### Create VM
```
bash ./scripts/vm.sh
```

### Setup Rally
```
ssh $CLIENT_PUBLIC_IP 'bash -s' < ./scripts/rally.sh
```

### Run Benchmark
Login into client VM
```
ssh $CLIENT_PUBLIC_IP
```

List tracks and chanlleges
```
esrally list tracks
```

Run benchmark with track `elastic/logs` and chanllege `many-shards-quantitative`
```
esrally race --track=elastic/logs \
    --challenge=many-shards-quantitative \
    --target-hosts=https://$SERVER_PUBLIC_IP:9200 \
    --client-options="basic_auth_user:'elastic',basic_auth_password:'$SERVER_PASSWORD',verify_certs:false"
```