# Installation Kubernetes in Rasberry PI and N100 Intel

## Disable Swap

```bash
    ansible-playbook -i ./config/inventory.ini ./proxy/ha_proxy.yml --ask-become-pass
```