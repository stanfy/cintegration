Scripts for Continious Integration
======

For Jenkins and a manual building of a project.

Main features
------------
- To build and sign ipa
- Generate plist file
- Collect dsim
- Add aditional info to app icon (git revision)
- Upload results to a private web server
- Upload results to Testflight
- Upload results to Crittercism
- Upload results to Hockeyapp
- Upload results to Amazon S3



Quick start
-------------
To build and sign ipa. Results will be in the **output** folder.

- Create a folder **cintegration** in your project with a next structure.

```bash
xcode-project
             /cintegration
                           /bin                   <-- git the submodule to this repo
                           /configs               <-- create a folder
                                     base.cfg     <-- add an empty file
                                     dev.cfg      <-- add an empty file   
                                     client.cfg   <-- optional: add an empty file
                           /output                <-- created by script
             /Frameworks
             /MyProject.xcworkspace
             /MyProject
```

- Create a new keychain with name **ios**, set a password for its **integrator** and add a certificate with a private key for app signing
- Create a folder and put there mobileprovision. For example: create **/User/jenkins/keys** and put there **dev.mobileprovision**
- Create and edit minimal **base.cfg**

```bash
#!/bin/sh

PROJECT_NAME=____your_project_name____  #Edit

#If SCHEME_NAME is different from PROJECT_NAME, then set a right one.
SCHEME_NAME="$PROJECT_NAME"

PROJECT_VERSION="1.0"

##################################

#Load main.cfg file
source main.cfg   #Don't edit

#################################

# Full url or local dir path to keys and provisions
KEY_SERVER_PATH='/User/jenkins/keys'  #Edit

# Build user, keychain owner
CI_USER='jenkins'  #Edit

# Keychain name with build certificate
KAYCHAIN_NAME='ios' #Edit

# Keychain pass to $KAYCHAIN_NAME
KEYCHAIN_PASS='integrator'  #Edit

# Path to Provisioning Profiles store
PROFILE_HOME=$HOME/Library/MobileDevice/Provisioning\ Profiles  #Edit optional
```

- Create and edit minimal **dev.cfg**

```bash
#!/bin/sh

#Load base.cfg
source ../configs/base.cfg #Don't edit

# username for a ipa signing
SIGNING_IDENTITY="iPhone Developer: Ivan Ivanov (HI7B2WB91Q)"  #Edit

# mobileprovision name, which placed in $KEY_SERVER_PATH
PROFILE_NAME=dev.mobileprovision  #Edit
```

- Run **dev** build

- Results will be in the **output** folder

Manual build
---------
Make **cd** from project root  to **bin** folder and run ./build with ***dev*** or ***client*** parameter
```
cd cintegration/bin  && ./build dev
```

Jenkins build
---------
Run from project root
```
./cintegration/bin/build-jenkins
```


Detail configuration
--------------

Example **base.cfg**
```bash
#!/bin/sh

PROJECT_NAME=____your_project_name____  #Edit

#If SCHEME_NAME is different from PROJECT_NAME, then set a right one.
SCHEME_NAME="$PROJECT_NAME"

PROJECT_VERSION="1.0"

##################################

#Load main.cfg file
source main.cfg   #Don't edit 

#################################

# Upload server name 
HTTP_BASE="https://stanfy.com"  #Edit

# Full url to keys and provisions
KEY_SERVER_PATH='https://stanfy.com/integration_keys'  #Edit

# WARNING: Servers name where project builds and make GIT STASH with GIT STASH CLEAN. 
BUILD_SERVERS='build.stanfy.com'  #Edit carefully

# Build user, keychain owner
CI_USER='jenkins'  #Edit

# Keychain name with build certificate
KAYCHAIN_NAME='ios' # Edit

# Keychain pass to $KAYCHAIN_NAME
KEYCHAIN_PASS='integrator'  #Edit

# Path to Provisioning Profiles store
PROFILE_HOME=$HOME/Library/MobileDevice/Provisioning\ Profiles  #Edit optional

# FTP connection parameters 
FTP_UPLOAD_HOST="stanfy.com"  #Edit
FTP_UPLOAD_PORT="4545"        #Edit
FTP_UPLOAD_USER="jenkins"     #Edit
# Public key for upload file to the server, must be placed in $KEY_SERVER_PATH/
UPLOAD_KEY='integrator.pub'  #Edit

```

Example **dev.cfg**
```bash
#!/bin/sh

#Load base.cfg
source ../configs/base.cfg #Don't edit

# Configuration name for build
CONFIGURATION=Release  #Edit optional

# Clean output directory befor build
CLEAN_BEFORE_BUILD=1  #Edit optional

# User name for a ipa signing 
SIGNING_IDENTITY="iPhone Developer: Ivan Ivanov (HI7B2WB91Q)"  #Edit

# mobileprovision name, which placed in $KEY_SERVER_PATH
PROFILE_NAME=dev.mobileprovision  #Edit

# For upload file to $HTTP_BASE server
FTP_UPLOAD_NEEDED=1  #Edit optional

# Full path to upload server folder
FTP_UPLOAD_DIR="/home/releases/${PROJECT_NAME}"  #Edit optional

# Full url to upload server folder, need for plist creation
IPA_URL="${HTTP_BASE}/releases/${PROJECT_NAME}"  #Edit optional

# Add build info on the app icon
ICON_ADD_INFO=0  #Edit optional 

```



Example **client.cfg**
```bash
#!/bin/sh

#Load base.cfg
source ../configs/base.cfg #Don't edit

# Configuration name for build
CONFIGURATION=Release  #Edit optional

# Clean output directory befor build
CLEAN_BEFORE_BUILD=1  #Edit optional

# User name for a ipa signing
SIGNING_IDENTITY="iPhone Distribution: Stanfy Company"  #Edit

# mobileprovision name, which placed in $KEY_SERVER_PATH
PROFILE_NAME=llc.mobileprovision  #Edit

# For upload file to $HTTP_BASE server
FTP_UPLOAD_NEEDED=1  #Edit optional

# Full path to upload server folder
FTP_UPLOAD_DIR="/home/clients/${PROJECT_NAME}"  #Edit optional

# Full url to upload server folder, need for plist creation
IPA_URL="${HTTP_BASE}/clients/${PROJECT_NAME}"  #Edit optional

# Add build info on the app icon
ICON_ADD_INFO=0  #Edit optional

# Upload to TESTFLIGHTS 
TESTFLIGHT_UPLOAD_NEEDED=0 #Edit optional
API_TOKEN=''
TEAM_TOKEN=''
DIST_LIST=''

# Upload to CRITTERCISM 
CRITTERCISM_UPLOAD_NEEDED=0  #Edit optional
APP_ID=''
API_KEY=''

# Upload to HOCKEYAPP
HOCKEYAPP_UPLOAD_NEEDED=0  #Edit optional
API_TOKEN_HOCKEYAPP=''

# Upload to AMAZON S3
S3_UPLOAD_NEEDED=0  #Edit optional
S3_ACCESS_KEY='' 
S3_SECRET_KEY=''
S3_BUCKET=''

```


