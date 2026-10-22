# shellcheck shell=bash

# Writes the first 24 bytes of a PNG file with the given width and height: the
# signature and the start of the IHDR chunk, which is all that installIcon
# reads.
writePngHeader() {
  local file=$1 width=$2 height=$3
  printf '\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR' >"$file"
  # shellcheck disable=SC2059
  printf "$(printf '\\x%02x' \
    $((width >> 24 & 255)) $((width >> 16 & 255)) $((width >> 8 & 255)) $((width & 255)) \
    $((height >> 24 & 255)) $((height >> 16 & 255)) $((height >> 8 & 255)) $((height & 255)))" >>"$file"
}
