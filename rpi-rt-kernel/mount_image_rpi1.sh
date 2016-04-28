#!/bin/bash

echo "Testando compilacao de KERNEL RP para raspberry PI"
echo "Fonte do script: http://www.frank-durr.de/?p=203"

# Este script é apenas um compilado do procedimento exposto no blog 
# Tem o propósito de servir como um "memorial descritivo" para este procedimento.

echo "Versão do Kernel - RPI-4.1, Versão do patch RT 4.1.20-rt23"

if [ -d "linux" ]; then 
	echo "Kernel Directory exists, going to it"
	
	cd linux
	echo "Reverting branch to original state"
	git reset --hard origin/rpi-4.1.y
	git clean -d -f
	make mrproper
	cd ..
else
	echo "Kernel Directory doesn't exists, cloning it"
	git clone https://github.com/raspberrypi/linux.git
	git checkout rpi-4.1.y
fi

cd linux

# These options are for RPI model 1
export ARCH=arm
export KERNEL=kernel
export CROSS_COMPILE=$HOME/dev_tools/rpi-tools/tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/bin/arm-linux-gnueabihf-

if [ ! -f "patch-4.1.20-rt23.patch.gz" ]; then
	echo "Downloading kernel rt patch"
	wget https://www.kernel.org/pub/linux/kernel/projects/rt/4.1/patch-4.1.20-rt23.patch.gz
fi

zcat patch-4.1.20-rt23.patch.gz | patch -p1

cp ../../config-rt ./.config

make -j3 zImage modules dtbs

#This will download the ARCH and exchange the Kernel
cd ..

if [ ! -f ./ArchLinuxARM-rpi-latest.tar.gz ]; then
	echo "ArchLinux for RPI Model 1 doesn't exist, downloading"
	wget https://archlinuxarm.org/os/ArchLinuxARM-rpi-latest.tar.gz 2> /dev/null
	echo "Finished downloading ARCH Linux"
else 
	echo "ArchLinux for RPI Model 1 exists, modifying it"
fi

if [ ! -d "rootfs" ]
then
	echo "\n#### rootfs dir doesn't exist, creating ####\n"
	mkdir rootfs
else
	echo "\n#### rootfs dir do exist, removing and creating a new one ####\n"
	sudo su -c "rm -rf rootfs"
	mkdir rootfs
fi

echo "\n#### Extracting ArchLinuxARM for Raspberry PI Model 1 ####\n"
sudo su -c "bsdtar -xpf ArchLinuxARM-rpi-latest.tar.gz -C rootfs"

echo "#### Moving kernel to root file system ####\n"

sudo su -c "cp linux/arch/arm/boot/Image rootfs/boot/kernel.img"
sudo su -c "cp linux/arch/arm/boot/dts/bcm2708-rpi-b.dtb rootfs/boot/bcm2708-rpi-b.dtb"
sudo su -c "cp linux/arch/arm/boot/dts/bcm2708-rpi-b-plus.dtb rootfs/boot/bcm2708-rpi-b-plus.dtb"

echo "\n#### Inserting QT Inside the image rootfs ####"
echo "#### Getting the base QT5 repository ####"
#git clone git://code.qt.io/qt/qt5.git
#cd qt5
#./init-repository --module-subset=qtbase
#cd ..

cd rootfs
sudo su -c "tar -cpvzf ../arch_linux_rasp-$(raspberryPIModel)_preemptRTKernel.tar.gz *"
cd ..

