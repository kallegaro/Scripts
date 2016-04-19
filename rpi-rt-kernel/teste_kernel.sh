!#/bin/bash

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

if [ ! -f "patch-4.1.20-rt23.patch.gz" ]; then
	echo "Downloading kernel rt patch"
	wget https://www.kernel.org/pub/linux/kernel/projects/rt/4.1/patch-4.1.20-rt23.patch.gz
fi

zcat patch-4.1.20-rt23.patch.gz | patch -p1
