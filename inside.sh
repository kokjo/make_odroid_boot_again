#!/bin/bash

apt-get install -qy u-boot-tools linux-headers-armmp linux-image-armmp sudo ssh vim
mkimage -A arm -O linux -T ramdisk -C none -a 0 -e 0 -n uInitrd -d /initrd.img /boot/uInitrd
mkimage -A arm -C none -T script -d /boot/boot.ini /boot/boot.scr
cp /vmlinuz /boot/zImage
cp /usr/lib/linux-image-4.9.0-4-armmp/exynos4412-odroidu3.dtb /boot

useradd jonas -m -G sudo -s /bin/bash

mkdir -p /home/jonas/.ssh
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBcKie1dw995RML+hierA8MISqXbTxpgv+4jq32cC5b1 jonas@x250" > /home/jonas/.ssh/authorized_keys
chown jonas: -R /home/jonas/.ssh
chmod og-rwx -R /home/jonas/.ssh

systemctl enable serial-getty@ttySAC1.service

rm /inside.sh
