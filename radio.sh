#!/bin/bash

APP_HOME="/home/pi/webradio" 
ARROW_UP=$'\x1b[A'
ARROW_DOWN=$'\x1b[B'
ARROW_RIGHT=$'\x1b[C'
ARROW_LEFT=$'\x1b[D'
PAGE_UP=$'\x1b[5~'
PAGE_DOWN=$'\x1b[6~'
INSERT=$'\x1b[1'
DELETE=$'\x1b[2'
ESC=$'\x1b'

print_title_pid=-1
function print_title {
	kill $print_title_pid
	while true
	do
		title=$(grep -a 'StreamTitle' mplayer.log |tail -1)
		title=${title:23}
		title=${title%%\';*}
		echo $title
		sleep 2
	done
}

source $APP_HOME/channels.sh

END=${#name[@]} 

i=$(cat $APP_HOME/current_channel)
j=$i
echo $i: ${name[$i]}
mplayer "${url[$i]}" < /dev/null > $APP_HOME/mplayer.log 2>&1 &
pid=$!
print_title &
print_title_pid=$!

while IFS= read -n 1 x; while read -n 1 -t .3 y; do x="$x$y"; done
do
  case "$x" in
    $ARROW_LEFT*)	i=$((i - 1));;
    $ARROW_RIGHT*)	i=$((i + 1));;
    $ARROW_UP*)
      volume=$(amixer get PCM |grep % |awk '{print $4}'|sed 's/[^0-9]//g')
      volume=$((volume + 5))
      if [ "$i" -gt "100" ]; then volume=100; fi
      amixer sset PCM $volume%
      top=$((volume / 10))
      for ((n=1; n<=$top; n++)); do echo -n "#"; done
      echo " $volume%"
    ;;
    $ARROW_DOWN*)
      volume=$(amixer get PCM |grep % |awk '{print $4}'|sed 's/[^0-9]//g')
      volume=$((volume - 5))
      if [ "$i" -lt "0" ]; then volume=0; fi
      amixer sset PCM $volume%
      top=$((volume / 10))
      for ((n=1; n<=$top; n++)); do echo -n "#"; done
      echo " $volume%"
    ;;
    m)
      amixer sset PCM toggle|tail -1
    ;;
    q) 
      kill $pid
      kill $print_title_pid 
      exit 0
    ;;
    *)
      if [ "$x" -ge "1" ] && [ "$x" -le "$END" ]; then i=$x; fi;;    
  esac

  if [ "$i" -lt "1" ]; then i=$END; fi
  if [ "$i" -gt "$END" ]; then i=1; fi

  if [ "$i" -ne "$j" ]
  then
    echo $i: ${name[$i]}
    kill $pid
    mplayer "${url[$i]}" < /dev/null > $APP_HOME/mplayer.log 2>&1 &
    j=$i
    echo $j > $APP_HOME/current_channel
    pid=$!
    print_title &
    print_title_pid=$!
  fi  
done


