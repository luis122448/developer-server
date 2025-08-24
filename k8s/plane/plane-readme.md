# Plane Application Deployment on Kubernetes

This document provides a step-by-step guide to deploying the Plane application on a Kubernetes cluster.

## Prerequisites

* A running Kubernetes cluster.
* `kubectl` configured to interact with your cluster.
* A running StorageClass, in this case the name is `nas-003`

## Deployment Steps

The deployment is divided into several components:

1.  **Namespace:** Creates a dedicated namespace for the Plane application.
2.  **Secrets:** Manages sensitive data like database credentials and secret keys.
3.  **Database:** Deploys a PostgreSQL database using a StatefulSet.
4.  **Cache:** Deploys a Redis cache.
5.  **Backend:** Deploys the Plane backend application.
6.  **Worker:** Deploys a Celery worker for background tasks.
7.  **Realtime:** Deploys a realtime component for live updates.
8.  **Frontend:** Deploys the Plane frontend application.
9.  **Ingress:** Exposes the frontend service to the internet.

### 1. Create the Namespace

First, create the namespace for the application:

```bash
kubectl apply -f k8s/plane/namespace.yml
```

### 2. Create the Secrets

For detailed instructions on how to create and configure the secrets, please refer to the [secret documentation](secret/plane-secret-readme.md).

Once you have configured the secrets, apply the manifest:

```bash
kubectl apply -f k8s/plane/secret/secret.yml
```

### 3. Deploy the Database

The PostgreSQL database is deployed as a StatefulSet, which ensures that the data is persisted across pod restarts.

```bash
kubectl apply -f k8s/plane/database/postgres-statefulset.yml
kubectl apply -f k8s/plane/database/postgres-service.yml
```

### 4. Deploy the Cache

The Redis cache is used for caching frequently accessed data.

```bash
kubectl apply -f k8s/plane/cache/redis-deployment.yml
kubectl apply -f k8s/plane/cache/redis-service.yml
```

### 5. Deploy the Backend

The backend application is the core of the Plane application.

```bash
kubectl apply -f k8s/plane/backend/backend-deployment.yml
kubectl apply -f k8s/plane/backend/backend-service.yml
```

### 6. Deploy the Worker

The Celery worker is used for running background tasks.

```bash
kubectl apply -f k8s/plane/backend/worker-deployment.yml
```

### 7. Deploy the Realtime Component

The realtime component is responsible for providing live updates to the frontend.

```bash
kubectl apply -f k8s/plane/realtime/realtime-deployment.yml
kubectl apply -f k8s/plane/realtime/realtime-service.yml
```

### 8. Deploy the Frontend

The frontend application is the user interface of the Plane application.

```bash
kubectl apply -f k8s/plane/frontend/frontend-deployment.yml
kubectl apply -f k8s/plane/frontend/frontend-service.yml
```

### 9. Expose the Application with Ingress

The Ingress resource exposes the frontend service to the internet. You will need to replace `plane.midominio.com` with your own domain name.

```bash
kubectl apply -f k8s/plane/ingress/ingress.yml
```

## Verification

After deploying all the components, you can verify that everything is running correctly by checking the status of the pods in the `plane` namespace:

```bash
kubectl get pods -n plane
```

You should see all the pods in the `Running` state. You can also check the logs of each pod to ensure that there are no errors.

Once all the pods are running, you should be able to access the Plane application at the domain name you configured in the Ingress resource.