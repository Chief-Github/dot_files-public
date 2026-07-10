#!/usr/bin/env bash

# Controls Hyprland's cursor zoom_factor, clamped between 1.0 and 3.0

# Get current blur level
get_blur() {
    hyprctl getoption -j decoration:blur:size | jq '.int'
}

# Clamp a value between 1.0 and 3.0
clamp() {
    local val="$1"
    awk "BEGIN {
        v = $val;
        if (v < 0) v = 0;
        if (v > 20) v = 20;
        print v;
    }"
}


# Set blur level
set_blur() {
    local value="$1"
    clamped=$(clamp "$value")
    hyprctl eval "hl.config({ decoration = { blur = { size = $clamped } } })"
}



case "$1" in
    reset)
        set_blur 3
        ;;
    increase)
        if [[ -z "$2" ]]; then
            echo "Usage: $0 increase STEP"
            exit 1
        fi
        current=$(get_blur)
        new=$(awk "BEGIN { print $current + $2 }")
        set_blur "$new"
        ;;
    decrease)
        if [[ -z "$2" ]]; then
            echo "Usage: $0 decrease STEP"
            exit 1
        fi
        current=$(get_blur)
        new=$(awk "BEGIN { print $current - $2 }")
        set_blur "$new"
        ;;
    *)
        echo "Usage: $0 {reset|increase STEP|decrease STEP}"
        exit 1
        ;;
esac