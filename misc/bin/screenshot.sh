#!/usr/bin/env bash

set -e

SCREENSHOT_DIR="${HOME}/media/images/screenshots"
TIMESTAMP="$(date +%Y-%m-%d_%H-%M-%S)"
SCREENSHOT_FILE="screenshot_$TIMESTAMP.png"
IMG="$SCREENSHOT_DIR/$SCREENSHOT_FILE"

mkdir -p "$SCREENSHOT_DIR"

MODE="${1:-region}"  # region | full

# Captura
if [ "$MODE" = "full" ]; then
    grim "$IMG"
else
    GEOM="$(slurp)"
    [ -z "$GEOM" ] && exit 1
    grim -g "$GEOM" "$IMG"
fi

satty --disable-notifications --filename "$IMG" --output-filename "$IMG"

dunstify -a "screenshot" -I "$IMG" -u low -t 3000 "Screenshot saved" "$SCREENSHOT_FILE"