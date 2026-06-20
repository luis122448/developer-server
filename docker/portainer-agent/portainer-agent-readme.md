# Portainer Agent — multi-host inventory

Deploy an **agent** on each standalone VM so the **central Portainer**
(`docker/portainer/`) can show, in a single web UI, what runs on each machine:
containers, images, volumes, networks and logs.

> Purpose: **inventory and visibility**. You keep deploying services manually on each
> VM; this only gives you a central view.

## Architecture

```
              Portainer UI (central server, port 9000)
                          │  connects to each agent :9001
        ┌─────────────┬───┴─────────┬─────────────┐
   agent@vm-1     agent@vm-2     agent@vm-3    agent@vm-4
   (exposes each VM's docker.sock on port 9001)
```

## Step 1 — Deploy the agent on EACH VM

Copy this directory (or just the `docker-compose.yml`) to each VM and start it:

```bash
docker compose up -d
```

Check that it is listening:

```bash
docker ps | grep portainer-agent
ss -tlnp | grep 9001
```

## Step 2 — Secure port 9001 (IMPORTANT)

⚠️ The agent grants **full control over that VM's Docker** to whoever reaches port 9001.
Do NOT leave it open to the whole network. Allow only the central server IP or the VPN subnet.

Using the UFW playbook already in this repo, or manually:

```bash
# Allow only the central server (replace <CENTRAL_IP>)
sudo ufw allow from <CENTRAL_IP> to any port 9001 proto tcp
# (optional) allow the whole VPN subnet
sudo ufw allow from 10.8.0.0/24 to any port 9001 proto tcp
sudo ufw deny 9001
```

## Step 3 — Register each VM in the central Portainer

In the central Portainer web UI:

1. **Environments** → **Add environment** → **Docker Standalone** → **Agent**.
2. **Environment address**: `<VM_IP>:9001` (local or VPN IP).
3. Name it (e.g. `vm-nas`, `vm-oracle`) → **Connect**.

Repeat for all 4 VMs. Done: each one shows up as an endpoint and you see its full
inventory from a single place.

## Notes

- **Version**: ideally pin the same version on the agent and on `portainer-ce`
  (this repo uses `:latest` for now; see the backlog in `AGENTS.md`).
- **Read-only**: Portainer CE has no per-endpoint granular roles (that is BE).
  Since you deploy by hand, use the UI only to look.
- **Optional hardening**: uncomment `AGENT_SECRET` in the compose and start the
  central Portainer with the same value to require authentication between the two.
- **VMs behind NAT / remote**: if one is not reachable from the central server, use an
  **Edge Agent** instead (the agent initiates the outbound connection). Not covered here
  because the VMs are on the local network/VPN.
