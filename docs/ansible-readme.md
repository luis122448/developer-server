# Ansible Installation Guide

This guide provides instructions on how to install `ansible` on Arch Linux and Ubuntu/Debian-based systems.

## Installation

### Arch Linux
To install `ansible` on Arch Linux, use the `pacman` package manager:

```bash
sudo pacman -S ansible
```

### Ubuntu / Debian
For Ubuntu, it is recommended to use the official PPA to ensure you have the latest version:

```bash
sudo apt update
sudo apt install software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install ansible
```

## Verification
After installation, verify that Ansible is installed correctly by checking the version:

```bash
ansible --version
```

## Basic Configuration
Ansible configuration files are typically located in `/etc/ansible/ansible.cfg` or can be defined locally in your project directory as `ansible.cfg`. In this project, the configuration is located at `config/ansible.cfg`.
