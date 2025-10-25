# Despliegue de MinIO con Vault y Let's Encrypt

Este directorio contiene los manifiestos para desplegar MinIO en Kubernetes, utilizando Vault para la gestión de secretos y Let's Encrypt para la obtención de certificados TLS.

## Prerrequisitos

1.  **Kubernetes Cluster**: Un cluster funcional.
2.  **Ingress Controller**: Un Ingress Controller como NGINX instalado.
3.  **Cert-Manager**: Cert-Manager debe estar instalado y configurado con un `ClusterIssuer` (ej. `letsencrypt-prod`).
4.  **Vault**: Vault debe estar instalado y configurado para la integración con Kubernetes (auth method `kubernetes`).
5.  **StorageClass**: Una `StorageClass` llamada `nas-003` debe existir.

## 1. Configuración de Vault

Antes de desplegar MinIO, necesitas configurar Vault para que pueda proveer las credenciales de forma segura.

### a. Crear la Política (Policy)

Esta política permite leer el secreto de MinIO.

```bash
vault policy write minio-policy - <<EOF
path "secret/data/minio" {
  capabilities = ["read"]
}
EOF
```

### b. Crear el Rol de Autenticación de Kubernetes

Este rol vincula el `ServiceAccount` de Kubernetes (`minio-sa`) y la `namespace` con la política de Vault que creaste.

```bash
# Reemplaza 'default' si usas otro namespace
vault write auth/kubernetes/role/minio-app \
    bound_service_account_names=minio-sa \
    bound_service_account_namespaces=default \
    policies=minio-policy \
    ttl=24h
```

### c. Crear el Secreto en Vault

Guarda las credenciales que usará MinIO. Vault las inyectará en el pod.

```bash
# Puedes usar 'openssl rand -hex 16' para generar un usuario y contraseña seguros
vault kv put secret/minio username="admin" password="YOUR_STRONG_PASSWORD"
```

**IMPORTANTE**: Reemplaza `YOUR_STRONG_PASSWORD` con una contraseña segura.

## 2. Despliegue de MinIO

Una vez configurado Vault, puedes aplicar los manifiestos de Kubernetes.

```bash
kubectl apply -f .
```

Esto creará todos los recursos: `ServiceAccount`, `PersistentVolumeClaim`, `Deployment`, `Service` e `Ingress`.

## 3. Acceso a MinIO

-   **Consola Web**: Una vez que el Ingress esté activo y el certificado TLS se haya emitido, podrás acceder a la consola de MinIO en `https://minio.lcalvo.com`.
-   **Credenciales**: Las credenciales para iniciar sesión son las que guardaste en Vault (`admin` / `YOUR_STRONG_PASSWORD`).

## 4. Exportar/Verificar Credenciales

Si necesitas verificar las credenciales que están siendo usadas por el pod, puedes hacerlo de la siguiente manera:

1.  **Encuentra el pod de MinIO**:
    ```bash
    kubectl get pods -l app=minio
    ```

2.  **Accede al pod y revisa el secreto inyectado**:
    El agente de Vault inyecta las credenciales en `/vault/secrets/credentials.txt`.

    ```bash
    # Reemplaza <minio-pod-name> con el nombre real del pod
    kubectl exec -it <minio-pod-name> -n minio-production -- cat /vault/secrets/credentials.txt
    ```

    Verás la salida con `export MINIO_ROOT_USER="..."` y `export MINIO_ROOT_PASSWORD="..."`.
