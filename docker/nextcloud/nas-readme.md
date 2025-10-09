# NAS Disk Preparation and Automatic Mounting Guide

This guide covers the essential steps to prepare, format, and configure automatic mounting for new or existing disks intended for use in a Network Attached Storage (NAS) on a Linux system. It focuses on using `parted` for GPT partitioning and `fstab` for automatic mounting.

**Based on the provided context, this guide assumes you are working with two 8TB disks identified as `/dev/sda` and `/dev/sdb`.**

---
## Prerequisites

* A Linux system (like Ubuntu, Debian, etc.).
* `sudo` access.
* Tools like `lsblk`, `parted`, `mkfs`, `blkid`, and a text editor (`nano` is used in the examples). These are usually available by default or easily installed via your distribution's package manager.

## ⚠️ CRITICAL WARNING: Data Loss

**The following steps will permanently erase ALL data on the disks (`/dev/sda` and `/dev/sdb`). Ensure you have backed up any important data before proceeding.**

---
## 1. Identify Your Disks

First, verify the device names of your disks. Based on your text, they appear to be `/dev/sda` and `/dev/sdb`.

```bash
sudo lsblk
```

Confirm that `/dev/sda` and `/dev/sdb` correspond to the 8TB disks you intend to prepare.

---
## 2. Partitioning the Disks with parted
We will use parted to create a new GPT partition table and a single partition that spans almost the entire disk. GPT (GUID Partition Table) is recommended and necessary for disks larger than 2TB.

It is highly recommended to have a single partition per disk for simplicity and maximum space utilization in a NAS context.

Prepare `/dev/sda`
Open `parted` for the first disk:

```bash
sudo parted /dev/sda
```

Inside the `parted` prompt:

1.  **Set Partition Table Type to GPT**: This will erase the existing partition table and all data.

```bash
(parted) mktable gpt
```

You will be asked to confirm the data loss. Type `Yes` and press Enter.

```bash
Warning: The existing disk label on /dev/sda will be destroyed and all data on this disk will be lost. Do you want to continue?
Yes/No? Yes
```

2.  **Create the Primary Partition**: Create a single primary partition starting at 1MiB (for proper alignment) and extending to 100% of the disk.

```bash
(parted) mkpart primary 1MiB 100%
```

You don't need to specify a filesystem type here; we'll do that later.

3.  **Quit parted**:

```bash
(parted) quit
```

## 3. Verify New Partitions

Run `lsblk` again to see the new partition structure. You should now see one partition (likely `sda1` and `sdb1`) under each disk.

```bash
sudo lsblk
```
Expected output (structure):

```bash
sda           8:0    0   7.3T  0 disk
└─sda1        8:1    0   7.3T  0 part
sdb           8:16   0   7.3T  0 disk
└─sdb1        8:17   0   7.3T  0 part
```

## 4. Formatting the Partitions

Now, we need to create a filesystem on the new partitions (`/dev/sda1` and `/dev/sdb1`). ext4 and `xfs` are common and robust choices for Linux data volumes. `xfs` is often recommended for very large filesystems.

Choose one of the following options:

Option A: Format with ext4

```bash
sudo mkfs.ext4 /dev/sda1
sudo mkfs.ext4 /dev/sdb1
```

Option B: Format with xfs

```bash
sudo mkfs.xfs /dev/sda1
sudo mkfs.xfs /dev/sdb1
```

This formatting process can take a significant amount of time for 8TB disks.

## 5. Configuring Automatic Mounting with `/etc/fstab`

To ensure your disks are available every time the system boots, we will configure automatic mounting using `/etc/fstab`. Using the unique identifier (UUID) for each partition is crucial, as device names like `/dev/sda1` can change.

5.1. Get Partition UUIDs
Use the blkid command to find the UUIDs of your newly formatted partitions:

```bash
sudo blkid /dev/sda1 /dev/sdb1
```

Note down the `UUID` and `TYPE` for both `/dev/sda1` and `/dev/sdb1`. The output will look similar to this (UUIDs will be different):

```bash
/dev/sda1: UUID="YOUR_UUID_FOR_SDA1" TYPE="ext4" PARTUUID="..."
/dev/sdb1: UUID="YOUR_UUID_FOR_SDB1" TYPE="ext4" PARTUUID="..."
```

5.2. Create Mount Points
Create directories where your partitions will be mounted. These are the "entry points" for accessing the disk data.

```bash
sudo mkdir /mnt/nas_files
sudo mkdir /mnt/torrents
```

You can choose different names and locations for these directories if you prefer (e.g., `/data/disk1`, `/srv/nas`).

5.3. Edit `/etc/fstab`

Open the `/etc/fstab` file using a text editor (like nano):

```bash
sudo nano /etc/fstab
```

Add the following lines to the end of the file. Do not modify or delete existing lines unless you are sure what you are doing.

Replace YOUR_UUID_FOR_SDA1 and YOUR_UUID_FOR_SDB1 with the actual UUIDs you obtained with blkid.
Replace /mnt/nas_files and /mnt/torrents with the actual mount point directories you created.
Replace <filesystem_type> with ext4 or xfs depending on which you used during formatting.

Fragmento de código

```bash
# Line for the NAS files disk (sda1)
UUID=YOUR_UUID_FOR_SDA1 /mnt/nas_files <filesystem_type> defaults,nofail 0 0

# Line for the torrents disk (sdb1)
UUID=YOUR_UUID_FOR_SDB1 /mnt/torrents <filesystem_type> defaults,nofail 0 0
```

Explanation of the fields:

UUID=...: The unique identifier of the partition.
/mnt/...: The mount point (directory where the partition is attached).
<filesystem_type>: The type of filesystem (e.g., ext4, xfs).
defaults: A set of common mount options (rw, suid, dev, exec, auto, nouser, async).
nofail: Important. This option tells the system to continue booting even if this specific mount fails (e.g., if the disk is temporarily unavailable).
0: (dump) Controls which filesystems are backed up by the dump utility. 0 disables it.
0: (fsck order) Controls the order in which fsck checks filesystems on boot. 0 disables the check for non-root filesystems, which is common for data partitions.
Save the file (in nano: Ctrl + O, then Enter) and exit the editor (Ctrl + X).

(Example excerpt from fstab based on provided text, showing the added lines)

Fragmento de código

# /swap.img     none    swap    sw      0       0
#UUID=dfaa1904-1a13-4e2d-962f-4fb0102607a7 /mnt/raid ext4 defaults 0 0
UUID=7cd51ec4-40c8-4e44-bcdd-91de6d2ecb2d /mnt/nas ext4 defaults,nofail 0 0
UUID=6b40dd84-1203-4648-b719-0aef8b2f5d9e /mnt/torrents ext4 defaults,nofail 0 0
Note: The example in the source text uses /mnt/nas and /mnt/torrents as mount points, while the instruction above used /mnt/nas_files and /mnt/torrents. Ensure consistency between your mkdir and fstab entries.

5.4. (Optional) Set Permissions
By default, the mount point directories might be owned by root. You may want to adjust permissions so your regular user can write to the disks. Replace $USER with your actual username if needed.

Bash

sudo chown -R $USER:$USER /mnt/nas_files
sudo chown -R $USER:$USER /mnt/torrents
5.5. Test Mounting Without Rebooting
You can test if your /etc/fstab entries are correct by attempting to mount all unmounted filesystems listed in it:

Bash

sudo mount -a
If this command runs without errors, your fstab entries are likely correct. If there are errors, double-check the lines you added for typos (especially UUIDs, mount points, and filesystem types).

5.6. Verify Correct Mounting
Check lsblk or the mount command to confirm the partitions are mounted at their specified points:

Bash

sudo lsblk
# Or
mount | grep sda1
mount | grep sdb1
You should see output indicating that /dev/sda1 is mounted on /mnt/nas_files and /dev/sdb1 on /mnt/torrents.

Conclusion
Your disks /dev/sda and /dev/sdb should now be partitioned, formatted, and configured to mount automatically at boot to their respective mount points (/mnt/nas_files and /mnt/torrents or whichever you chose). You are now ready to configure your NAS software or services to use these directories for storage.