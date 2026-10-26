#!/bin/sh
# name: Put the pictures into one PDF
# for: *.jpg *.jpeg *.png *.webp
# The pictures chosen, in their order, as the pages of one PDF named after their folder, beside them.
dir="$(dirname "$1")"
magick "$@" "$dir/$(basename "$dir").pdf"
