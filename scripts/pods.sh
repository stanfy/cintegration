#!/bin/bash

WAIT_TIME=60

podfile=$(find . -name Podfile -maxdepth 2 )

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

	podSpecifiedVersion=''
	if [ -n "$POD_VERSION" ]
	then
		podSpecifiedVersion="_${POD_VERSION}_"
	fi
	                            
        pod_version=$(pod $podSpecifiedVersion --version | tail -n1)
        echo "[INFO] Using pod version: $pod_version"
        LANG=en_US.UTF-8 pod $podSpecifiedVersion install --no-ansi
                                                    
  fi
fi
                                                      
                                                      