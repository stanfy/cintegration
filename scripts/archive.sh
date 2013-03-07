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

DEV_CFG_FILE=configs/$1-dev.cfg
  if [ -f ${DEV_CFG_FILE} ]; then
  echo Overriding ${CFG_FILE} with ${DEV_CFG_FILE}
  source ${DEV_CFG_FILE}
fi


#cleaning up
OUTPUT_DIR="`pwd`/../output"
echo [DEBUG] OUTPUT_DIR = "${OUTPUT_DIR}"
if [ -d "${OUTPUT_DIR}" ]; then
  rm -r "${OUTPUT_DIR}"
  echo [CLEAN] Removing old files from output dir
fi
mkdir "${OUTPUT_DIR}"

#system vars
PROFILE_HOME=~/Library/MobileDevice/Provisioning\ Profiles/
if [ ! -d "${PROFILE_HOME}" ]; then
  mkdir -p "${PROFILE_HOME}"
fi

#Searching profiles
PROFILE_LOCATION=`pwd`/../profiles/"${PROFILE_NAME}"
if [ ! -f "${PROFILE_LOCATION}" ]; then
   echo "[ERROR] Cannot find profile for specified build type ($1) : ( ${PROFILE_LOCATION})"
   exit 1
fi

PROFILE_UID=`grep -E "[[:alnum:]]+-[[:alnum:]]+-[[:alnum:]]+-[[:alnum:]]+-[[:alnum:]]+" -ao "${PROFILE_LOCATION}"` 
echo [COPY] "${PROFILE_LOCATION}" --> "${PROFILE_HOME}/${PROFILE_NAME}"
cp "${PROFILE_LOCATION}" "${PROFILE_HOME}/${PROFILE_NAME}"

cd ../..

#remove old archives
if [ ${CLEAN_BEFORE_BUILD} -gt 0 ]; then
 echo [CLEAN] Performing prohect clean \(CLEAN_BEFORE_BUILD == 1 \)
 xcodebuild -verbose -scheme ${SCHEME_NAME} -sdk ${IPHONE_SDK} -configuration ${CONFIGURATION} clean > cintegration/output/build.log
fi

TARGET_PARAMS=""
if [ ! -z "${BUILD_TARGET}" ]; then
  TARGET_PARAMS="-target ${BUILD_TARGET}"
fi

if [ "${USER}" == "jenkins-ci" ]; then
  echo "[INTEGRATOR] Integrator user found"
  echo "[INTEGRATOR] Unlocking iPhone keychain"
  security list-keychains -s /Users/jenkins-ci/Library/Keychains/iPhone.keychain 
  security unlock-keychain -p integrator /Users/jenkins-ci/Library/Keychains/iPhone.keychain
fi


if [ -n "$CFBundleIdentifier" -a -n "$CFBundlePath" ]
then
    CFBundlePath=$(echo "$CFBundlePath" | sed 's/^\///' )
    /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $CFBundleIdentifier" "$CFBundlePath"
    echo "[INFO] CFBundleIdentifier <$CFBundleIdentifier> was changed in $CFBundlePath"
fi
                        

XCWORKSPACE=$(find . -maxdepth 1 -name "*.xcworkspace" -print -quit)

if [ -n "$XCWORKSPACE" ]
then
        echo [BUILD] Running xcodebuild -sdk ${IPHONE_SDK} -workspace ${XCWORKSPACE} -configuration ${CONFIGURATION} build CODE_SIGN_IDENTITY="${SIGNING_IDENTITY}" PROVISIONING_PROFILE="${PROFILE_UID}"
        xcodebuild ONLY_ACTIVE_ARCH=NO -verbose -workspace ${XCWORKSPACE} -scheme ${SCHEME_NAME} -sdk ${IPHONE_SDK} -configuration ${CONFIGURATION} build CODE_SIGN_IDENTITY="${SIGNING_IDENTITY}" PROVISIONING_PROFILE="${PROFILE_UID}" > cintegration/output/build.log 2>&1
else
	echo [BUILD] Running xcodebuild -sdk ${IPHONE_SDK} -configuration ${CONFIGURATION} ${TARGET_PARAMS} build CODE_SIGN_IDENTITY="${SIGNING_IDENTITY}" PROVISIONING_PROFILE="${PROFILE_UID}"
	xcodebuild ONLY_ACTIVE_ARCH=NO -verbose -scheme ${SCHEME_NAME} -sdk ${IPHONE_SDK} -configuration ${CONFIGURATION} ${TARGET_PARAMS} build CODE_SIGN_IDENTITY="${SIGNING_IDENTITY}" PROVISIONING_PROFILE="${PROFILE_UID}" > cintegration/output/build.log 2>&1
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
  if [ -n "$CFBundleIdentifier" -a -n "$CFBundlePath" ]
  then
       /usr/bin/git stash > /dev/null && /usr/bin/git stash clear > /dev/null
       echo "[INFO] Git was stashed"
  fi
  exit 1
fi

echo "[SUCCESS]"
