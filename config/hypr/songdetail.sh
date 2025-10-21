#!/bin/bash
# Made by Chief-Github 
# https://github.com/Chief-Github

song_info=$(/usr/bin/playerctl metadata --format '{{title}}      {{artist}}')

echo "$song_info"