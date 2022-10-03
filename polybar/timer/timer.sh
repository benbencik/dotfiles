#!/bin/bash

now () { date --utc +%s; }
killTimer () { rm -rf /tmp/polybar-timer ; }
timerSet () { [ -e /tmp/polybar-timer/ ] ; }
timerPaused () { [ -f /tmp/polybar-timer/paused ] ; }

timerExpiry () { cat /tmp/polybar-timer/expiry ; }
timerLabelRunning () { cat /tmp/polybar-timer/label_running ; }
timerLabelPaused () { cat /tmp/polybar-timer/label_paused ; }
timerAction () { cat /tmp/polybar-timer/action ; }

printExpiryTime () { dunstify -u low -r -12345 "Timer expires at $( date -d "$(secondsLeft) sec" +%H:%M)" ;}
printPaused () { dunstify -u low -r -12345 "Timer paused" ; }
removePrinting () { dunstify -C -12345 ; }


secondsLeftWhenPaused () { cat /tmp/polybar-timer/paused ; }
minutesLeftWhenPaused () {  echo $(( $(secondsLeftWhenPaused) / 60 )) ; }
secondsLeft () { echo $(( $(timerExpiry) - $(now) )); }
minutesLeft () { printf "%02d" $(( ( $(timerExpiry) - $(now) ) / 60 )); }

secondsLeftMod () { printf "%02d" $(( ( $(timerExpiry) - $(now) ) % 60 )); }
secondsLeftWhenPausedMod () { printf "%02d" $(( $(secondsLeftWhenPaused) % 60 )); }


# UPDATE -------------------------------------------------------
updateTail () {
  # check whether timer is expired
  if timerSet
  then
    if { ! timerPaused && [ $(minutesLeft) -le 0 ] && [ $(secondsLeft) -le 0 ]; }
    then
      eval $(timerAction)
      killTimer
      removePrinting
    fi
  fi

  # update output
  if timerSet
  then
    if timerPaused
    then
      echo "%{F$DISABLED_COLOR}$(timerLabelPaused) $(minutesLeftWhenPaused):$(secondsLeftWhenPausedMod)"
    else
      echo "%{F$PRIMARY_COLOR}$(timerLabelRunning) %{F$FOREGROUND_COLOR}$(minutesLeft):$(secondsLeftMod)"
    fi
  else
    echo "${STANDBY_LABEL}"
  fi
}

# MAIN CODE -------------------------------------------------------
case $1 in
  tail)
    STANDBY_LABEL=$2
    PRIMARY_COLOR=$(polybar --dump=primary party_bar)
    FOREGROUND_COLOR=$(polybar --dump=foreground party_bar)
    DISABLED_COLOR=$(polybar --dump=disabled party_bar)
    
    trap updateTail USR1

    while true
    do
      updateTail
      #  sleep ${3} &
      sleep 0.5 &
      wait
    done
    ;;
  update)
    kill -USR1 $(pgrep --oldest --parent ${2})
    ;;
  new)
    state=$(cat ~/.config/polybar/timer/state)
    timer_icon=$(cat ~/.config/polybar/timer/$state | cut --delimiter=' ' --fields 1)
    timer_duration=$(cat ~/.config/polybar/timer/$state | cut --delimiter=' ' --fields 2)
    echo "$(( (state+1) % 3 ))" > ~/.config/polybar/timer/state

    killTimer
    mkdir /tmp/polybar-timer
    # echo "$(( $(now) + 60*${2} ))" > /tmp/polybar-timer/expiry
    echo "$(( $(now) + 60*$timer_duration ))" > /tmp/polybar-timer/expiry
    echo $timer_icon > /tmp/polybar-timer/label_running
    echo "${4}" > /tmp/polybar-timer/label_paused
    echo "${5}" > /tmp/polybar-timer/action
    printExpiryTime
    ;;
  increase)
    if timerSet
    then
      if timerPaused
      then
        echo "$(( $(secondsLeftWhenPaused) + ${2} ))" > /tmp/polybar-timer/paused
      else
        echo "$(( $(timerExpiry) + ${2} ))" > /tmp/polybar-timer/expiry
        printExpiryTime
      fi
    else
      exit 1
    fi
    ;;
  cancel)
    killTimer
    removePrinting
    echo "0" > ~/.config/polybar/timer/state
    ;;
  togglepause)
    if timerSet
    then
      if timerPaused
      then
        echo "$(( $(now) + $(secondsLeftWhenPaused) ))" > /tmp/polybar-timer/expiry
        rm -f /tmp/polybar-timer/paused
        printExpiryTime
      else
        secondsLeft > /tmp/polybar-timer/paused
        rm -f /tmp/polybar-timer/expiry
        printPaused
      fi
    else
      exit 1
    fi
    ;;
esac