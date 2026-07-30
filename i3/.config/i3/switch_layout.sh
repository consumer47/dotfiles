#!/bin/bash

# Switch keyboard layout using ibus
if [ "$1" == "us" ]; then
   ibus engine xkb:us::eng
elif [ "$1" == "de" ]; then
   ibus engine xkb:de::deu 
else
   echo "Usage: $0 {us|de}"
   exit 1
fi
# #!/bin/bash
#
# # Switch keyboard layout
# if [ "$1" == "us" ]; then
#     setxkbmap us
# elif [ "$1" == "de" ]; then
#     setxkbmap de
# else
#     echo "Usage: $0 {us|de}"
#     exit 1
# fi

# Physical-key remapping is handled independently by Kanata. Keeping layout
# selection here means the same Kanata layers work with both US and German XKB.
