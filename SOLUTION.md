# Práctica Pablo Cazallas - Liberando productos

## A. Nuevo endpoint + Unit tests

![snaps/new_endpoint_code.png](./snaps/new_endpoint_code.png)
![snaps/test_new_endpoint_code.png](./snaps/test_new_endpoint_code.png)
![snaps/new_endpoint_curl.png](./snaps/new_endpoint_curl.png)
![snaps/new_endpoint_browser.png](./snaps/new_endpoint_browser.png)
![snaps/unit_test_passing.png](./snaps/unit_test_passing.png)
![snaps/unit_test_cov_passing.png](./snaps/unit_test_cov_passing.png)  


## B. Creación de helm chart para desplegar la aplicación en Kubernetes

1. Construir la imagen del contenedor.  
    ```
    # Manualmente:
    $ docker build -t <imgname>:<imgver> .

    # Mediante el comando 'make' y las definiciones del Makefile:
    $ make docker-build
    ```  

2. Etiquetar y publicar la imagen creada en un registry online.  
    Publicar en Github Packages:
    ```
    # Manualmente:
    $ docker tag <imgname> ghcr.io/<githubuser>/<imgname>:<imgver>
    $ docker push ghcr.io/<githubuser>/<imgname>:<imgver>
    ```
    Publicar en Docker Hub:
    ```
    $ docker tag <imgname> [docker.io/]<dockerhubuser>/<imgname>:<imgver>
    $ docker push [docker.io/]<dockerhubuser>/<imgname>:<imgver>
    ```  
    Publicar en ambos registros (mediante el comando `make` y las definiciones del Makefile):
    ```
    $ make publish
    ```

3. Arrancar minikube con un nuevo perfil `practica-sre`.  
    ```
    $ minikube start --memory=4096 --addons="metrics-server,default-storageclass,storage-provisioner" -p practica-sre
    ```

4. Crear un helm chart para desplegar la aplicación en kubernetes (con minikube).  
    ```
    $ helm create simpleserver
    ```

    Modificar los atributos del fichero `values.yaml`.  
    ```
    repository: valande/sre-ss
    ...

    service:
      type: ClusterIP
      port: 8081
    ...
    ```

    Modificar el atributo `appVersion` del fichero `Chart.yaml`.  

    Desplegar el chart:
    ```
    $ helm install <release_name> simpleserver
    ```

    Seguir las instrucciones de las NOTES:
    ```
    NAME: ss-02
    LAST DEPLOYED: Wed Apr 26 13:58:23 2023
    NAMESPACE: default
    STATUS: deployed
    REVISION: 1
    NOTES:
        1. Get the application URL by running these commands:
        export POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=simpleserver,app.kubernetes.io/instance=ss-02" -o jsonpath="{.items[0].metadata.name}")
        export CONTAINER_PORT=$(kubectl get pod --namespace default $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
        echo "Visit http://127.0.0.1:8080 to use your application"
        kubectl --namespace default port-forward $POD_NAME 8080:$CONTAINER_PORT
    ```  

## C. Creación de pipelines CI/CD

Se ha utilizado Github Actions, con la configuración establecida en los ficheros yaml del directorio `.github/workflows`.  

Es necesario crear un token personal con los permisos de manejo de `packages`:  

![snaps/actions_ghcr_token_permissions.png](./snaps/actions_ghcr_token_permissions.png)


Es necesario definir los secretos para poder hacer login frente a los registros de contenedores. Esto se define en la sección de `Actions` de los `Settings` del repo:  

![snaps/actions_secrets.png](./snaps/actions_secrets.png)  


Ejecución de pipelines puede verse en el apartado `Actions` del proyecto:  

![snaps/actions_tests.png](./snaps/actions_tests.png)
![snaps/actions_release.png](./snaps/actions_release.png)  


Los artefactos generados se publican tanto en ghcr.io como en el hub de docker:  

![snaps/packages.png](./snaps/packages.png)
![snaps/dockerhub.png](./snaps/dockerhub.png)  


## D. Monitorización y alertas - Prometheus, Grafana

1. Añadir fichero values.yaml correspondiente al stack `kube-prometheus-stack`, para su instalación vía Helm.
2. Definir la sección `metrics` en el fichero `values.yaml` del chart `simpleserver`.
3. Configurar `apiUrl` (Webhook de Slack, mediante app "Incoming WebHooks") y `channel` (Channel de Slack) en la sección `alertmanager` del fichero `values.yaml` correspondiente al stack `kube-prometheus`.
4. Definir las alertas de monitorización en la sección `additionalPrometheusRulesMap` del mismo fichero.
5. Instalar el stack de monitorización:
    ```
    $ helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    $ helm repo update
    ...

    $ helm -n monitoring upgrade --install prometheus prometheus-community/kube-prometheus-stack \
        -f kube-prometheus/values.yaml --create-namespace --wait --version 34.1.1
    ``` 
6. Instalar el chart `simpleserver`:
    ```
    $ helm -n simpleserver upgrade ss-sre --wait --install --create-namespace simpleserver
    ```
7. Hacer algunos `port-forward` para exponer los servicios creados:
    ```
    $ kubectl -n monitoring port-forward svc/prometheus-grafana 3000:http-web
    ```
    ![snaps/grafana_home.png](./snaps/grafana_home.png)
    ![snaps/grafana_dashboard.png](./snaps/grafana_dashboard.png)
    ![snaps/grafana_dashboard_mem.png](./snaps/grafana_dashboard_mem.png)

    ```
    $ kubectl -n monitoring port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090
    ```
    ![snaps/grafana_home.png](./snaps/prometheus_alerts.png)
    
    ```
    $ kubectl -n simpleserver port-forward svc/ss-sre-simpleserver 8080:8081
    ```
    ![snaps/grafana_home.png](./snaps/endpoint_sre.png)
    
    Además, si se hace `port-forward` sobre el pod para el puerto 8000:8000, se pueden observar las métricas de Prometheus:
    ```
    $ kubectl -n simpleserver port-forward <pod> 8000:8000
    ```
    ![snaps/grafana_home.png](./snaps/prometheus_raw.png)

