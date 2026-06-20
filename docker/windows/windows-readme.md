# vlmcsd — KMS activation server

Local KMS (Key Management Service) server for **volume activation** of Windows and
Microsoft Office on the internal network. It does not host Windows; it answers KMS
activation requests from clients.

> Use only with licenses that permit KMS volume activation (e.g. Windows/Office
> Volume License editions). It does not bypass licensing.

## Port

| Port | Purpose            |
| ---- | ------------------ |
| 1688 | KMS protocol (TCP) |

## Setup

```bash
docker compose up -d
```

## Activate a client against this server

On the Windows client (admin shell), point it at this server and activate:

```powershell
# Windows (example)
slmgr /skms <server-IP>:1688
slmgr /ato
```

```bash
# Office (run from the Office "OfficeXX" install directory)
cscript ospp.vbs /sethst:<server-IP>
cscript ospp.vbs /act
```

## Notes

- The directory is named `windows/` for the use case, but the service image is `vlmcsd`.
- Clients must re-activate periodically; KMS activation is valid for 180 days and renews
  automatically while the server is reachable.
