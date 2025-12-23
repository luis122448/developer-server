# Nextcloud External Service (NAS)

Esta configuración permite exponer una instancia de Nextcloud que se ejecuta **fuera** del clúster de Kubernetes (en un contenedor Docker en la misma red local) a través del Ingress Controller del clúster.

## Objetivo

Redirigir el tráfico externo seguro hacia una IP local insegura:
`Internet (HTTPS) -> Ingress (nas.bbg.pe) -> Service (Cluster) -> Docker Host (192.168.100.161:8002)`

## Archivos

1.  **`01-service-endpoints.yaml`**:
    *   **Service**: Crea un servicio abstracto (`nextcloud-external-svc`) en el puerto 80 dentro del clúster. No tiene selectores de Pods.
    *   **Endpoints**: Define manualmente la dirección IP de destino (`192.168.100.161`) y el puerto (`8002`). Esto conecta el servicio con el contenedor externo.

2.  **`02-ingress.yaml`**:
    *   Configura el Ingress de Nginx para escuchar en `nas.bbg.pe`.
    *   Gestiona la terminación SSL usando `cert-manager`.
    *   Redirige el tráfico al servicio `nextcloud-external-svc`.
    *   Incluye anotaciones para aumentar el tamaño de subida de archivos (`proxy-body-size: 10g`), esencial para un NAS.

## Despliegue

Para aplicar esta configuración en el clúster:

```bash
kubectl apply -f kubernetes/external/nas-nextcloud/
```

## Verificación

1.  **Verificar Endpoints**:
    Asegúrate de que el servicio tenga asignada la IP externa correctamente.

```bash
kubectl get endpoints nextcloud-external-svc
# Deberías ver: 192.168.100.161:8002 en la columna ENDPOINTS
```

2.  **Verificar Ingress**:

```bash
kubectl get ingress nextcloud-external-ingress
```

## Notas Importantes

*   **Red**: El clúster de Kubernetes (específicamente los nodos donde corren los pods del Ingress Controller) debe tener visibilidad de red hacia la IP `192.168.100.161`.
*   **Certificados**: Se asume que existe un ClusterIssuer llamado `letsencrypt-prod`. Si usas otro nombre o método, edita la anotación en `02-ingress.yaml`.