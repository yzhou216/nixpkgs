# shellcheck shell=bash

# Setup hook that installs icons into the hicolor icon theme, in the directory
# that matches the size of each icon.
#
# Example usage in a derivation:
#
#   { ..., installIcons, ... }:
#   stdenv.mkDerivation {
#     ...
#     nativeBuildInputs = [ installIcons ];
#     postInstall = ''
#       installIcon --name foobar icons/foobar-*.png icons/foobar.svg
#     '';
#   }
#
# installIcon [--name <name>] [--context <context>] [--scale <scale>] [--] <file>...
#
# Installs each PNG icon into the directory for its size, such as 48x48/apps,
# and each SVG icon into scalable/apps, under $outputBin/share/icons/hicolor.
# The size is read from the PNG file, and icons are never resized.
#
#   --name     Name of the icon, without an extension, for all the files.
#              Defaults to the name of each file without its extension.
#   --context  Context directory, such as apps or mimetypes.  Defaults to apps.
#   --scale    Scale of the PNG icons.  For example, a 1024x1024 icon with
#              --scale 2 is installed into 512x512@2.  Defaults to 1.
#
# Options also take the form --option=value.
#
# The build fails if a file does not exist or is not a PNG or SVG file, if
# --name is not a valid icon name, if a file has no valid icon name and no
# --name is given, if a PNG icon is not square or its size is not a multiple
# of the scale, if --scale is greater than 1 for an SVG icon, if the hicolor
# theme has no directory for the context or for the size and scale of an
# icon, or if the icon is already installed.

# Prints the width and height of a PNG file, which its first chunk holds
_installIconPngSize() {
  # Split and join on spaces, whatever IFS the caller set
  local IFS=' '
  local -a bytes
  read -r -a bytes <<<"$(od -An -v -tu1 -N24 -w24 -- "$1")"
  # Signature, then the length and type of the IHDR chunk
  if ((${#bytes[@]} != 24)) || [[ "${bytes[*]:0:16}" != "137 80 78 71 13 10 26 10 0 0 0 13 73 72 68 82" ]]; then
    return 1
  fi
  echo "$((bytes[16] << 24 | bytes[17] << 16 | bytes[18] << 8 | bytes[19]))" \
    "$((bytes[20] << 24 | bytes[21] << 16 | bytes[22] << 8 | bytes[23]))"
}

# Succeeds if an icon name is not empty, has no directory or extension, and does
# not start with a dot, which would hide the icon
_installIconValidName() {
  [[ -n "$1" && "$1" != */* && "$1" != .* && ! "${1,,}" =~ \.(png|svg|svgz|xpm)$ ]]
}

installIcon() {
  local name context=apps scale=1
  # Unset, so that a temporary assignment such as name=foo installIcon does not
  # count as --name
  unset -v name
  while (($#)); do
    case "$1" in
    --name=* | --context=* | --scale=*)
      set -- "${1%%=*}" "${1#*=}" "${@:2}"
      continue
      ;;
    --name | --context | --scale)
      # Treat -- as a missing value, not as a name, context or scale
      if (($# < 2)) || [[ "$2" == -- ]]; then
        nixErrorLog "$1 expects an argument"
        return 1
      fi
      case "$1" in
      --name) name=$2 ;;
      --context) context=$2 ;;
      --scale) scale=$2 ;;
      esac
      shift 2
      ;;
    --)
      shift
      break
      ;;
    -*)
      nixErrorLog "unknown option $1"
      return 1
      ;;
    *) break ;;
    esac
  done

  if (($# == 0)); then
    nixErrorLog "expects at least one icon file"
    return 1
  fi
  # Check any given name, so that an empty one, for example from an empty
  # variable, fails instead of falling back to the file names
  if [[ -v name ]] && ! _installIconValidName "$name"; then
    nixErrorLog "--name expects an icon name without a directory or an extension, not '$name'"
    return 1
  fi
  # Bounded number of digits, so that the arithmetic cannot overflow
  if [[ ! "$scale" =~ ^[1-9][0-9]{0,8}$ ]]; then
    nixErrorLog "--scale expects a positive integer, not '$scale'"
    return 1
  fi
  # Suffix of the directories for the scale, such as @2
  local scaleSuffix=
  if ((scale > 1)); then
    scaleSuffix=@$scale
  fi

  # Directories that the hicolor theme defines, such as 48x48/apps and
  # 48x48@2/apps, as a comma-separated list
  local directories
  directories=,$(sed -n 's/^\(Scaled\)\{0,1\}Directories=//p' @indexTheme@ | paste -sd,),
  # Match whole contexts only.  In a directory for a size, such as
  # 48x48@2/apps, a digit comes before the context.  A comma would let the
  # context span several directories of the list.
  if [[ "$context" == *,* || "$directories" != *[0-9]"/$context,"* ]]; then
    nixErrorLog "the hicolor theme has no $context context"
    return 1
  fi

  local file base extension dimensions width height directory half sizes iconName destination
  for file in "$@"; do
    if [[ ! -f "$file" ]]; then
      nixErrorLog "$file does not exist or is not a regular file"
      return 1
    fi
    base=${file##*/}
    width=0
    case "${base,,}" in
    *.png)
      extension=png
      if ! dimensions=$(_installIconPngSize "$file"); then
        nixErrorLog "$file is not a PNG file"
        return 1
      fi
      IFS=' ' read -r width height <<<"$dimensions"
      if ((width != height)); then
        nixErrorLog "$file is ${width}x${height}, but icons must be square"
        return 1
      fi
      if ((width % scale)); then
        nixErrorLog "$file is ${width}x${height}, which is not a multiple of --scale $scale"
        return 1
      fi
      directory=$((width / scale))x$((width / scale))$scaleSuffix
      ;;
    *.svg)
      extension=svg
      # HTML page, such as one fetched from a GitHub blob URL, can embed SVG
      if ! grep -qF '<svg' -- "$file" || grep -qiE '<html([[:space:]>]|$)' -- "$file"; then
        nixErrorLog "$file is not an SVG file"
        return 1
      fi
      if ((scale > 1)); then
        nixErrorLog "--scale applies only to PNG icons, not to $file"
        return 1
      fi
      directory=scalable
      ;;
    *)
      nixErrorLog "$file is not a PNG or SVG file"
      return 1
      ;;
    esac

    if [[ "$directories" != *",$directory/$context,"* ]]; then
      half=$((width / 2))x$((width / 2))@2
      if ((width && width % 2 == 0 && scale == 1)) && [[ "$directories" == *",$half/$context,"* ]]; then
        nixErrorLog "the hicolor theme has no $directory/$context directory; pass --scale 2 to install $file into $half/$context, in a separate call from icons at scale 1"
      else
        sizes=$(tr , '\n' <<<"$directories" | sed -n "s|^\([0-9]*\)x[0-9]*$scaleSuffix/$context\$|\1|p" | sort -n | paste -sd' ')
        nixErrorLog "the hicolor theme has no $directory/$context directory for $file; its sizes for $context${scaleSuffix:+ at --scale $scale} are ${sizes:-none}"
      fi
      return 1
    fi

    iconName=${name:-${base%.*}}
    if ! _installIconValidName "$iconName"; then
      nixErrorLog "$file has no valid icon name before its extension, only '$iconName'; pass --name to name the icon"
      return 1
    fi
    destination=${!outputBin:?}/share/icons/hicolor/$directory/$context/$iconName.$extension
    if [[ -e "$destination" || -L "$destination" ]]; then
      nixErrorLog "$directory/$context/$iconName.$extension is already installed, so $file would overwrite it"
      return 1
    fi
    nixLog "installing $file as $directory/$context/$iconName.$extension"
    install -Dm644 -- "$file" "$destination" || return 1
  done
}
