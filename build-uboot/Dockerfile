FROM debian

RUN apt-get update && apt-get install -qy build-essential git gcc-arm-linux-gnueabihf bc libssl-dev

RUN git clone --depth=1 https://github.com/u-boot/u-boot.git
COPY fix-autoboot-script.patch /
RUN cd /u-boot && git apply /fix-autoboot-script.patch

ENV ARCH=arm
ENV CROSS_COMPILE=arm-linux-gnueabihf-

RUN cd /u-boot && make odroid_defconfig && make -j 16
