#!/bin/bash
bat0=$(cat /sys/class/power_supply/BAT0/capacity)
bat1=$(cat /sys/class/power_supply/BAT1/capacity)
bothbatts=$((bat0 + bat1))

echo $bothbatts%
