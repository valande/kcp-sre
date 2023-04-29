# Práctica Pablo Cazallas - Liberando productos

## A. Creación de helm chart para desplegar la aplicación en Kubernetes

Pasos:  

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
