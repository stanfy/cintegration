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


if [ -z "${FTP_UPLOAD_NEEDED_USA}" ]; then FTP_UPLOAD_NEEDED_USA=0 ;fi
if [ -z "${S3_UPLOAD_NEEDED}" ]; then S3_UPLOAD_NEEDED=0 ;fi

if [ "${INIT_TYPE}" != "auto" -a \( "${FTP_UPLOAD_NEEDED}" = "1" -o "${FTP_UPLOAD_NEEDED_USA}" = "1" -o "${S3_UPLOAD_NEEDED}" = "1" \) ]; then

   OUTPUT_PROJECT="../output/${PROJECT_NAME}"
   if [ -d "${OUTPUT_PROJECT}" ]; then
     rm -r "${OUTPUT_PROJECT}"
   fi
   mkdir "${OUTPUT_PROJECT}"
   rsync -r --exclude "${PROJECT_NAME}"  --exclude '*.log' --exclude '*.xcarchive' ../output/ "${OUTPUT_PROJECT}"
   
   S3_UPLOADED=0
  
   echo "[INFO]"
   echo "[INFO] Uploading files"
   while IFS=' ' read -ra ADDR; do 
      for i in "${ADDR[@]}"; do
         # process "$i"
         echo "[INFO]    $i"
      done 
   done <<< `ls -1 "${OUTPUT_PROJECT}"`
   echo "[INFO] Syncing files from ${OUTPUT_PROJECT}"
   echo


   if [ "${FTP_UPLOAD_NEEDED}" = "1" ]
   then
	   chmod -R g+w     "${OUTPUT_PROJECT}"
   
	   if [ "${S3_UPLOAD_NEEDED}" = "1" ]
	   then
	      exclude='*.ipa'
	      IPA_FILE=$(ls ${OUTPUT_PROJECT}/*.ipa)
	      IPA_URL_S3="http://${S3_BUCKET}.s3.amazonaws.com"
	      sed -i '' s#${IPA_URL}#${IPA_URL_S3}# ${OUTPUT_PROJECT}/*.plist
	      echo "[INFO]   Uploading to ${IPA_URL_S3}"
	      
	      /usr/local/bin/s3cmd -c "extended/s3cfg" --access_key="${S3_ACCESS_KEY}"  --secret_key="${S3_SECRET_KEY}"  put ${IPA_FILE} -P "s3://${S3_BUCKET}/"
	      if [ "$?" -ne "0" ]; then
	         echo "[ERROR] Amazon S3 upload failed"
	         exit 1
	      else
	      	 echo "[INFO]   Uploaded to S3"
		 echo
	      	 S3_UPLOADED=1
	      fi                                        
	   else
	      exclude='0'
	   fi

	   echo "[INFO]   To:  ${FTP_UPLOAD_HOST}:${FTP_UPLOAD_DIR}"	   
	   rsync --exclude "$exclude" -vr  "${OUTPUT_PROJECT}/" -e "ssh -p${FTP_UPLOAD_PORT} -i $HOME/.keystore-ci/$UPLOAD_KEY" "${FTP_UPLOAD_USER}@${FTP_UPLOAD_HOST}:${FTP_UPLOAD_DIR}/" >> ../output/build.log 2>&1

	   if [ "$?" -ne "0" ]; then
	      echo "[ERROR] FTP UPLOAD failed"
	      exit 1;
	   else
	      CHECK_BIT=$(echo ${FTP_UPLOAD_DIR} | grep -o '/home/releases/')
	      echo "[INFO]   Link ${IPA_URL%%ios}"
	      echo "[INFO]   Uploaded to dev"
	      echo
	      if [[ -n $CHECK_BIT ]]; then
			  ssh -i "$HOME/.keystore-ci/$UPLOAD_KEY" ${FTP_UPLOAD_USER}@${FTP_UPLOAD_HOST} -p${FTP_UPLOAD_PORT} "echo 1 > ${CHECK_BIT}check && chmod o+w ${CHECK_BIT}check"
			  echo "[INFO] CHECK_BIT is set" 
	      fi
	   fi

   fi 
   
   #Export vars
   export PROJECT_DATE=${PROJECT_DATE}
   export PROJECT_DEST_NAME=${PROJECT_DEST_NAME}
   
else
  echo "[SKIP ] Uploading skipped. This option can be enabled by setting 'FTP_UPLOAD_NEEDED=1' variable in dev[client].cfg"
  echo
fi

# APPSTORE UPLOAD
if [ "a${APPSTORE_UPLOAD_NEEDED}" == "a1" ]; then
  echo "-- APPSTORE UPLOAD --"
  echo
  if [ -n "${ITUNES_CONNECT_LOGIN}" -a -n "${ITUNES_CONNECT_PASS}" ]
  then
	echo "[INFO] Insert credential for <${ITUNES_CONNECT_LOGIN}> in keychain"
	
	/usr/bin/security add-generic-password -s Xcode:itunesconnect.apple.com -a "${ITUNES_CONNECT_LOGIN}" -w "${ITUNES_CONNECT_PASS}" -UA "/Users/${CI_USER}/Library/Keychains/${KEYCHAIN_NAME}.keychain"
  	
  	IPA_FILE=$(find ../output -d 1 -iname '*.ipa')
  
  	echo
  	
	/usr/bin/xcrun -sdk ${IPHONE_SDK} Validation -online -upload -verbose "${IPA_FILE}" | grep -v 'shouldContinueUploadForApplication'
                                      
	echo "[INFO] Remove credential for <${ITUNES_CONNECT_LOGIN}> from keychain"
	
	/usr/bin/security delete-generic-password -s Xcode:itunesconnect.apple.com -a "${ITUNES_CONNECT_LOGIN}" "/Users/${CI_USER}/Library/Keychains/${KEYCHAIN_NAME}.keychain"
  else
  	echo "[ERROR] Missing some parameters"
  	exit 1
  fi
  	             	
fi
                                                                                      
                                                                                      

# TESTFLIGHT UPLOAD
if [ "a${TESTFLIGHT_UPLOAD_NEEDED}" == "a1" ]; then
  echo "[INFO] Testflight upload"
  if [ -n "${TEAM_TOKEN}" -a -n "${API_TOKEN}" -a -n "${DIST_LIST}" ]
  then
	
	IPA_FILE=$(find ../output -d 1 -iname '*.ipa')
	#echo "IPA_FILE  $IPA_FILE"
	
	/usr/bin/curl "http://testflightapp.com/api/builds.json" -F file=@"${IPA_FILE}" -F api_token="${API_TOKEN}" -F team_token="${TEAM_TOKEN}" -F notes="Build uploaded automatically from Jenkins." -F notify=True -F distribution_lists="${DIST_LIST}"
	echo
	
	if [ "$?" -ne "0" ]; then
      echo "[ERROR] Testflight UPLOAD failed"
      exit 1
	fi  
  else
      echo "[ERROR] Missing some parameters"
	  exit 1
  fi
fi


# HOCKEYAPP UPLOAD
if [ "a${HOCKEYAPP_UPLOAD_NEEDED}" == "a1" ]; then
  echo "[INFO] Hockeyapp upload"
    if [ -n "${API_TOKEN_HOCKEYAPP}" ]
    then
    
	    DSYM_FILE=''
	    IPA_FILE=$(find ../output -d 1 -iname '*.ipa'| head -n 1)
	    DSYM_FILE=$(find ../output -d 1 -iname '*.zip'| head -n 1)
	    if [ -n "$DSYM_FILE" ]
	    then
	    	/usr/bin/curl "https://rink.hockeyapp.net/api/2/apps/upload" -F ipa=@"${IPA_FILE}" -F dsym=@"${DSYM_FILE}" -H "X-HockeyAppToken: ${API_TOKEN_HOCKEYAPP}" -F notes="Build uploaded automatically from Jenkins." -F release_type=0 -F notes_type=0  -F status=2 -F notify=1
	    else
	    	/usr/bin/curl "https://rink.hockeyapp.net/api/2/apps/upload" -F ipa=@"${IPA_FILE}" -H "X-HockeyAppToken: ${API_TOKEN_HOCKEYAPP}" -F notes="Build uploaded automatically from Jenkins." -F release_type=0 -F notes_type=0  -F status=2 -F notify=1
	    fi
	    echo
                                      
	    if [ "$?" -ne "0" ]; then
		    echo "[ERROR] Hockeyapp UPLOAD failed"
		    exit 1
	    fi
    else
    	echo "[ERROR] Missing API_TOKEN_HOCKEYAPP"
    	exit 1
    fi
fi
                                                                                      
# CRITTERCISM UPLOAD
if [ "a${CRITTERCISM_UPLOAD_NEEDED}" == "a1" ]; then
  echo "[INFO] Crittercism upload"
  if [ -n "${APP_ID}" -a -n "${API_KEY}" ]
  then
  	DSYM_FILE=$(find ../output -d 1 -iname '*.zip')
        #echo "IPA_FILE  $IPA_FILE"
        /usr/bin/curl "https://www.crittercism.com/api_beta/dsym/${APP_ID}" -F dsym=@"${DSYM_FILE}" -F key="${API_KEY}"
        echo
                                      
        if [ "$?" -ne "0" ]; then
        	echo "[ERROR] Crittercism UPLOAD failed"
                exit 1
        fi
  else
  	echo "[ERROR] Crittercism need some parameters"
        exit 1
  fi
fi
                                                                                      

# SRC zipping
if [ "a${SRC_NEEDED}" == "a1" -a "a${zip_src}" == "atrue" ]; then
  echo
  echo "[INFO] Src zipping..."
  echo
  
  pushd ../.. > /dev/null 2>&1
  
  /usr/bin/zip -r0 cintegration/output/${PROJECT_DEST_NAME}_.zip * -x cintegration/\* ${SRC_EXCLUDE}  >> cintegration/output/build.log 2>&1
  
  echo "[INFO] Src uploading..."
  echo
  ssh -p 9322 -i "$HOME/.keystore-ci/$UPLOAD_KEY"  "${FTP_UPLOAD_USER}@${FTP_UPLOAD_HOST}" "/usr/bin/find ${FTP_UPLOAD_DIR}/src/ -name '${PROJECT_NAME}_${TAG_NAME}_*_.zip' -exec rm {} \;  "  
  /usr/bin/rsync -a cintegration/output/${PROJECT_DEST_NAME}_.zip  -e "ssh -p${FTP_UPLOAD_PORT} -i $HOME/.keystore-ci/$UPLOAD_KEY" "${FTP_UPLOAD_USER}@${FTP_UPLOAD_HOST}:${FTP_UPLOAD_DIR}/src/"   >> cintegration/output/build.log 2>&1 || exit 1
  
  popd  > /dev/null 2>&1
  
fi  
