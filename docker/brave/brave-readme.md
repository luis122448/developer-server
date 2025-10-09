# Brave Browser en Docker (Kasm)

Esta configuración despliega una instancia del navegador Brave utilizando una imagen de Kasm, accesible a través de un navegador web.

Es una alternativa ligera a `webtop`, ya que solo ejecuta el navegador y no un entorno de escritorio completo.

## Puesta en marcha

1.  **Navega al directorio**:

```bash
cd /srv/developer-server/docker/brave
```

2.  **Levanta el servicio**:

```bash
docker compose up -d
```

## Acceso

Una vez que el contenedor esté en funcionamiento, puedes acceder a Brave desde tu navegador en la siguiente URL:

- **URL**: `http://<IP_DEL_SERVIDOR>:8005`

## Gestión del servicio

-   **Para detener el servicio**:

```bash
docker compose down
```

-   **Para ver los logs**:

```bash
docker compose logs -f
```
