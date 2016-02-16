ifndef EXTRA_CFLAGS
	EXTRA_CFLAGS = -s -O3 -fno-strict-aliasing -ffast-math -funroll-loops -pipe # -Wall -Wextra -pedantic
endif

ifndef CC
	CC = gcc
endif

obj-m := laf.o

all: laffun lafctl lafd modules

laffun:
	$(CC) $(EXTRA_CFLAGS) -c laffun.c

lafctl:
	$(CC) $(EXTRA_CFLAGS) laffun.o lafctl.c -o lafctl

lafd:
	$(CC) $(EXTRA_CFLAGS) laffun.o lafd.c -I/usr/include/dbus-1.0 -I/usr/lib/x86_64-linux-gnu/dbus-1.0/include -L/lib/x86_64-linux-gnu -o lafd -ldbus-1

modules:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules -Wunused-function -Werror=strict-prototypes

modules-install:
	sudo cp -f laf.ko /lib/modules/$(shell uname -r)/kernel/net/laf
	sudo depmod -a

modules-uninstall:
	sudo rmmod laf
	sudo rm /lib/modules/$(shell uname -r)/kernel/net/laf/laf.ko
	sudo rmdir /lib/modules/$(shell uname -r)/kernel/net/laf

uninstall:
	sudo rm /usr/bin/lafctl
	sudo rm /usr/bin/lafd
	sudo rm /etc/laf.cfg
	sudo rm /lib/systemd/system/laf.service
	sudo rm /etc/dbus-1/system.d/lafd.conf
	sudo systemctl disable laf.service
	sudo rmmod laf
	sudo rm /lib/modules/$(shell uname -r)/kernel/net/laf/laf.ko
	sudo rmdir /lib/modules/$(shell uname -r)/kernel/net/laf
	echo "** NOW REMOVE laf FROM YOUR /etc/modules.conf OR /etc/modules-load.d FILE **"

install: all
	sudo cp -f lafctl      /usr/bin
	sudo cp -f lafd        /usr/bin
	sudo cp -f laf.cfg     /etc
	sudo cp -f laf.service /lib/systemd/system/
	sudo cp -f lafd.conf   /etc/dbus-1/system.d/
	sudo systemctl enable laf.service
	sudo mkdir -p /lib/modules/$(shell uname -r)/kernel/net/laf
	sudo cp -f laf.ko /lib/modules/$(shell uname -r)/kernel/net/laf
	sudo depmod -a
	echo "** NOW ADD laf TO YOUR /etc/modules.conf OR /etc/modules-load.d FILE **"

unload:
	sudo rmmod laf

load: all
	sudo insmod laf.ko

reset: clean unload load

clean:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean
	rm laffun.o lafctl lafd

mrproper: clean
	rm -f *.mod.* *.o *.ko .laf.* modules.order
