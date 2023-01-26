FROM ubuntu:18.04

RUN apt-get update -y && apt-get install -y \
    kpartx \
    rsync \
    wget \
    xz-utils

# using the latest "buster" release as it boots without any "first time boot" interactions
RUN wget https://downloads.raspberrypi.org/raspios_oldstable_lite_armhf/images/raspios_oldstable_lite_armhf-2022-09-26/2022-09-22-raspios-buster-armhf-lite.img.xz
RUN unxz --test *.xz
RUN unxz --verbose *.xz

RUN mkdir -p /BOOTFS/ /ROOTFS/
ADD BOOTFS /BOOTFS/
ADD ROOTFS /ROOTFS/

COPY release.sh /release.sh
ENTRYPOINT [ "/release.sh" ]