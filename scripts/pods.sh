#!/bin/bash

WAIT_TIME=60

podfile=$(find . -name Podfile -maxdepth 2 )

#gemfile=$(find . -name Gemfile -maxdepth 2 )


#### INSTALL GEMS
#if [ -n "$gemfile" ]
#then
#  gemfile_dir=$(echo "gemfile" | xargs dirname)
#
#  mod_time=$(stat -f %m "$gemfile")
#
#  now_time=$(date +%s)
#
#  let "diff_time = $now_time - $mod_time"
#
#  if [ $diff_time -lt $WAIT_TIME ]
#  then
#  echo
#        echo "-- PODS INSTALLING via GEMS--"
#        cd "$podfile_dir"
#        bundle install
#        bundle exec pod install --no-color
#        echo
#  fi
#  exit 0
#fi


##### INSTALL PODS
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
                            
        pod_version=$(pod --version | tail -n1)
        echo "[INFO] Using pod version: $pod_version"
        LANG=en_US.UTF-8 pod install --no-ansi
                                                    
  fi
fi
                                                      
                                                      