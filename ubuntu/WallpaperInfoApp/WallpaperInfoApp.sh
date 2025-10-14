#!/bin/bash

unset GTK_PATH
export GTK_PATH=/usr/lib/x86_64-linux-gnu/gtk-3.0
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
export XDG_CURRENT_DESKTOP=Unity
export ORIGINAL_XDG_CURRENT_DESKTOP=ubuntu:GNOME
os=$(bp_os)

if [ "${os}" = "linux" ]; then
    if [ ! -d ~/logs ]; then
        mkdir -p ~/logs
    fi
    cd ~/bin/WallpaperInfoApp
    # must redirect stdout to /dev/null to diswon completely
    #LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu/gtk-3.0/modules:$LD_LIBRARY_PATH ~/bin/WallpaperInfoApp.sh > /dev/null 2>&1 & disown
    # ~/bin/WallpaperInfoApp/WallpaperInfoApp.bin > /dev/null 2>&1 & disown
    exec ~/bin/WallpaperInfoApp/WallpaperInfoApp.bin | tee > /dev/null 2>&1 & disown
fi
