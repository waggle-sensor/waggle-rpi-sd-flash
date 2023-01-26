#!/bin/bash

# To be executed within a RPI FS environment to create the Waggle specific bootloader firmware files
# - installs a more recent version of the `rpi-eeprom` tool to get more recent firmware files
# - creates & verifies eeprom update files using the found `bootconf.txt`
# ref: https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#eeprom-update-files

BL_PATH=/lib/firmware/raspberrypi/bootloader/
FW_PATH=${BL_PATH}/default/
EEPROM_BASE_PATH=${FW_PATH}/pieeprom-2022-12-07.bin
EEPROM_UPD_PATH=${FW_PATH}/pieeprom.upd
EEPROM_SIG_PATH=${FW_PATH}/pieeprom.sig
BOOTCONFIG_PATH=${BL_PATH}/bootconf.txt
TEST_CONFIG_PATH=/tmp/testeeprom.conf

apt-get update
apt-get install -y rpi-eeprom=15.2-1~buster

echo "== Create Waggle specific boot firmware"
rpi-eeprom-config --config ${BOOTCONFIG_PATH} --out ${EEPROM_UPD_PATH} ${EEPROM_BASE_PATH}
rpi-eeprom-digest -i ${EEPROM_UPD_PATH} -o ${EEPROM_SIG_PATH}

echo "== Test Loaded eeprom configuration"
rpi-eeprom-config ${EEPROM_UPD_PATH} --out ${TEST_CONFIG_PATH}

if cmp -s ${TEST_CONFIG_PATH} ${BOOTCONFIG_PATH}; then
   echo "Bootconf set correctly!"
else
   echo "Bootconf not applied correctly"
   exit 1
fi
