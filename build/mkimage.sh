#!/bin/sh

# Inspired by the RPI3 image build script

FIRMWAREDIR=$PWD

# Set this based on how many CPUs you have
JFLAG=-j2

# Where to put your build objects, you need write access
export MAKEOBJDIRPREFIX=${HOME}/obj

# Where to install to
DEST=${MAKEOBJDIRPREFIX}/pine64
DEST2=${DEST}

set -e

# Your github clone of the freebsd source:
cd $HOME/src/freebsd

make TARGET=arm64 TARGET_ARCH=aarch64 -s ${JFLAG} buildworld
make TARGET=arm64 TARGET_ARCH=aarch64 -s buildkernel # NO_MODULES=YES

rm -rf ${DEST}/root
mkdir -p ${DEST}/root
make TARGET=arm64 TARGET_ARCH=aarch64 -s -DNO_ROOT installworld distribution installkernel \
     DESTDIR=${DEST}/root

echo "/dev/mmcsd0s3a / ufs rw,noatime 0 0" > ${DEST}/root/etc/fstab
echo "./etc/fstab type=file uname=root gname=wheel mode=0644" >> ${DEST}/root/METALOG

echo "hostname=\"pine64\"" > ${DEST}/root/etc/rc.conf
echo "growfs_enable=\"YES\"" >> ${DEST}/root/etc/rc.conf
echo "./etc/rc.conf type=file uname=root gname=wheel mode=0644" >> ${DEST}/root/METALOG

touch ${DEST}/root/firstboot
echo "./firstboot type=file uname=root gname=wheel mode=0644" >> ${DEST}/root/METALOG

makefs -t ffs -B little -F ${DEST}/root/METALOG ${DEST2}/ufs.img ${DEST}/root

mkimg -s bsd -p freebsd-ufs:=${DEST2}/ufs.img -o ${DEST2}/ufs_part.img

newfs_msdos -C 50m -F 16 -u 64 ${DEST2}/fat.img

mmd -i ${DEST2}/fat.img EFI
mmd -i ${DEST2}/fat.img EFI/BOOT
mcopy -i ${DEST2}/fat.img ${MAKEOBJDIRPREFIX}/arm64.aarch64/media/swan/github/freebsd/sys/boot/efi/boot1/boot1.efi ::EFI/BOOT/bootaa64.efi

boot0_position=8      # KiB
uboot_position=19096  # KiB

mkimg -s mbr -p prepboot:-'dd if=/dev/zero bs=512 count=40959' -p fat16b:=${DEST2}/fat.img -p freebsd:=${DEST2}/ufs_part.img \
    -o ${DEST2}/pine64.img

dd if=/usr/local/share/u-boot/u-boot-pine64/pine64.img conv=notrunc bs=1024 seek=$boot0_position of=${DEST2}/pine64.img
