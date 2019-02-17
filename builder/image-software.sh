#! /usr/bin/env bash

#
# Script for install software to the image.
#
# Copyright (C) 2018 Copter Express Technologies
#
# Author: Artem Smirnov <urpylka@gmail.com>
#

set -ev # Exit immidiately on non-zero result

echo_stamp "Install apt keys & repos"

# TODO: This STDOUT consist 'OK'
curl http://repo.coex.space/aptly_repo_signing.key 2> /dev/null | apt-key add -
apt-get update
apt-get install --no-install-recommends -y -qq dirmngr=2.1.18-8~deb9u4
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-key 421C365BD9FF1F717815A3895523BAEEB01FA116

echo "deb http://packages.ros.org/ros/ubuntu stretch main" > /etc/apt/sources.list.d/ros-latest.list
echo "deb http://repo.coex.space/rpi-ros-kinetic stretch main" > /etc/apt/sources.list.d/rpi-ros-kinetic.list
echo "deb http://repo.coex.space/clever stretch main" > /etc/apt/sources.list.d/clever.list

echo_stamp "Update apt cache"

# TODO: FIX ERROR: /usr/bin/apt-key: 596: /usr/bin/apt-key: cannot create /dev/null: Permission denied
apt-get update -qq
# && apt upgrade -y

echo_stamp "Software installing"
apt-get install --no-install-recommends -y \
unzip=6.0-21 \
zip=3.0-11 \
ipython=5.1.0-3 \
ipython3=5.1.0-3 \
screen=4.5.0-6 \
byobu=5.112-1  \
nmap=7.40-1 \
lsof=4.89+dfsg-0.1 \
git \
dnsmasq=2.76-5+rpt1+deb9u1  \
tmux=2.3-4 \
vim=2:8.0.0197-4+deb9u1 \
cmake=3.7.2-1 \
libjpeg8-dev=8d1-2 \
tcpdump \
ltrace \
libpoco-dev=1.7.6+dfsg1-5+deb9u1 \
python-rosdep=0.15.0-1 \
python-rosinstall-generator=0.1.14-1 \
python-wstool=0.1.17-1 \
python-rosinstall=0.7.8-1 \
build-essential=12.3 \
libffi-dev \
monkey=1.6.9-1 \
pigpio python-pigpio python3-pigpio \
i2c-tools \
ntpdate \
python-dev \
python3-dev \
&& echo_stamp "Everything was installed!" "SUCCESS" \
|| (echo_stamp "Some packages wasn't installed!" "ERROR"; exit 1)

# Deny byobu to check available updates
sed -i "s/updates_available//" /usr/share/byobu/status/status
# sed -i "s/updates_available//" /home/pi/.byobu/status

echo_stamp "Installing pip"
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python3 get-pip.py
python get-pip.py
#my_travis_retry pip install --upgrade pip
#my_travis_retry pip3 install --upgrade pip

echo_stamp "Make sure both pip and pip3 are installed"
pip --version
pip3 --version

echo_stamp "Install and enable Butterfly (web terminal)"
my_travis_retry pip3 install butterfly
my_travis_retry pip3 install butterfly[systemd]
systemctl enable butterfly.socket

echo_stamp "Install ws281x library"
my_travis_retry pip install rpi_ws281x

echo_stamp "Setup Monkey"
mv /etc/monkey/sites/default /etc/monkey/sites/default.orig
mv /root/monkey /etc/monkey/sites/default
systemctl enable monkey.service

echo_stamp "Install Node.js"
cd /home/pi
wget https://nodejs.org/dist/v10.15.0/node-v10.15.0-linux-armv6l.tar.gz
tar -xzf node-v10.15.0-linux-armv6l.tar.gz
cp -R node-v10.15.0-linux-armv6l/* /usr/local/
rm -rf node-v10.15.0-linux-armv6l/

echo_stamp "Add .vimrc"
cat << EOF > /home/pi/.vimrc
set mouse-=a
syntax on
autocmd BufNewFile,BufRead *.launch set syntax=xml
EOF

echo_stamp "Running processes:"
ps aux

echo_stamp "Attempting to kill dirmngr"
gpgconf --kill dirmngr
# dirmngr is only used by apt-key, so we can safely kill it.
# We ignore pkill's exit value as well.
pkill -9 -f dirmngr || true
echo_stamp "Running processes:"
ps aux

echo_stamp "End of software installation"
