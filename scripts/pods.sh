#!/bin/bash

WAIT_TIME=60

podfile=$(find . -name Podfile -maxdepth 2 )

if [ -n "$podfile" ]
then
  podfile_dir=$(echo "$podfile" | xargs dirname)

  mod_time=$(stat -f %m "$podfile")

  now_time=$(date +%s)

  let "diff_time = $now_time - $mod_time"

  if [ $diff_time -lt $WAIT_TIME ]
  then
	echo
        echo "-- PODS INSTALLING --"
        cd "$podfile_dir"
        pod install --no-color
        echo
  fi
fi
                                        