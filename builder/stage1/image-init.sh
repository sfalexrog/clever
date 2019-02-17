#! /usr/bin/env bash

#
# Script for initialisation image
#
# Copyright (C) 2018 Copter Express Technologies
#
# Author: Artem Smirnov <urpylka@gmail.com>
#

set -ev # Exit immidiately on non-zero result

echo_stamp "Write CLEVER information"

# FIXME: version information doesn't work for now
# Clever image version
# echo "$1" >> /etc/clever_version
# Origin image file name
# echo "${2%.*}" >> /etc/clever_origin

echo_stamp "Write magic script to /etc/rc.local"
MAGIC_SCRIPT="sudo /root/init_rpi.sh; sudo sed -i '/sudo \\\/root\\\/init_rpi.sh/d' /etc/rc.local && sudo reboot"
sed -i "19a${MAGIC_SCRIPT}" /etc/rc.local

# It needs for autosizer.sh & maybe that is correct
echo_stamp "Change boot partition"
sed -i 's/root=[^ ]*/root=\/dev\/mmcblk0p2/' /boot/cmdline.txt
sed -i 's/.*  \/boot           vfat    defaults          0       2$/\/dev\/mmcblk0p1  \/boot           vfat    defaults          0       2/' /etc/fstab
sed -i 's/.*  \/               ext4    defaults,noatime  0       1$/\/dev\/mmcblk0p2  \/               ext4    defaults,noatime  0       1/' /etc/fstab

echo_stamp "Set max space for syslogs"
# https://unix.stackexchange.com/questions/139513/how-to-clear-journalctl
sed -i 's/#SystemMaxUse=/SystemMaxUse=200M/' /etc/systemd/journald.conf

echo_stamp "End of init image"
