#!/bin/bash

img=/tmp/screen.png
icon=~/.config/pictures/lock.png
 
maim $img
import -window root $img 
# blur
convert $img -blur 0x9 $img

#pixelate
#convert $img -scale 10% -scale 1000% $img
convert $img $icon -gravity center -composite $img

i3lock -i $img
rm $img
