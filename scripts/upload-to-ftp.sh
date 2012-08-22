#!/bin/sh

#  upload-to-ftp.sh
#  AutomaticBuild
#
#  Created by Taykalo Paul on 8/3/11.
#  Copyright 2011 Stanfy. All rights reserved.

#INPUTS
echo 
echo -- FTP UPLOAD --

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


if [ "${INIT_TYPE}" != "auto" -a ${FTP_UPLOAD_NEEDED} -gt "0" ]; then

   OUTPUT_PROJECT="../output/${PROJECT_NAME}"
   if [ -d "${OUTPUT_PROJECT}" ]; then
     rm -r "${OUTPUT_PROJECT}"
   fi
   mkdir "${OUTPUT_PROJECT}"
   rsync -r --exclude "${PROJECT_NAME}"  --exclude '*.log' ../output/ "${OUTPUT_PROJECT}"
  
   echo "[INFO]"
   echo "[INFO] Uploading files"
   while IFS=' ' read -ra ADDR; do 
      for i in "${ADDR[@]}"; do
         # process "$i"
         echo "[INFO]    $i"
      done 
   done <<< `ls -1 "${OUTPUT_PROJECT}"`



   echo "[INFO] Syncing files from ${OUTPUT_PROJECT}"
   echo "[INFO]     ${FTP_UPLOAD_HOST}:${FTP_UPLOAD_DIR}"

   #scp -r -P ${FTP_UPLOAD_PORT} -i "keys/integrator.key" ""${OUTPUT_PROJECT}/*"" "${FTP_UPLOAD_USER}@${FTP_UPLOAD_HOST}:${FTP_UPLOAD_DIR}/" > ../output/build.log 2>&1

   chmod -R g+w     "${OUTPUT_PROJECT}"
   
   rsync -vr "${OUTPUT_PROJECT}/" -e "ssh -p${FTP_UPLOAD_PORT} -i keys/integrator.key" "${FTP_UPLOAD_USER}@${FTP_UPLOAD_HOST}:${FTP_UPLOAD_DIR}/" >> ../output/build.log 2>&1

   if [ "$?" -ne "0" ]; then
      echo [ERROR] FTP UPLOAD failed
      exit 1;
   else
      CHECK_BIT=$(echo ${FTP_UPLOAD_DIR} | grep -o '/home/releases/')
      if [[ -n $CHECK_BIT ]]; then
		  ssh -i keys/integrator.key ${FTP_UPLOAD_USER}@${FTP_UPLOAD_HOST} -p${FTP_UPLOAD_PORT} "echo 1 > ${CHECK_BIT}check && chmod o+w ${CHECK_BIT}check"
		  echo "[INFO] CHECK_BIT is setted" 
      fi
   fi

   echo "[SUCCESS]"
   echo

else
  echo "[SKIP ] Uploading skipped. This option can be enabled by setting 'FTP_UPLOAD_NEEDED' variable in cfg.file"
  echo
fi


# TESTFLIGHT UPLOAD
if [ "a${TESTFLIGHT_UPLOAD_NEEDED}" == "a1" ]; then
  echo "[INFO] Testflight upload"
  if [ -n "${TEAM_TOKEN}" -a -n "${API_TOKEN}" -a -n "${DIST_LIST}" ]
  then
	
	IPA_FILE=$(find ../output -d 1 -iname '*.ipa')
	echo "IPA_FILE  $IPA_FILE"
	/usr/bin/curl "http://testflightapp.com/api/builds.json" -F file=@"${IPA_FILE}" -F api_token="${API_TOKEN}" -F team_token="${TEAM_TOKEN}" -F notes="Build uploaded automatically from Jenkins." -F notify=True -F distribution_lists="${DIST_LIST}"
	
	if [ "$?" -ne "0" ]; then
      echo "[ERROR] Testflight UPLOAD failed"
      exit 1
	fi  
  else
      echo "[ERROR] Missing some parameters"
	  exit 1
  fi
fi


#find ../output/ -d 1 -iname '*.ipa' -exec mv {} "../output/${PROJECT_NAME}".ipa \;

