#!/bin/bash
SCRIPT=$(readlink -f $0)
if [ "$(id -u)" != "0" ] ;
then
    sudo $SCRIPT "$@"
    exit 0
fi;

DISK=/dev/mmcblk0

dd if=/dev/zero of=${DISK} bs=1M count=1
(fdisk -w always -W always ${DISK} || true) <<EOF
o
n
p
1
2048
+60M

n
p
2



t
2
83

d
1

n
p
1
4096


t
1
6

w
EOF

docker build -t build-uboot build-uboot && docker run --rm build-uboot cat /u-boot/u-boot.bin > u-boot.bin
dd iflag=dsync oflag=dsync if=./E4412_S.bl1.HardKernel.bin of=$DISK bs=512 seek=1
dd iflag=dsync oflag=dsync if=./bl2.signed.bin of=$DISK bs=512 seek=31
dd iflag=dsync oflag=dsync if=./u-boot.bin of=$DISK bs=512 seek=63
dd iflag=dsync oflag=dsync if=./E4412_S.tzsw.signed.bin of=$DISK bs=512 seek=2111

BOOT=${DISK}p1
ROOT=${DISK}p2
dd if=/dev/urandom of=${BOOT} bs=1M count=1
dd if=/dev/urandom of=${ROOT} bs=1M count=1

mkfs.vfat ${BOOT}
mkfs.ext4 -O ^metadata_csum,^sparse_super2 ${ROOT}

rmdir target
mkdir -p target
mount ${ROOT} target
mkdir -p target/boot
mount ${BOOT} target/boot

qemu-debootstrap --arch armhf stretch target

BOOT_UUID=$(blkid -s UUID -o value ${BOOT})
ROOT_UUID=$(blkid -s UUID -o value ${ROOT})

cat > target/etc/fstab << EOF
UUID=${ROOT_UUID} / ext4 discard,noatime,errors=remount-ro 0 1
UUID=${BOOT_UUID} /boot vfat discard,noatime 0 2
EOF

cat > target/boot/boot.ini << EOF
setenv kernel_args "setenv bootargs root=/dev/disk/by-uuid/${ROOT_UUID} rootwait ttySAC1,115200n8";
EOF

cat > target/etc/network/interfaces.d/eth0 <<EOF
allow-hotplug eth0
iface eth0 inet dhcp
EOF

echo "odroid" > target/etc/hostname

mount -t proc proc target/proc
mount -o bind /dev target/dev
mount -o bind /dev/pts target/dev/pts || true
mount -o bind /dev/shm target/dev/shm || true

cp inside.sh target && chroot target /bin/bash /inside.sh

umount target/dev/pts
umount target/dev/shm
umount target/dev/
umount target/proc
umount target/boot
umount target
