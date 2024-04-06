# eidas-node demo in kubernetes

For this demo, we use the following
- local kubernetes cluster , example `kind`
- local docker registry, connected to the local cluster
- ingress-nginx installed in the cluster
- eidas-node helm chart from https://mvn.ecsec.de/repository/helm-public
- a magic dns entry http://eidas-node.127.0.0.1.nip.io pointing to 127.0.0.1

# steps

- build docker image eidas-node-mock:tomcat-latest
```
# in git-root-dir
make build-tomcat
```

- import image in local registry (demo)
```
docker push localhost:5001/eidas-node-mock:tomcat-latest
```

- Create eidas namespace
```
kubectl create ns eidas
```

- In kubernetes directory, import eidas-node demo config file from the `config` directory as configmap
```
# show imported files
cat kustomization.yaml
# show generated config map
kubectl kustomize
# import configmap in eidas namespace
kubectl kustomize | kubectl apply -n eidas -f - -n eidas
```

- Show the helm value file: `eidas-values.yaml`. By default it works as is.

- add helm repo
```
helm repo add ecsec https://mvn.ecsec.de/repository/helm-public/
```

- Install eidas-node helm chart with config values
```
helm upgrade --install eidas-node ecsec/eidas-node --version 2.6.0-1 -n eidas -f eidas-values.yaml --create-namespace
```

- show object in kubernetes
```
kubectl get events -n eidas  --sort-by='.lastTimestamp'
kubectl logs -n eidas deployments/eidas-node
kubectl get pod -n eidas
kubectl get all -n eidas
```

- Wait few seconds, that the pod start with all java components

- Then Try the demo. Connect with your browser to http://eidas-node.127.0.0.1.nip.io/SP/ and follow steps
  - Choose `CA` for both SP and citizen country
  - Later: Enter the user credentials. `xavi` as *Username* and `creus` as *Password
  - At the end of all steps, you must see  "Login Succeeded"


- destroy eidas resources
```
helm uninstall -n eidas eidas-node
```
