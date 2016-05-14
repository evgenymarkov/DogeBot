#!/bin/bash

# This script makes a doge memes from template
# Usage: ./make_dog.sh newdog_filename "word1" "word2" "word3" "word4"

# return values:
# 10 - There is no arguments given
# 1x - x and subsequent arguments are undefined x = { 1, 2, ..., 4 } 
# 20 - no one doge template not found

TEMPLATES_PATH='templates/'

#------------------------------------------------------------------------------
# Argument checking

newdog_filename=
[[ -z $1 ]] && exit 10 || newdog_filename=$1
[[ -z $2 ]] && exit 11
[[ -z $3 ]] && exit 12
[[ -z $4 ]] && exit 13
[[ -z $5 ]] && exit 14

#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Word completing

meme_prefixes=( such much so many )
meme_complete_words=( amaze wow )

word_indexes=( 1 2 3 4 5 )
complete_word_index=$(( RANDOM % ${#word_indexes[@]} + 1 ))
declare "word$complete_word_index"="${meme_complete_words[$(( RANDOM % 2 ))]}"
word_indexes=( ${word_indexes[@]/"$complete_word_index"/} )

for i in ${word_indexes[@]}
do
    next_meme_word=${meme_prefixes[$((RANDOM % ${#meme_prefixes[@]}))]}
    meme_prefixes=(${meme_prefixes[@]/$next_meme_word})
    declare "word$i"="$next_meme_word $2"
    shift
done

#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Generating colors

colors=(\#FFFF01 \#00FFF7 \#0112FE \#FE00FF \#01870E \#741577 \#FE4E01)

i=1
while (( $i <= 6 ))
do
    next_color=${colors[$((RANDOM % ${#colors[@]}))]}
    colors=(${colors[@]/"$next_color"/})
    declare "color$i"=$next_color
    (( i++ ))
done
unset i

#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Choosing doge template

declare -a doge_array
i=0
for doge_template in $TEMPLATES_PATH/*.jpg
do
    if [[ -f "$doge_template" ]]
    then
        doge_array[$i]="$doge_template"
        (( i++ ))
    fi
done
unset i

if [[ ${#doge_array[@]} -eq 0 ]]
then
    echo "No doge found in templates directory" 1>&2
    exit 20
fi

doge_template=${doge_array[$((RANDOM % ${#doge_array[@]}))]}

#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Determining text positions

dimensions=$(identify -format "%[fx:w]:%[fx:h]" $doge_template)
wh=(${dimensions//:/ })
width=${wh[0]}
height=${wh[1]}

hpart=$(( height / 5 ))
for (( i = 1; i <= 5; i++ ))
do
    eval wordi_length=\${#word$i}
    declare "xpos$i"="$(shuf -n 1 -i 15-$(( width - $wordi_length * 25 )))"
    declare "ypos$i"="$(( hpart * (i - 1) + 10 ))"
done

#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Image processing

if (( $width > 520 ))
then
    fontsize=40
else
    fontsize=32
fi

convert $doge_template +repage -font "comic-sans.ttf" \
-pointsize $fontsize -gravity "NorthWest" \
-fill "$color1" -draw "text $xpos1,$ypos1 \"$word1\"" \
-fill "$color2" -draw "text $xpos2,$ypos2 \"$word2\"" \
-fill "$color3" -draw "text $xpos3,$ypos3 \"$word3\"" \
-fill "$color4" -draw "text $xpos4,$ypos4 \"$word4\"" \
-fill "$color5" -draw "text $xpos5,$ypos5 \"$word5\"" \
$newdog_filename

#------------------------------------------------------------------------------