#!/bin/bash

song_info=$(/usr/bin/playerctl metadata --format '{{title}}      {{artist}}')

echo "$song_info"