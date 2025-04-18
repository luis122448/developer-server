# Installation Kubernetes in Rasberry PI and N100 Intel

## Disable Swap

```bash
    ansible-playbook -i ./config/inventory.ini ./loadbalancer/ha_proxy.yml --ask-become-pass
```