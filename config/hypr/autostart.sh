#!/bin/bash
kitty +kitten panel --edge=background --instance-group=cava-startup --config=/home/chief/.config/kitty/cava_kitty.conf --margin-top=238 --margin-right=1200 --margin-left=2 --margin-bottom=3 --name=cava-startup cava -p ~/.config/cava/cava_wallpaper.conf &
sleep 0.5
bash ~/.config/hypr/scripts/NEW_rainbow_border.sh
sleep 0.5
kitty +kitten panel --edge=background --margin-bottom=625 --margin-top=235 --margin-right=1100 --margin-left=23 --override background_opacity=0.0 --override background_blur=0 ~/.config/hypr/nms.sh &
#kitty +kitten panel --edge=background --margin-bottom=5 --margin-top=900 --margin-right=8 --margin-left=1350 --override background_opacity=0.0 --override background_blur=0 ~/.config/hypr/nms.sh &