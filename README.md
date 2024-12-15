## Reserved and Statics IPs, for Developer Server

## Verify Hostname

```bash
    hostnamectl
```

## Change Hostname and Reboot

```bash
    sudo nano /etc/hostname
    sudo nano /etc/hosts
    sudo reboot
```


## 1.- Test Connection

```bash
    ping google.com
```

## 2.- Get MAC Address

```bash
    ip link show eth0
``` 

## 3.-

- For Rasberry PIs

| Server | Ip | MAC Address | Reserved? |
| ------------ | --------------- | ----------------- | --- | 
| rasberry-001 | 192.168.100.101 | b8:27:eb:12:34:56 | [ ] |
| rasberry-002 | 192.168.100.102 | ----------------- | --- |
| rasberry-003 | 192.168.100.103 | ----------------- | --- |
| rasberry-004 | 192.168.100.104 | ----------------- | --- |
| rasberry-005 | 192.168.100.105 | ----------------- | --- |

- For Orange PIs

| Server | Ip | MAC Address | Reserved? |
| ---------- | --------------- | ----------------- | --- |
| orange-001 | 192.168.100.121 | ----------------- | --- |
| orange-002 | 192.168.100.122 | ----------------- | --- |

- For Intel N100 PCs

| Server | Ip | MAC Address | Reserved? |
| -------- | --------------- | ----------------- | --- |
| n100-001 | 192.168.100.141 | ----------------- | --- |
| n100-002 | 192.168.100.142 | ----------------- | --- |

- For Developer Servers

| Server | Ip | MAC Address | Reserved? |
| ------- | --------------- | ----------------- | --- |
| dev-001 | 192.168.100.161 | ----------------- | --- |
| dev-002 | 192.168.100.162 | ----------------- | --- |