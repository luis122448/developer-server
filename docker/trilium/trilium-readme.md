# Trilium Notes

Hierarchical knowledge base and note-taking application.

## How to start the service
```bash
docker compose up -d
```
The service will be available at port `8081`.

## Synchronization
- Access from any browser at `http://<YOUR-SERVER-IP>:8081`.
- You can install the desktop client on your PC and connect it to this server for bidirectional synchronization.

## Data
All information (notes, attached images, database) is stored in the `trilium_data` volume.
