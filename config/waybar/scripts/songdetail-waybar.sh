#!/bin/bash

song_info=$(playerctl metadata -i firefox --format '{{title}} | ')
song_info="${song_info:0:15}"

echo "$song_info"
