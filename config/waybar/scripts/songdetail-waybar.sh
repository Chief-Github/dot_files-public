#!/bin/bash

song_info=$(/usr/bin/playerctl metadata --format '{{title}} | ')

echo "$song_info"
