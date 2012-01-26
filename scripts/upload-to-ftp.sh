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


if [ ${FTP_UPLOAD_NEEDED} -gt "0" ]; then

   # v0.1 support
   # In older versions there was an HTTP_BASE variable
   # If it set, we should add 
   # If we have HTTP_BASE variable, then we should ADD additional
   # Dir to fix FTP_UPLOAD_DIR and IPA_URL
   if [ ! -z "${HTTP_BASE+xxx}" ]; then 
      echo "[INFO]"
      echo "[INFO] HTTP_BASE parameter found. cintegration v0.0.1 support enabled"
      echo "[INFO]"
      echo "[INFO] Old variables values : "
      echo "[INFO]    FTP_UPLOAD_DIR         = ${FTP_UPLOAD_DIR}"
      echo "[INFO]    IPA_URL                = ${IPA_URL}"
      echo "[INFO]"

      #By default old logic was to copy in this directory
      FTP_UPLOAD_PROJECT_DIR="${PROJECT_NAME}/ios/"
      FTP_UPLOAD_DIR="${FTP_UPLOAD_DIR}${FTP_UPLOAD_PROJECT_DIR}"

      echo "[INFO] Fixed variables values : "
      echo "[INFO]    FTP_UPLOAD_DIR         = ${FTP_UPLOAD_DIR}"
      echo "[INFO]    IPA_URL                = ${IPA_URL}"
   fi



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
   fi

   echo "[SUCCESS]"

else
  echo "[SKIP ] Uploading skipped. This option can be enabled by setting 'FTP_UPLOAD_NEEDED' variable in cfg.file"
fi