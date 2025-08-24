# LVM Configuration for Consolidating Disks

This guide provides a step-by-step walkthrough for using Logical Volume Management (LVM) to consolidate multiple physical disks into a single, large logical volume. This is particularly useful for creating a large storage pool for applications, such as a Kubernetes NFS server.

---

## 1. Prerequisites

Ensure you have the LVM userspace tools installed. If not, install them using your distribution's package manager.

```bash
sudo apt update
sudo apt install lvm2
```

---

## 2. Configuration Steps

Follow these steps to create a logical volume that spans multiple disks.

### 2.1. Identify Disks

First, identify the disks you want to consolidate. Use `lsblk` to list the available block devices.

```bash
lsblk
```

Look for the disks that you want to use, for example, `/dev/nvme0n1`, `/dev/nvme1n1`, etc.

### 2.2. Prepare Disks (Optional)

If the disks have been used before, they might have existing partition tables or filesystem signatures. This can cause `pvcreate` to fail with an error like `Cannot use /dev/nvme2n1: device is partitioned`.

To avoid this, you can wipe the signatures from the disks.

**Warning**: This command will destroy any data on the specified disks. Make sure you have selected the correct disks.

```bash
sudo wipefs -a /dev/nvme0n1
sudo wipefs -a /dev/nvme1n1
sudo wipefs -a /dev/nvme2n1
sudo wipefs -a /dev/nvme3n1
```

### 2.3. Create Physical Volumes (PVs)

Next, mark each disk as a physical volume for LVM. This prepares the disks for use in a volume group.

```bash
sudo pvcreate /dev/nvme0n1 /dev/nvme1n1 /dev/nvme2n1 /dev/nvme3n1
```

You can verify the creation of the physical volumes with `pvs` or `pvdisplay`.

```bash
sudo pvs
```

### 2.4. Create a Volume Group (VG)

Now, create a volume group to pool the physical volumes together. Give it a descriptive name, like `datavg`.

```bash
sudo vgcreate datavg /dev/nvme0n1 /dev/nvme1n1 /dev/nvme2n1 /dev/nvme3n1
```

You can verify the volume group's creation with `vgs` or `vgdisplay`.

```bash
sudo vgs
```

### 2.5. Create a Logical Volume (LV)

With the volume group created, you can now create a logical volume. The following command creates a logical volume named `datalv` that uses 100% of the available space in the `datavg` volume group.

```bash
sudo lvcreate -n datalv -l 100%FREE datavg
```

Verify the logical volume's creation with `lvs` or `lvdisplay`.

```bash
sudo lvs
```

### 2.6. Format the Logical Volume

Next, format the logical volume with a filesystem. `ext4` is a common choice.

```bash
sudo mkfs.ext4 /dev/datavg/datalv
```

### 2.7. Mount the Logical Volume

Finally, create a mount point and mount the logical volume. To make the mount persistent, add an entry to `/etc/fstab`.

1.  **Create a mount point**:

```bash
sudo mkdir /mnt/data
```

2.  **Mount the volume**:

```bash
sudo mount /dev/datavg/datalv /mnt/data
```

3.  **Add to `/etc/fstab` for persistence**:

```bash
sudo nano /etc/fstab
```

Add the following line to `/etc/fstab`:

```bash
/dev/datavg/datalv /mnt/data ext4 defaults,nofail 0 0
```

4. **Test and Mount**:

Before rebooting, it is crucial to test the `/etc/fstab` entry to prevent potential boot failures.
*This command mounts all filesystems listed in /etc/fstab that are not already mounted. If it runs without errors, your configuration is correct*.

```bash
sudo mount -a
```

After running the command, verify that the volume is mounted correctly:
      
```bash
df -h /mnt/data
```

---

## 3. Verification

After completing the steps, you can verify the final setup. The `lsblk` command should show the LVM structure.

```bash
luis122448@nas-001:~$ lsblk
NAME                      MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
mmcblk0                   179:0    0  58.2G  0 disk 
├─mmcblk0p1               179:1    0     1G  0 part /boot/efi
├─mmcblk0p2               179:2    0     2G  0 part /boot
└─mmcblk0p3               179:3    0  55.2G  0 part 
  └─ubuntu--vg-ubuntu--lv 252:1    0  27.6G  0 lvm  /
mmcblk0boot0              179:8    0     4M  1 disk 
mmcblk0boot1              179:16   0     4M  1 disk 
nvme0n1                   259:0    0 476.9G  0 disk 
└─datavg-datalv           252:0    0   1.9T  0 lvm  /mnt/data
nvme1n1                   259:1    0 476.9G  0 disk 
└─datavg-datalv           252:0    0   1.9T  0 lvm  /mnt/data
nvme3n1                   259:2    0 476.9G  0 disk 
└─datavg-datalv           252:0    0   1.9T  0 lvm  /mnt/data
nvme2n1                   259:3    0 476.9G  0 disk 
└─datavg-datalv           252:0    0   1.9T  0 lvm  /mnt/data
```

In this example, the four `nvme` disks are part of the `datavg-datalv` LVM structure, which is mounted at `/mnt/data`.
