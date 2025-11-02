#!/bin/bash

os=$(bp_os)

if [ "${os}" = "linux" ]; then
    output=$(ps -ef | grep ngorongoro | grep -v grep )
    if [ "${output}" != "" ]; then
        echo -e "${output}\n$ killall ngorongoro"
        killall ngorongoro
    fi
fi

cd ~/bin
echo -e "$ cd ~/bin; ~/bin/ngorongoro &"
# commented out for distribution
if [ "${os}" = "osx" ]; then
    ~/bin/ngorongoro &
#    cp ~/bin/ngorongoro ~/Documents/CloudStation/Install/Mac\ OS\ X/bin
elif [ "${os}" = "windows" ]; then
    ~/bin/ngorongoro &
#    cp ~/bin/ngorongoro ~/Documents/CloudStation/Install/MS\ Windows/bin
elif [ "${os}" = "linux" ]; then
    ~/bin/ngorongoro 2>&1 | tee /dev/tty >> ~/logs/ngorongoro.log &
#    cp ~/bin/ngorongoro ~/Documents/CloudStation/Install/Linux/bin
fi
disown