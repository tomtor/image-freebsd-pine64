#!/bin/sh

FIRMWAREDIR=$PWD

# Set this based on how many CPUs you have
JFLAG=-j3

# Where to put you're build objects, you need write access
export MAKEOBJDIRPREFIX=${HOME}/obj

# Where to install to
DEST=${MAKEOBJDIRPREFIX}/pine64

set -e

cd /usr/src

make TARGET=arm64 -s ${JFLAG} buildworld NO_CLEAN=YES
make TARGET=arm64 -s ${JFLAG} buildkernel NO_CLEAN=YES KERNCONF=PINE64

mkdir -p ${DEST}/root
make TARGET=arm64 -s -DNO_ROOT installworld distribution installkernel \
     DESTDIR=${DEST}/root KERNCONF=PINE64

echo "/dev/mmcsd0s2a / ufs rw,noatime 0 0" > ${DEST}/root/etc/fstab
echo "./etc/fstab type=file uname=root gname=wheel mode=0644" >> ${DEST}/root/METALOG

echo "hostname=\"pine64\"" > ${DEST}/root/etc/rc.conf
echo "growfs_enable=\"YES\"" >> ${DEST}/root/etc/rc.conf
echo "./etc/rc.conf type=file uname=root gname=wheel mode=0644" >> ${DEST}/root/METALOG

touch ${DEST}/root/firstboot
echo "./firstboot type=file uname=root gname=wheel mode=0644" >> ${DEST}/root/METALOG

makefs -t ffs -B little -F ${DEST}/root/METALOG ${DEST}/ufs.img ${DEST}/root

mkimg -s bsd -p freebsd-ufs:=${DEST}/ufs.img -o ${DEST}/ufs_part.img

newfs_msdos -C 50m -F 16 ${DEST}/fat.img

cp ${DEST}/root/boot/dtb/pine64.dtb ${DEST}/pine64.dtb
mcopy -i ${DEST}/fat.img ${DEST}/pine64.dtb  ::
#mcopy -i ${DEST}/fat.img ${DEST}/root/boot/fbsdboot.bin ::
mcopy -i ${DEST}/fat.img ${DEST}/root/boot/kernel/kernel ::

#mcopy -i ${DEST}/fat.img ${FIRMWAREDIR}/u-boot-with-dtb.bin ::

boot0_position=8      # KiB
uboot_position=19096  # KiB
# part_position=20480   # KiB

mkimg -s mbr -p prep-boot:-'dd if=/dev/zero bs=1m count=20' -p fat16b:=${DEST}/fat.img -p freebsd:=${DEST}/ufs_part.img \
    -o ${DEST}/pine64.img

dd if=${FIRMWAREDIR}/boot0.bin conv=notrunc bs=1024 seek=$boot0_position of=${DEST}/pine64.img
dd if=${FIRMWAREDIR}/u-boot-with-dtb.bin conv=notrunc bs=1024 seek=$uboot_position of=${DEST}/pine64.img
