#!/bin/sh

#  create-ipa.sh
#  AutomaticBuild
#
#  Created by Taykalo Paul on 8/2/11.
#  Copyright 2011 Stanfy. All rights reserved.

export BUILD_TYPE=$1

echo 
echo -- IPA CREATING --

#INPUTS
CFG_FILE=../configs/$1.cfg

#Checking if config fil exists
if [ ! -f "${CFG_FILE}" ]; then
  echo "[ERROR] Cannot find config file at ${CFG_FILE}"
  exit 1
fi

source ${CFG_FILE}

DEV_CFG_FILE=../configs/$1-dev.cfg
  if [ -f ${DEV_CFG_FILE} ]; then
  echo Overriding ${CFG_FILE} with ${DEV_CFG_FILE}
  source ${DEV_CFG_FILE}
fi

#PARENT DIR
PARENT_DIR=`dirname ${PWD}`


#Some calculated variables
PLIST_NAME=`pwd`/../output/${PROJECT_DEST_NAME}.plist

#Creating output dir
if [ ! -d "../output" ]; then
  mkdir -p "../output"
fi



#copy profile location to output
FULL_PROFILE_NAME="${PROJECT_NAME}-${PROFILE_NAME}"
PROFILE_LOCATION="$PROFILE_HOME/${FULL_PROFILE_NAME}"
echo "[COPY ] ${PROFILE_LOCATION} --> ../output/${PROJECT_DEST_NAME}.mobileprovision"
cp "${PROFILE_LOCATION}" "../output/${PROJECT_DEST_NAME}.mobileprovision"

app_list=$(grep DerivedData ../output/build.log)
APPLICATION_ARCHIVE_LOCATION=$(python  scripts/derived.py ../output/build.log)

echo [DEBUG] APPLICATION_ARCHIVE_LOCATION = "${APPLICATION_ARCHIVE_LOCATION}"

	DWARF_DSYM_FOLDER_PATH=$(dirname "${APPLICATION_ARCHIVE_LOCATION}")
	DWARF_DSYM_FILE_NAME=$(ls ${DWARF_DSYM_FOLDER_PATH} | grep -i "\.dsym" | xargs )
    
    if [ -d "${DWARF_DSYM_FILE_NAME}" ]; then
        echo
        echo "[WARN ] Not found dsym folder path (${DWARF_DSYM_FILE_NAME}) or dsym is unpresent. This can't be good"
        echo

	else
		echo
		echo -- DWARF DSYM INFROMATION --
		echo [DEBUG] DWARF_DSYM_FOLDER_PATH = "${DWARF_DSYM_FOLDER_PATH}"
		echo [DEBUG] DWARF_DSYM_FILE_NAME = "${DWARF_DSYM_FILE_NAME}"
		echo [DEBUG] parm = "$1"
		echo
		echo [DEBUG] zipping DSYM file

		PRESENT_DIR=`pwd`
		pushd "$DWARF_DSYM_FOLDER_PATH" > /dev/null
		zip -r "${PRESENT_DIR}/../output/${PROJECT_DEST_NAME}.dSym.zip" "${DWARF_DSYM_FILE_NAME}"
		popd > /dev/null
		
		if [ "$?" -eq "0" ]; then
            echo
            echo [DEBUG] Dsym is created
        else
            echo
            echo [ERROR] Dsym creation failed
            exit 1;
        fi
		
	fi

if [ ! -d "${APPLICATION_ARCHIVE_LOCATION}" ]; then
  echo "[ERROR] No application archive at ${APPLICATION_ARCHIVE_LOCATION} :("
  echo "[ERROR] Make sure, that you correctly specified PROJECT_APP_FILE_NAME variable in cfg file"
  echo "[ERROR] Currently it has '${PROJECT_APP_FILE_NAME}' value"
  exit 1
fi

echo 
echo -- IPA PACKAGING AND SIGNING --

IPA_NAME=${PROJECT_DEST_NAME}.ipa
IPA_ARCHIVE_LOCATION=`pwd`/../output/${IPA_NAME}
IPA_FULL_URL="${IPA_URL}/${IPA_NAME}"
echo [DEBUG] IPA_ARCHIVE_LOCATION = "${IPA_ARCHIVE_LOCATION}"

#Correct developer dir location

DEVELOPER_LOCATION=`xcode-select -print-path`


#SIGNING
#This is needed for codesign
export CODESIGN_ALLOCATE="${DEVELOPER_LOCATION}/Platforms/iPhoneOS.platform/Developer/usr/bin/codesign_allocate"
echo "[SIGN ] OUTPUT  : ${IPA_ARCHIVE_LOCATION}"
echo "[SIGN ] SIGNER  : ${SIGNING_IDENTITY}"
echo "[SIGN ] PROFILE : ${PROFILE_LOCATION}"

/usr/bin/perl "${DEVELOPER_LOCATION}/Platforms/iPhoneOS.platform/Developer/usr/bin/PackageApplication" $2 "${APPLICATION_ARCHIVE_LOCATION}" -o "${IPA_ARCHIVE_LOCATION}" --sign "${SIGNING_IDENTITY}" --embed "${PROFILE_LOCATION}"

if [ "$?" -ne "0" ]; then
  echo [ERROR] Codesign failed
  exit 1;
fi

echo "[SUCCESS]"

echo 
echo -- DISTRIBUTION PLIST CREATION --

#Getting Info.plist file location
INFO_PLIST_LOCATION="${APPLICATION_ARCHIVE_LOCATION}/Info.plist"
echo [DEBUG] INFO_PLIST_LOCATION = ${INFO_PLIST_LOCATION}

#CREATING PLIST FOR DISTRIBUTED BUILD

if [ -z "$BUNDLE_IDENT_SUFFIX" ]
then 
	python2.5 scripts/plist-creator.py --ipa-url="${IPA_FULL_URL}" --plist-application-info-location="${INFO_PLIST_LOCATION}" --plist-app-title="${PLIST_TITLE}" --plist-app-subtitle="${PLIST_SUBTITLE}" --plist-name="${PLIST_NAME}"
else
	python2.5 scripts/plist-creator.py --ipa-url="${IPA_FULL_URL}" --plist-application-info-location="${INFO_PLIST_LOCATION}" --plist-app-title="${PLIST_TITLE}" --plist-app-subtitle="${PLIST_SUBTITLE}" --plist-name="${PLIST_NAME}" --bundle-ident-suffix="${BUNDLE_IDENT_SUFFIX}"
fi

if [ "$?" -ne "0" ]; then
  echo [ERROR] Plist creation failed
  exit 1;
fi

echo "[SUCCESS]"

