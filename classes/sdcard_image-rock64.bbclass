inherit image_types

#
# Create a ROCK64 image that can be written onto a SD card using dd.
# Based on https://github.com/agherzan/meta-raspberrypi/blob/master/classes/sdcard_image-rpi.bbclass
#
# ROCK64 Boot flow:
#+--------+----------------+----------+-------------+---------+
#| Boot   | Terminology #1 | Actual   | Rockchip    | Image   |
#| stage  |                | program  |  Image      | Location|
#| number |                | name     |   Name      | (sector)|
#+--------+----------------+----------+-------------+---------+
#| 1      |  Primary       | ROM code | BootRom     |         |
#|        |  Program       |          |             |         |
#|        |  Loader        |          |             |         |
#|        |                |          |             |         |
#| 2      |  Secondary     | U-Boot   |idbloader.img| 0x40    | pre-loader
#|        |  Program       | TPL/SPL  |             |         |
#|        |  Loader (SPL)  |          |             |         |
#|        |                |          |             |         |
#| 3      |  -             | U-Boot   | u-boot.itb  | 0x4000  | including u-boot and atf
#|        |                |          | uboot.img   |         | only used with miniloader
#|        |                |          |             |         |
#|        |                | ATF/TEE  | trust.img   | 0x6000  | only used with miniloader
#|        |                |          |             |         |
#| 4      |  -             | kernel   | boot.img    | 0x8000  |
#|        |                |          |             |         |
#| 5      |  -             | rootfs   | rootfs.img  | 0x40000 |
#+--------+----------------+----------+-------------+---------+

# The disk layout used is:
#
#    0                      -> IDBLOADER                      - empty
#    IDBLOADER              -> UBOOT                          - pre-loader
#    UBOOT                  -> TRUST                          - UBoot
#    TRUST                  -> BOOT                           - ARM trusted firmware
#    BOOT                   -> ROOTFS                         - Kernel + Device Tree Blob
#    ROOTFS                 -> SDIMG_SIZE                     - RootFS

#                                                     Default Free space = 1.3x
#                                                     Use IMAGE_OVERHEAD_FACTOR to add more space
#
#  32KiB     ~8MiB      4MiB    4MiB     ~112MiB   SDIMG_ROOTFS
# <------><----------> <-----> <-----> <--------> <------------>
# -------- ----------- ------- ------- ---------- -------------
# | EMPTY | IDBLOADER | UBOOT | TRUST |   BOOT   |   ROOTFS    |
#  ------- ----------- ------- ------- ---------- -------------
# ^       ^           ^       ^       ^          ^             ^ 
# |       |           |       |       |          |             |
# 0      32KiB       8MiB   12MiB   16MiB      128MiB  128MiB+SDIMG_ROOTFS

# This image depends on the rootfs image
IMAGE_TYPEDEP_rock64-sdimg = "${SDIMG_ROOTFS_TYPE}"

# Set kernel and boot loader
IMAGE_BOOTLOADER ?= "u-boot-rockchip"

# Kernel image name
SDIMG_KERNELIMAGE  ?= "Image"

# Boot partition volume id
BOOTDD_VOLUME_ID ?= "${MACHINE}"

# Use an uncompressed ext3 by default as rootfs
SDIMG_ROOTFS_TYPE ?= "ext3"
SDIMG_ROOTFS = "${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.${SDIMG_ROOTFS_TYPE}"

# For the names of kernel artifacts
inherit kernel-artifact-names

do_image_rock64_sdimg[depends] = " \
    parted-native:do_populate_sysroot \
    mtools-native:do_populate_sysroot \
    dosfstools-native:do_populate_sysroot \
    virtual/kernel:do_deploy \
    ${IMAGE_BOOTLOADER}:do_deploy \
"


