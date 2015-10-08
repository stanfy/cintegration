#!/bin/sh 

#  archive.sh
#  AutomaticBuild
#
#  Created by Taykalo Paul on 8/2/11.
#  Copyright 2011 Stanfy. All rights reserved.


#INPUTS
export BUILD_TYPE=$1

echo
echo -- PROJECT BUILDING --

CFG_FILE=../configs/$1.cfg

#Checking if config fil exists
if [ ! -f "${CFG_FILE}" ]; then
  echo "[ERROR] Cannot find config file at ${CFG_FILE}"
  exit 1
fi

source ${CFG_FILE}

#check certs and mobileprovisions

FULL_PROFILE_NAME="${PROJECT_NAME}-${PROFILE_NAME}"

load_provision () {

status_first=99
status=99
        
case "$1" in
'key')
   download_file="${UPLOAD_KEY}"
   download_path="$HOME/.keystore-ci"
   store_path="${download_file}"
   ;;
'prov')
   download_file="${PROFILE_NAME}"
   download_path="${PROFILE_HOME}"
   store_path="${PROJECT_NAME}-${PROFILE_NAME}"
   ;;
'exten')
   download_file="$2"
   download_path="${PROFILE_HOME}"
   store_path="${PROJECT_NAME}-$2"
   ;;
esac   


key_local_path=$( echo ${KEY_SERVER_PATH} | egrep -i '^http[s]?://')
if [ -z "$key_local_path" ] 
then
   cp "${KEY_SERVER_PATH}/$download_file" "${download_path}/${store_path}" 2>/dev/null
   if [ "$?" -eq "0" ]
   then
   	echo "[INFO] $download_file copied"
   	return 
   else
   	echo "[ERROR] ${KEY_SERVER_PATH}/$download_file not found"
   	exit 1
   fi  
fi


if [ "0$auth_ok" == "01" ]
then
   /usr/local/bin/wget --no-check-certificate --http-user="${user}" --http-password="${pass}" -O "${download_path}/${store_path}" "${KEY_SERVER_PATH}/$download_file" 2>/dev/null
   status_first=$?
else

   /usr/local/bin/wget --no-check-certificate -O "${download_path}/${store_path}" "${KEY_SERVER_PATH}/${download_file}" 2>/dev/null
   status_first=$?

   if [ $status_first -eq 6 ]
   then
	i=0
	echo "[WARNING] Need you auth to download files"
	while True
	do
		rm -f "${download_path}/$download_file"
		
		printf 'username: '
		read user
		printf 'password: '
		read pass 
	
		/usr/local/bin/wget --no-check-certificate --http-user="${user}" --http-password="${pass}" -O "${download_path}/${store_path}" "${KEY_SERVER_PATH}/$download_file" 2>/dev/null
		status=$?
		if [ $status -eq 0 ]
		then
			auth_ok=1
			break
		fi
		if [ $status -eq 8 ]
		then
			echo "[ERROR] ${KEY_SERVER_PATH}/$download_file not found on server"
		        exit 1
		fi
		                                                                                
		let "i=$i+1"
		if [ $i -gt 3 ]
		then
			echo "[ERROR] Auth limit was reached" 
			exit 1
		fi	
		echo "[WARNING] Wrong auth. Try again"
		echo
		                
	done
   fi
fi

if [ $status_first -eq 0 -o $status -eq 0 ]
   then
	echo "[INFO] $download_file downloaded"
   else
	echo "[ERROR] ${KEY_SERVER_PATH}/$download_file not found on server"
	exit 1
fi
   
}

if [ ! -d "${PROFILE_HOME}" ]; then
   mkdir -p "${PROFILE_HOME}"
   echo "[INFO] $HOME/Library/MobileDevice/Provisioning\ Profiles/ was created"
fi

#Searching profiles
PROFILE_LOCATION="$PROFILE_HOME/${FULL_PROFILE_NAME}"
if [ ! -f "${PROFILE_LOCATION}" ]; then
   echo "[WARNING] Cannot find profile for specified build type ($1) : ( ${PROFILE_LOCATION})"
   load_provision 'prov'
fi
      

#Searching provision for extension
for extension in $PROFILE_EXTENSIONS
do
	PROFILE_EXTEN_LOCATION="$PROFILE_HOME/${PROJECT_NAME}-${extension}"   
	if [ ! -f "${PROFILE_EXTEN_LOCATION}" ]; then
   		echo "[WARNING] Cannot find extension profile for specified build type ($1) : ( ${PROFILE_EXTEN_LOCATION})"
   		load_provision 'exten' "$extension"
	fi
done      

profile_expiration=$(grep -A1 ExpirationDate -a "${PROFILE_HOME}/${FULL_PROFILE_NAME}" | tail -1 | sed -e 's/.*<date>\(.*\)<\/date>/\1/')
if [ -z "$profile_expiration" ]
then
  echo "[WARNING] ${PROFILE_NAME} - corrupted. Downloading ..."
  load_provision 'prov'
fi 

if [ $(date -j -f "%FT%TZ" $profile_expiration "+%s") -lt $(date "+%s") ]
then
  echo "[ERROR] ${PROFILE_NAME} - expired"
  load_provision 'prov'
fi

  
PROFILE_UID=`grep -E "[[:alnum:]]+-[[:alnum:]]+-[[:alnum:]]+-[[:alnum:]]+-[[:alnum:]]+" -ao "${PROFILE_LOCATION}"`

#echo $PROFILE_UID      

if [ "a$FTP_UPLOAD_NEEDED" == "a1" ]
then
   if [ ! -d "$HOME/.keystore-ci" ]
   then
       mkdir "$HOME/.keystore-ci"
       echo "[INFO] $HOME/.keystore-ci was created"
    fi

    if [ -z "$UPLOAD_KEY" ]
    then
    	echo "[ERROR] 'UPLOAD_KEY' does not exist or does not have any value in base.cfg"
    	exit 1
    elif [ ! -f "$HOME/.keystore-ci/$UPLOAD_KEY" ]      
    then
       echo "[WARNING] $UPLOAD_KEY not present. Downloading..."
       load_provision 'key'
       chmod 600 "$HOME/.keystore-ci/$UPLOAD_KEY"
    fi
fi

# Get path to -Info.plist

pushd "../.." >/dev/null 2>&1
PlistInfo=$(find . -name "$SCHEME_NAME-Info.plist")
ICONS=''

for item in ${BUILD_SERVERS}
do
if [ $(hostname) == "${item}" ]
then
    /usr/bin/git stash > /dev/null && /usr/bin/git stash clear > /dev/null
    echo "[INFO] Git was stashed"
fi       
done

if [ -n "$PlistInfo" ]
then
	if [ "a${BUNDLE_VERSION_CHANGE}" == "a1" ]
	then

		if [ -z "$BUNDLEVERSION" ]
	        then
	        	if [ "a${APPSTORE_UPLOAD_NEEDED}" == "a1" ]; then
	                	BUNDLEVERSION="${BUILD_NUMBER}"
	                else
	                	BUNDLEVERSION="${BUILD_NUMBER}.${SVN_REVISION}"
	                fi
	        fi
	        /usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${BUNDLEVERSION}" "$PlistInfo"
	        echo "[INFO] CFBundleVersion <${BUNDLEVERSION}> was changed in $PlistInfo"
	                                                                                                                                                                                                        
	fi
	
	if [ -n "$BUNDLEIDENTIFIER" ]
	then
	    /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLEIDENTIFIER" "$PlistInfo"
	    echo "[INFO] CFBundleIdentifier <$BUNDLEIDENTIFIER> was changed in $PlistInfo"
	fi
	        
	
	ICONS=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIcons:CFBundlePrimaryIcon:CFBundleIconFiles" "$PlistInfo" | egrep -v '{|}' | sed 's/\ //g')
else
	echo "[WARNING] $SCHEME_NAME-Info.plist was not found"		
fi
popd >/dev/null 2>&1

#cleaning up
OUTPUT_DIR="`pwd`/../output"
echo [DEBUG] OUTPUT_DIR = "${OUTPUT_DIR}"
if [ -d "${OUTPUT_DIR}" ]; then
  rm -r "${OUTPUT_DIR}"
  echo [CLEAN] Removing old files from output dir
fi
mkdir "${OUTPUT_DIR}"


cd ../..

#remove old archives
if [ ${CLEAN_BEFORE_BUILD} -gt 0 ]; then
 echo [CLEAN] Performing project clean \(CLEAN_BEFORE_BUILD == 1 \)
 xcodebuild -verbose -scheme ${SCHEME_NAME} -sdk ${IPHONE_SDK} -configuration ${CONFIGURATION} clean > cintegration/output/build.log
fi

TARGET_PARAMS=""
if [ ! -z "${BUILD_TARGET}" ]; then
  TARGET_PARAMS="-target ${BUILD_TARGET}"
fi

if [ "${USER}" == "$CI_USER" ]; then
  echo "[INTEGRATOR] Integrator user found"
  echo "[INTEGRATOR] Unlocking iPhone keychain"
  security list-keychains -s "/Users/${CI_USER}/Library/Keychains/${KEYCHAIN_NAME}.keychain"
  security unlock-keychain -p "$KEYCHAIN_PASS" "/Users/${CI_USER}/Library/Keychains/${KEYCHAIN_NAME}.keychain"
  security set-keychain-settings -lut 1800 "/Users/${CI_USER}/Library/Keychains/${KEYCHAIN_NAME}.keychain"
fi


#get icons
CHECK_FOR_CLIENT_BUILD=$(echo "$1" | grep -i "client")
if [ -n "$ICONS" ]
then
  ICONS_ARR=''
  ICONS_SIZE_ARR=''
  while read line
  do
  	ICON=''
  	ICON=$(find . -name "$line*" | head -n 1) 	
  	if [ -n "$ICON" ]
  	then

           SIZE_ICONS=''
           SIZE_ICONS=$(/usr/bin/stat -f "%z %N" "$ICON" 2> /dev/null)
           ICONS_SIZE_ARR=$(printf "%s\n%s" "$ICONS_SIZE_ARR" "$SIZE_ICONS")
           ICONS_ARR=$(printf "%s\n%s" "$ICONS_ARR" "$ICON")
  	fi

  done <<< "$ICONS"

  CHECK_FOR_CLIENT_BUILD=$(echo "$1" | grep -i "client")
  if [[ -z ${CHECK_FOR_CLIENT_BUILD} ]]; then
  
  	SORT_ICONS=$(echo "$ICONS_SIZE_ARR"| sort -nrk 1 | cut -d' ' -f 2-)
  	icon2=$(echo "$SORT_ICONS" | sed -n 1p)
  	icon=$(echo "$SORT_ICONS" | sed -n 2p)

  	if [ -f "$icon" ]
  		then
	  	cp "$icon" "$(pwd)/cintegration/output/icon.png"
        	echo "[INFO] $icon was copied to icon.png"
	else	
  		echo '[INFO] icon.png was not found'
	fi
                                                                     
	if [ -f "$icon2" ]
	then
	   	cp "$icon2" "$(pwd)/cintegration/output/icon2.png"
        	echo "[INFO] $icon2 was copied to icon2.png"
	else
  		echo '[INFO] icon@2x.png was not found'
	fi
  fi
                                                                                                                               
  #insert info in icons
  if [ "a$ICON_ADD_INFO" = 'a1' ]
  then
        echo "[INFO] Add info to icons"
  	while read ICON_CH
	do
		if [ -f "$ICON_CH" ]
		then
	        	width=0
		        width=$(/usr/local/bin/identify -format %w "$ICON_CH")
		        if [ $width -lt 114 ]
		        then 
		        	/usr/local/bin/convert -background '#0008' -fill white -gravity center -size ${width}x10 -pointsize 10 label:"${TAG_NAME}" "${ICON_CH}" +swap -gravity north -composite "${ICON_CH}"
		        	/usr/local/bin/convert -background '#0008' -fill white -gravity center -size ${width}x20 -pointsize 10 label:"${SVN_REVISION}\n${PROJECT_DATE:4:9}" "${ICON_CH}" +swap -gravity south -composite "${ICON_CH}"
		        else
				/usr/local/bin/convert -background '#0008' -fill white -gravity center -size ${width}x14 -pointsize 14 label:"${TAG_NAME}" "${ICON_CH}" +swap -gravity north -composite "${ICON_CH}"
				/usr/local/bin/convert -background '#0008' -fill white -gravity center -size ${width}x28 -pointsize 14 label:"${SVN_REVISION}\n${PROJECT_DATE:4:9}" "${ICON_CH}" +swap -gravity south -composite "${ICON_CH}"
				                                                     
		        fi
		        echo "[INFO] Icon $ICON_CH was converted"
		fi
	done <<< "$ICONS_ARR"
  fi

fi

XCWORKSPACE=$(find . -maxdepth 1 -name "*.xcworkspace" -print -quit)
XCARCHIVE_LOCATION=`find . -maxdepth 2 -name "cintegration" -print -quit`/output/${PROJECT_NAME}.xcarchive

if [ "a${EXTENSIONS}" != "a1" ]
then
	ADDITIONAL_BUILD_PARAMS="PROVISIONING_PROFILE=${PROFILE_UID} ${ADDITIONAL_BUILD_PARAMS}"
fi

if [ -n "$XCWORKSPACE" ]
then
    	echo [BUILD] Running xcodebuild -sdk ${IPHONE_SDK} -workspace ${XCWORKSPACE} -scheme ${SCHEME_NAME} -configuration ${CONFIGURATION} archive CODE_SIGN_IDENTITY="${SIGNING_IDENTITY}" XCARCHIVE_LOCATION="${XCARCHIVE_LOCATION}" ${ADDITIONAL_BUILD_PARAMS}
    	xcodebuild ONLY_ACTIVE_ARCH=NO -verbose -workspace ${XCWORKSPACE} -scheme ${SCHEME_NAME} -sdk ${IPHONE_SDK} -configuration ${CONFIGURATION} -archivePath ${XCARCHIVE_LOCATION} archive CODE_SIGN_IDENTITY="${SIGNING_IDENTITY}" ${ADDITIONAL_BUILD_PARAMS} > cintegration/output/build.log 2>&1 
else
	echo [BUILD] Running xcodebuild -sdk ${IPHONE_SDK} -configuration ${CONFIGURATION} archive CODE_SIGN_IDENTITY="${SIGNING_IDENTITY}" XCARCHIVE_LOCATION="${XCARCHIVE_LOCATION}" ${ADDITIONAL_BUILD_PARAMS}
        xcodebuild ONLY_ACTIVE_ARCH=NO -verbose -scheme ${SCHEME_NAME} -sdk ${IPHONE_SDK} -configuration ${CONFIGURATION} -archivePath ${XCARCHIVE_LOCATION} archive CODE_SIGN_IDENTITY="${SIGNING_IDENTITY}" ${ADDITIONAL_BUILD_PARAMS} > cintegration/output/build.log 2>&1
fi

if [ "$?" -ne "0" ]; then
  echo
  PROJ_GREP=`grep -oE "([[:alnum:]]+.[mh]:[0-9]+:[0-9]+)||(xcodebuild): error:.*" ${OUTPUT_DIR}/build.log`
  while IFS=$'\n' read -ra ADDR; do 
     for i in "${ADDR[@]}"; do
     # process "$i"
     echo "[ERROR] $i"
    done 
  done <<< "$PROJ_GREP"

#  echo "[ERROR] ${PROJ_GREP}"
  echo "[ERROR] XCODE build failed. See output/build.log for error description"
  tail -n250 "${OUTPUT_DIR}/build.log"
  exit 1
fi

echo "[SUCCESS]"
