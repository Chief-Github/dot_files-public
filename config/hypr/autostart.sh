#!/bin/bash

kitty --class neofetch-startup --title neofetch-startup --hold sh -lc 'neofetch' &
sleep 0.5
sleep 0.5
kitty --class cava-startup --title cava-startup --override background_opacity=0.0 --override background_blur=0 -e cava
sleep 0.5


# OLD
#sleep 0.5
#kitty -e btop &
#sleep 0.5
#kitty -e cmatrix &
#kitty
#