#!/bin/bash -e

function cleanup()
{
   echo "== Checking if loopback device needs cleanup."
   if [ -z "$NEWDEVICE" ]; then
      echo "Manual cleanup of loopback devices neccessary."
      return -1
   fi

   echo "NEWDEVICE set @ $NEWDEVICE. Proceeding with cleanup!"
   #free loopback devices
   losetup -d $NEWDEVICE

   umount bootmnt/
   umount rootmnt/

   loopDev1=$(echo $(basename ${NEWDEVICE})p1)
   loopDev2=$(echo $(basename ${NEWDEVICE})p2)
   dmsetup remove $loopDev1
   dmsetup remove $loopDev2

   rm -rf bootmnt
   rm -rf rootmnt
   echo "Cleanup complete!"
}
trap cleanup EXIT SIGINT

BOOTDIR=bootmnt
ROOTDIR=rootmnt
# define the firmware files
RECOVERY_PATH=/${ROOTDIR}/lib/firmware/raspberrypi/bootloader/default/recovery.bin
EEPROM_UPD_PATH=/${ROOTDIR}/lib/firmware/raspberrypi/bootloader/default/pieeprom.upd
EEPROM_SIG_PATH=/${ROOTDIR}/lib/firmware/raspberrypi/bootloader/default/pieeprom.sig
OUT_PATH=/repo/output/

echo "== Mount RPI Filesystem"
#determine currently used loopback devices
losetup --output NAME -n > loopbackdevs

kpartx -a -v *.img
mkdir -p ${BOOTDIR} ${ROOTDIR}

#determine which loopback device we just created
losetup --output NAME -n > loopbackdevsAFTER
NEWDEVICE=$(grep -v -F -x -f loopbackdevs loopbackdevsAFTER)

#deterine paths to mount boot and root from (NEWDEVICE includes /dev/ path to device which is why we progress 5 characters)
bootloc=$(echo /dev/mapper/$(basename ${NEWDEVICE})p1)
rootloc=$(echo /dev/mapper/$(basename ${NEWDEVICE})p2)

mount $bootloc ${BOOTDIR}/
mount $rootloc ${ROOTDIR}/

if [ -n "$PAUSE" ]; then
   read -p "Build is paused. Image mounted @ ${BOOTDIR} & ${ROOTDIR}. Press enter to continue..."
   echo
fi

echo "== Apply boot partition modifications"
rsync -av /BOOTFS/* /${BOOTDIR}/

echo "== Apply root partition modifications"
rsync -av /ROOTFS/* /${ROOTDIR}/

echo "== chroot to RPI filesystem, update rpi-eeprom, and create Waggle boot eeprom files"
chroot /${ROOTDIR} /apply-waggle-bootfw.sh

echo "== Copy Waggle boot eeprom files to /boot partition"
cp ${RECOVERY_PATH} /${BOOTDIR}/
cp ${EEPROM_UPD_PATH} /${BOOTDIR}/
cp ${EEPROM_SIG_PATH} /${BOOTDIR}/

# unmount the partitions and export the img
cleanup
# remove the trap, since we just cleaned up the partitions
trap '' EXIT SIGINT

echo "== Compress resulting image"
xz -z --keep --threads=0 --verbose *.img

echo "== Test integrity of resulting compressed image"
xz -l *.img.xz
xz -t --verbose *.img.xz

echo "== Export resulting compressed image"
mkdir -p ${OUT_PATH}
mv *.img.xz ${OUT_PATH}/waggle-rpi-sdflash_${VERSION_LONG}.img.xz
