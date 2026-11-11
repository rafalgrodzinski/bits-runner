#!/bin/bash

qemu-system-i386 -drive file=fdd.img,if=floppy,format=raw -display cocoa,zoom-to-fit=on -monitor unix:/tmp/qemu-monitor.sock,server,nowait &
sleep 0.5
osascript -e 'tell application "System Events" to tell (first process whose name starts with "qemu-system") to set size of front window to {1024, 768}'