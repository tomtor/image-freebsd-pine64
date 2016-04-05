# image-freebsd-pine64

First step in creating a FreeBSD image for the Pine64 is building a u-boot with 
the CONFIG_API option enabled.

This is needed for ubldr.

See https://github.com/tomtor/u-boot-pine64/tree/freebsd
and https://github.com/longsleep/build-pine64-image/tree/master/u-boot-postprocess
for build instructions.

https://github.com/tomtor/image-freebsd-pine64/raw/master/build/u-boot-with-dtb.bin is a ready to use version.
