# Docker Management Guide

This guide provides a simple approach to initializing servers and managing Docker containers using Ansible and basic Docker commands.

## 1. Server Initialization and Docker Setup

These steps use Ansible playbooks to configure the servers for SSH, open necessary firewall ports, and install Docker.

Make sure you have Ansible installed and your inventory file (`config/inventory.ini`) is correctly configured.

### - Configure SSH Key Authentication Login (Initial Setup)

This playbook sets up SSH key-based authentication on the target servers to allow for passwordless access, which is more secure and required for other playbooks.

```bash
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ./config/inventory.ini ./ansible/init-ssh.yml --ask-pass --ask-become-pass --limit $GROUP1
```

### - Install and Open Firewall Port (UFW)

This playbook opens a specific port on the server's firewall. Change the `port` variable as needed.

```bash
ansible-playbook -i ./config/inventory.ini ./ansible/ufw-open-port.yml --ask-become-pass -e "port=8080" --limit $GROUP1
```

### - Install Docker (Optional)

This playbook installs Docker Engine on the target servers.

```bash
ansible-playbook -i ./config/inventory.ini ./ansible/install-docker.yml --ask-become-pass --limit $GROUP1
```

### - (Recommended) Manage Docker as a non-root user

To avoid having to type `sudo` for every Docker command, add your user to the `docker` group. This is the recommended and most secure practice.

1.  **Create the `docker` group (if it doesn't already exist):**

```bash
sudo groupadd docker
```

2.  **Add your user to the `docker` group:**

```bash
sudo usermod -aG docker $USER
```

3.  **Apply the new group membership.** You will need to log out and log back in for your new group membership to take effect, or you can run the following command:

```bash
newgrp docker
```

## 2. Docker Container Management

Once Docker is installed, you can use these commands to manage your containers.

### - Supervising Running Applications

To see all running containers:

```bash
docker ps
```

To see all containers, including stopped ones:

```bash
docker ps -a
```

### - Checking Container Execution

To get detailed information about a specific container (e.g., its IP address):

```bash
docker inspect <container_name_or_id>
```

To view resource usage statistics (CPU, memory):

```bash
docker stats
```

### - Restarting Containers

To restart a running container:
```bash
docker restart <container_name_or_id>
```

### - Deleting or Cleaning Up Resources

To stop a running container:

```bash
docker stop <container_name_or_id>
```

To remove a stopped container:

```bash
docker rm <container_name_or_id>
```

To remove an image:

```bash
docker rmi <image_name_or_id>
```

To remove all unused containers, networks, and images:

```bash
docker system prune -a
```

### - Viewing Logs

To view the logs of a container in real-time:

```bash
docker logs -f <container_name_or_id>
```

To view the last 100 lines of logs:

```bash
docker logs --tail 100 <container_name_or_id>
```

### - Container Management Tools

For a more user-friendly way to manage containers, you can use a graphical interface.

- **[Portainer](./portainer/portainer-readme.md):** A web-based UI for Docker. See the guide for installation instructions.
- **lazydocker:** A terminal-based UI for Docker. Installation instructions can be found on its official website.
