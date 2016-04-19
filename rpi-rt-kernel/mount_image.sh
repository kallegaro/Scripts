#!/bin/bash

usePreemptRTKernel=false
raspberryPIModel=1

getPreemptRTKernel(){
	if [ -d "linux" ]; then
		echo "Kernel directory exists, going to it"
		usePreemptRTKernel=true		
	else
		echo "linux folder doesn't exist, want to download from souce (y/n)?"
		read download_preempt_rt_kenerl
		case $download_preempt_rt_kenerl in
			Y|y) echo "Downloading preempt rt kernel from GIT"
				git clone https://github.com/raspberrypi/linux.git
				cd linux
				git checkout
				usePreemptRTKernel=true
			;;
			N|n) echo "Skipping"
				usePreemptRTKernel=false
			;;
		esac
	fi

	if [ $usePreemptRTKernel ]; then
		cd linux-rt-rpi

		echo "\n#### Configuring Kernel #### \n"	
		case $raspberryPIModel in
			1)
				make bcmrpi_rt_defconfig ;;
			2)
				make bcm2709_rt_defconfig ;;
		esac
		echo "\n#### Kernel configured, compiling #### \n"
		make -j5
		cd ..
	fi
}

export ARCH=arm
export CROSS_COMPILE=$HOME/dev_tools/rpi-tools/tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/bin/arm-linux-gnueabihf-

echo "Mounting RPI image \nWant to use PREEMPT RT emlid Kernel? (y/n) "
read preempRT

echo "Which Raspberry PI model is inteded to be used? (1/2)"
read piVersion
case $piVersion in
	1)
	echo "Configuring for Raspberry PI Model 1"
	raspberryPIModel=1
	;;
	2)
	echo "Configuring for Raspberry PI Model 2"
	raspberryPIModel=2
	;;
esac


case $preempRT in
	Y|y) echo "Using PREEMPT RT Kernel"
	getPreemptRTKernel	
	echo "Kernel compiled"
	;;
	N|n) echo "Not using PREEMPT RT Kernel"
	;;
esac

echo "\n#### Getting ArchLinux ####\n"
case $raspberryPIModel in
	1) 
	if [ ! -f ./ArchLinuxARM-rpi-latest.tar.gz ]; then
		echo "ArchLinux for RPI Model 1 doesn't exist, downloading"
		wget https://archlinuxarm.org/os/ArchLinuxARM-rpi-latest.tar.gz 2> /dev/null
		echo "Finished downloading ARCH Linux"
	fi
	;;
	2)
	if [ ! -f ./ArchLinuxARM-rpi-2-latest.tar.gz ]; then
		echo "ArchLinux for RPI Model 2 doesn't exist, downloading"
		wget https://archlinuxarm.org/os/ArchLinuxARM-rpi-2-latest.tar.gz 2> /dev/null
		echo "Finished downloading ARCH Linux"
	fi
	;;
	3) 	echo "Raspberry PI Model not known, aborting"
		exit ;;
esac

echo "Preparing to extract ARCH Linux image \n The next steps must be done as sudo"

if [ ! -d "rootfs" ]
then
	echo "\n#### rootfs dir doesn't exist, creating ####\n"
	mkdir rootfs
else
	echo "\n#### rootfs dir do exist, removing and creating a new one ####\n"
	sudo su -c "rm -rf rootfs"
	mkdir rootfs
fi

case $raspberryPIModel in
	1) 
	echo "\n#### Extracting ArchLinuxARM for Raspberry PI Model 1 ####\n"
	sudo su -c "bsdtar -xpf ArchLinuxARM-rpi-latest.tar.gz -C rootfs"
	echo "#### Moving kernel to root file system ####\n"
	sudo su -c "cp linux-rt-rpi/arch/arm/boot/Image rootfs/boot/kernel.img"
	sudo su -c "cp linux-rt-rpi/arch/arm/boot/dts/bcm2708-rpi-b.dtb rootfs/boot/bcm2708-rpi-b.dtb"
	sudo su -c "cp linux-rt-rpi/arch/arm/boot/dts/bcm2708-rpi-b-plus.dtb rootfs/boot/bcm2708-rpi-b-plus.dtb"
	;;
	
	2)
	echo "\n#### Extracting ArchLinuxARM for Raspberry PI Model 2 ####\n"
	sudo su -c "bsdtar -xpf ArchLinuxARM-rpi-2-latest.tar.gz -C rootfs"
	echo "#### Moving kernel to root file system ####\n"
	sudo su -c "cp linux-rt-rpi/arch/arm/boot/Image rootfs/boot/kernel7.img"
	sudo su -c "cp linux-rt-rpi/arch/arm/boot/dts/bcm2709-rpi-2-b.dtb rootfs/boot/bcm2709-rpi-2-b.dtb on"
	;;
	
esac

echo "\n#### Inserting QT Inside the image rootfs ####"
echo "#### Getting the base QT5 repository ####"
git clone git://code.qt.io/qt/qt5.git
cd qt5
./init-repository --module-subset=qtbase
cd ..

cd rootfs
sudo su -c "tar -cpvzf ../arch_linux_rasp-$(raspberryPIModel)_preemptRTKernel.tar.gz *"
cd ..


