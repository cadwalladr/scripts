#!/usr/bin/env bash
# Author: Dolores Portalatin <hello@doloresportalatin.info>
# Dependencies: imagemagick, i3lock-color-git, scrot, wmctrl (optional)
set -o errexit -o noclobber -o nounset

HUE=(-level 0%,100%,0.6)
EFFECT=(-filter Gaussian -resize 20% -define filter:sigma=1.5 -resize 500.5%)
IMAGE="$(mktemp).png"
DESKTOP=""

#PICNAME=`perl -e 'print int(rand(5-1))'`
if [ "$#" -gt 0 ]; then
	PICNAME="$1"
else
	PICNAME="/home/gab/Pictures/m_mini.png"
fi

OPTIONS="Options:
    -h, --help   This help menu.
    -d, --desktop    Attempt to minimize all windows before locking.
    -g, --greyscale  Set background to greyscale instead of color.
    -p, --pixelate   Pixelate the background instead of blur, runs faster.
    -f <fontname>, --font <fontname>  Set a custom font.
    -l, --listfonts  Display a list of possible fonts for use with -f/--font.
                     Note: this option will not lock the screen, it displays
                     the list and exits immediately."

# move pipefail down as for some reason "convert -list font" returns 1
set -o pipefail
trap 'rm -f "$IMAGE"' EXIT
TEMP="$(getopt -o :hdpglf: -l help,pixelate,greyscale,font: --name "$0" -- "$@")"
eval set -- "$TEMP"

while true ; do
    case "$1" in
        -h|--help)
            printf "Usage: $(basename $0) [options]\n\n$OPTIONS\n\n" ; exit 1 ;;
        -d|--desktop) DESKTOP=$(which wmctrl) ; shift ;;
        -g|--greyscale) HUE=(-level 0%,100%,0.6 -set colorspace Gray -separate -average) ; shift ;;
        -p|--pixelate) EFFECT=(-scale 10% -scale 1000%) ; shift ;;
        -f|--font)
            case "$2" in
                "") shift 2 ;;
                *) FONT=$2 ; shift 2 ;;
            esac ;;
        -l|--listfonts) convert -list font | awk -F: '/Font: / { print $2 }' | sort -du | ${PAGER:-less} ; exit 0 ;;
        --) shift ; break ;;
        *) echo "error" ; exit 1 ;;
    esac
done

# get path where the script is located to find the lock icon
SCRIPTPATH=$(realpath "$0")
SCRIPTPATH=${SCRIPTPATH%/*}

scrot -z "$IMAGE"
#ICON="$SCRIPTPATH/"
#ICON="$ICON$PICNAME"
#ICON="$ICON.png"
ICON="$PICNAME"
PARAM=(--timepos="x--110:h-120" \
  --datepos="tx+24:ty+25" \
  --clock --datestr "Type password to unlock..." \
  --insidecolor=00000000 --ringcolor=ffffffff --line-uses-inside \
  --keyhlcolor=d23c3dff --bshlcolor=d23c3dff --separatorcolor=00000000 \
  --insidevercolor=fecf4dff --insidewrongcolor=d23c3dff \
  --ringvercolor=ffffffff --ringwrongcolor=ffffffff --indpos="x+290:h-120" \
  --radius=20 --ring-width=3 --veriftext="" --wrongtext="" --noinputtext="" \
  --timecolor="ffffffff" --datecolor="ffffffff"
)

convert "$IMAGE" "${HUE[@]}" "${EFFECT[@]}" "$ICON" -gravity center -composite "$IMAGE"
#convert "$IMAGE" "${HUE[@]}" "${EFFECT[@]}" "$IMAGE"

# If invoked with -d/--desktop, we'll attempt to minimize all windows (ie. show
# the desktop) before locking.
${DESKTOP} ${DESKTOP:+-k on}

rectangles=" "

SR=$(xrandr --query | grep ' connected' | grep -o '[0-9][0-9]*x[0-9][0-9]*[^ ]*')
for RES in $SR; do
  SRA=(${RES//[x+]/ })
  CX=$((${SRA[2]} + 25))
  CY=$((${SRA[1]} - 80))
  rectangles+="rectangle $CX,$CY $((CX+300)),$((CY-80)) "
done

convert "$IMAGE" -draw "fill black fill-opacity 0.4 $rectangles" "$IMAGE"

# try to use a forked version of i3lock with prepared parameters
if ! i3lock -n "${PARAM[@]}" -i "$IMAGE" > /dev/null 2>&1; then
    # We have failed, lets get back to stock one
    i3lock -n -i "$IMAGE"
fi

# As above, if we were passed -d/--desktop, we'll attempt to restore all windows
# after unlocking.
${DESKTOP} ${DESKTOP:+-k off}
