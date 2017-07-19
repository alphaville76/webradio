#!/bin/bash

APP_HOME=`dirname "$0"`
ARROW_UP=$'\x1b[A'
ARROW_DOWN=$'\x1b[B'
ARROW_RIGHT=$'\x1b[C'
ARROW_LEFT=$'\x1b[D'
PAGE_UP=$'\x1b[5~'
PAGE_DOWN=$'\x1b[6~'
INSERT=$'\x1b[1'
DELETE=$'\x1b[2'
ESC=$'\x1b'

current_channel=""
current_channel_name=""
current_title=""

# Read the stream title from mplayer logs every 5 seconds
update_display_pid=-1
update_display() {
	if [ $update_display_pid -ne "-1" ]; then
	  kill $update_display_pid
        fi
	while true
	do
		title=$(grep -a 'StreamTitle' mplayer.log |tail -1)
		title=${title:23}
		title=${title%%\';*}

    if [ "$current_title" != "$title" ]; then
      echo $title
      current_title=$title
    fi
		sleep 5
	done
}

# Increment/decrement volume
set_volume() {
  increment = $1
  volume=$(amixer get PCM |grep % |awk '{print $4}'|sed 's/[^0-9]//g')
  volume=$((volume + $increment))
  if [ "$volume" -gt "100" ]; then volume=100; fi
  if [ "$volume" -lt "0" ]; then volume=0; fi
  amixer sset PCM $volume%
  top=$((volume / 10))
  for ((n=1; n<=$top; n++)); do echo -n "#"; done
  
  echo " $volume%"
}


###############################################################################
#                                                                             #
#                                   Main                                      #
#                                                                             #
###############################################################################
source $APP_HOME/channels.sh
END=${#name[@]} 

current_channel=$(cat $APP_HOME/current_channel)
current_channel_name=${name[$current_channel]}
echo $current_channel: $current_channel_name
mplayer "${url[$current_channel]}" < /dev/null > $APP_HOME/mplayer.log 2>&1 & mplayer_pid=$!
update_display & update_display_pid=$!

selected_channel=$current_channel
while IFS= read -n 1 key; while read -n 1 -t .3 key_2nd; do key="$key$key_2nd"; done
do
  case "$key" in
    $ARROW_LEFT*)	
      selected_channel=$((selected_channel - 1))
    ;;
    $ARROW_RIGHT*)
      selected_channel=$((selected_channel + 1))
    ;;
    $ARROW_UP*)
      set_volume +5
    ;;
    $ARROW_DOWN*)
      set_volume -5
    ;;
    m)
      # mute/unmute
      amixer sset PCM toggle|tail -1
    ;;
    q) 
      kill $mplayer_pid
      kill $update_display_pid 
      exit 0
    ;;
    *)
      if [ "$key" -ge "1" ] && [ "$key" -le "$END" ]; then selected_channel=$key; fi;;    
  esac

  if [ "$selected_channel" -lt "1" ]; then selected_channel=$END; fi
  if [ "$selected_channel" -gt "$END" ]; then selected_channel=1; fi

  if [ "$selected_channel" -ne "$current_channel" ]
  then
    current_channel_name=${name[$selected_channel]}
    echo $selected_channel: $current_channel_name
    kill $mplayer_pid
    mplayer "${url[$selected_channel]}" < /dev/null > $APP_HOME/mplayer.log 2>&1 & mplayer_pid=$!
    current_channel=$selected_channel
    echo $current_channel > $APP_HOME/current_channel    
    update_display & update_display_pid=$!
  fi  
done


