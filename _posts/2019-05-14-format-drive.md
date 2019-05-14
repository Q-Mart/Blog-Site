---
layout:     post
title:      Reformatting a bootable drive to be usable again using the Linux command line
date:       2019-05-14 09:00:00
categories: technology, linux
---

First, find the drive you want to format.
```bash
> lsblk
```
Note it down, it will from now on be referred to as  `/dev/sdX`, with it's partition referred to as
`/dev/sdXY`.

Unmount the partition
```bash
> umount /dev/sdXY
```

Wipe the device (this will take a while).
```bash
> dd if=/dev/zero of=/dev/sdX bs=1024
```

Recreate the partition table
```bash
> fdisk /dev/sdX
```

- Type `n` to create a new table
- Type `p` for partition table
- Type `1` to select the first partition
- Press enter twice to select the default first and last sectors
- Type `t` to change the partition type of partition 1
- Type `6` to change it to FAT16
- Type `w` to commit the changes to disk

Reformat it as FAT32 so it can be used on all operating systems.
```bash
> mkfs -t vfat /dev/sdXY
```
