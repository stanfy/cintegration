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
PROFILE_LOCATION=`pwd`/../profiles/"${PROFILE_NAME}"
echo "[COPY ] ${PROFILE_LOCATION} --> ../output/"
cp "${PROFILE_LOCATION}" "../output/${PROFILE_DEST_NAME}"

#copy index.php
#INDEX_PHP_LOCATION=`pwd`/scripts/index.php
#echo "[COPY ] ${INDEX_PHP_LOCATION} --> ../output/"
#cp ${INDEX_PHP_LOCATION} ../output/


#archive location 
#change to build
DERIVED_DATA_PATH="$HOME/Library/Developer/Xcode/DerivedData"
PROJ_GREP=`grep -oE "$WORKSPACE_NAME-([a-zA-Z0-9]+)[/]" ../output/build.log | head -n1`
PROJECT_DERIVED_DATA_DIR=$(grep -oE "$WORKSPACE_NAME-([a-zA-Z0-9]+)[/]" ../output/build.log | sed -n "s/\($WORKSPACE_NAME-[a-z]\{1,\}\)\//\1/p" | head -n1)
PROJECT_DERIVED_DATA_PATH="$DERIVED_DATA_PATH/$PROJECT_DERIVED_DATA_DIR"
APPLICATION_ARCHIVE_LOCATION="${PROJECT_DERIVED_DATA_PATH}/Build/Products/${CONFIGURATION}-iphoneos/${PROJECT_APP_FILE_NAME}.app"
echo [DEBUG] DERIVED_DATA_PATH = "${DERIVED_DATA_PATH}"
echo [DEBUG] PROJECT_DERIVED_DATA_DIR = "${PROJECT_DERIVED_DATA_DIR}"
echo [DEBUG] PROJECT_DERIVED_DATA_PATH = "${PROJECT_DERIVED_DATA_PATH}"
echo [DEBUG] APPLICATION_ARCHIVE_LOCATION = "${APPLICATION_ARCHIVE_LOCATION}"

#resolving dsym location
DWARF_DSYM_FOLDER_PATH=`grep -oE "setenv[[:blank:]]DWARF_DSYM_FOLDER_PATH[[:blank:]]([[:graph:]]+)" ../output/build.log | tail -n1 | sed "s/setenv[[:blank:]]DWARF_DSYM_FOLDER_PATH[[:blank:]]\([[:graph:]]\)/\1/"`
DWARF_DSYM_FILE_NAME=`grep -oE "setenv[[:blank:]]DWARF_DSYM_FILE_NAME[[:blank:]]([[:graph:]]+)" ../output/build.log | tail -n1 | sed "s/setenv[[:blank:]]DWARF_DSYM_FILE_NAME[[:blank:]]\([[:graph:]]\)/\1/"`
DSYM_LOCATION=${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}

if [[ ! -d "${DWARF_DSYM_FOLDER_PATH}" ]]; then
   echo "[WARN ] Not found dsym folder path (${DWARF_DSYM_FOLDER_PATH}). This can be not good"
else
   echo
   echo -- DWARF DSYM INFROMATION --
   echo [DEBUG] DWARF_DSYM_FOLDER_PATH = "${DWARF_DSYM_FOLDER_PATH}"
   echo [DEBUG] DWARF_DSYM_FILE_NAME = "${DWARF_DSYM_FILE_NAME}"
   echo [DEBUG] DSYMLOCATION = "${DSYM_LOCATION}"
   echo
   echo [DEBUG] zipping DSYM file
   tar -pvczf ../output/${PROJECT_DEST_NAME}.tar.gz "${DSYM_LOCATION}" && echo [DEBUG] Done
#   if [[ "$?" -e "0" ]]; then
#      echo [DEBUG] Done
#      echo
#   fi
fi


if [[ ! -d "${PROJECT_DERIVED_DATA_PATH}/Build/Products/" ]]; then
   echo "[WARN ] Not found Default Xcode derivedData location. seaching"
   PROJ_GREP=`grep -oE "/usr/bin/touch -c .*\.app" ../output/build.log | head -n1 | grep -oE " /.*\.app" | grep -oE "/.*"`
   APPLICATION_ARCHIVE_LOCATION="${PROJ_GREP}"
   echo "[INFO ] found build dir at ${PROJ_GREP}"
   if [[ ! -d ${PROJ_GREP} ]]; then
      echo "[WARN ] Still not found .app file. Continue serch."
      PROJ_GREP=`grep -oE "setenv BUILD_DIR .*" ../output/build.log | head -n1 | grep -oE "/.*"`
      echo "[INFO ] found build dir at ${PROJ_GREP}"
      APPLICATION_ARCHIVE_LOCATION="${PROJ_GREP}/${CONFIGURATION}-iphoneos/${PROJECT_APP_FILE_NAME}.app"
      echo [DEBUG] APPLICATION_ARCHIVE_LOCATION = "${APPLICATION_ARCHIVE_LOCATION}"
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
#ipa
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

#PWD=`pwd`
#echo `dirname ${PWD}`

#echo rnning python2.5 scripts/plist-creator.py --ipa-url="${IPA_FULL_URL}" --plist-application-info-location="${INFO_PLIST_LOCATION}" --plist-app-title="${PLIST_TITLE}" --plist-app-subtitle="${PLIST_SUBTITLE}" --plist-name="${PLIST_NAME}"
python2.5 scripts/plist-creator.py --ipa-url="${IPA_FULL_URL}" --plist-application-info-location="${INFO_PLIST_LOCATION}" --plist-app-title="${PLIST_TITLE}" --plist-app-subtitle="${PLIST_SUBTITLE}" --plist-name="${PLIST_NAME}"


if [ "$?" -ne "0" ]; then
  echo [ERROR] Plist creation failed
  exit 1;
fi

echo "[SUCCESS]"

