#!/bin/sh
# name: Make the pictures smaller (1920 px)
# for: *.jpg *.jpeg *.png *.webp
# Each picture chosen gets a copy beside it, at most 1920 px on its longer side; the picture itself stays as it was.
for f in "$@"; do
    magick "$f" -resize '1920x1920>' "${f%.*}-1920.${f##*.}"
done
