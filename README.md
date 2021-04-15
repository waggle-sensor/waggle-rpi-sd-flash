# RPI_PxE_Flash_SD
Instructions for Building an SD Card .Img for flashing the RPI to a PxE-bootable state

Current Version for Download: http://3.85.9.172/rpi-pxe-setup-1.0.1.zip

### 1.) Download RPi OS

``` bash
wget https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2021-03-25/2021-03-04-raspios-buster-armhf-lite.zip
```

### 2.) Mount the /boot partition of the .img file onto machine

(This is the first partition of the sd-card, so mounting the sd-card will mount this partition)

### 3.) Make modifications to limit size of .img file

Remove the following line from the /boot/cmdline.txt file:
``` bash
init=/usr/lib/raspi-config/init_resize.sh
```

This change will not allow the .img file to consume the remaining space on the SD card.

### 4.) Make changes after booting an RPi with SD card

Boot an RPi with the SD card and make any necessary changes to the image including placing necessary applications for example the rpi-eeprom updater.

### 5.) Shut down RPi and remove SD Card, place back into machine that is creating the image.

### 6.) Find necessary information about image on SD Card

``` bash
$ sudo fdisk /dev/disk2
Disk: /dev/disk2  geometry: 15567/255/63 [250085376]
Signature: 0xAA55
Starting       Ending
#: id  cyl  hd sec -  cyl  hd sec [start -       size]
-----------------------------------------------------------
1: 0C    0 130   3 -    5 249  31 [ 8192 -      87851] Win95 FAT32L
2: 83    6  30  25 -  219  68  41 [98304 -    3424256] Linux files*
3: 00    0   0   0 -    0   0   0 [    0 -          0]     
4: 00    0   0   0 -    0   0   0 [    0 -          0]
```

We care about the size and start of the linux files sector (partition 2), adding these together gives us the size to copy from the SD-Card to minimize the image.   

In this example we have 3424256 + 98304 = 3522560, then we add another to make sure we've got everything on this sd-card making it 3522561 blocks to copy.   

We also need the bs(block size of our sd card) which can be found with

```bash
$ diskutil info disk2
Device Identifier:        disk2
Device Node:              /dev/disk2
Whole:                    Yes
Part of Whole:            disk2
Device / Media Name:      SD Card Reader
Volume Name:              Not applicable (no file system)
Mounted:                  Not applicable (no file system)
File System:              None
Content (IOContent):      FDisk_partition_scheme
OS Can Be Installed:      No
Media Type:               Generic
Protocol:                 USB
SMART Status:             Not Supported
Disk Size:                128.0 GB (128043712512 Bytes) (exactly 250085376 512-Byte-Units)
Device Block Size:        **512 Bytes**
Read-Only Media:          No
Read-Only Volume:         Not applicable (no file system)
Device Location:          Internal
Removable Media:          Removable
Media Removal:            Software-Activated
Virtual:                  No
```

The highlighted section shows our bs to be 512 bytes.

### 7.) Copy exactly the size of the used space on the sd-card to our img file

``` bash
sudo dd if=/dev/disk2 of=image.img bs=512 count=3522561
```

### 8.) Compressing our .img file

``` bash
zip -r image.zip image.img
```

### Reference Files
https://samdecrock.medium.com/building-your-custom-raspbian-image-8b54a24f814e

