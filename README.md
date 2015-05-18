Scripts for iOS Continious Integration 
======

Scripts allow to build and sign an ios project manually or by Jenkins.

Main features
------------
- To build and sign ipa, ready for installation on device
- With extensions
- Upload results to a private web server, with all necessary files
- Upload results to Testflight
- Upload results to Crittercism
- Upload results to Hockeyapp
- Upload results to Amazon S3
- Generate plist file, for installation from web
- Collect dsym
- Add aditional info to app icon (git revision)



Minimal setup configuration
-----------------------------

Structure of project, with steps below:

```bash
ios-project
             /cintegration
                           /bin
                           /configs
                                     appstore.cfg
                                     base.cfg
                                     dev.cfg
                                     client.cfg
                           /output
             /Frameworks
             /MyProject.xcworkspace
             /MyProject
```

Steps:

- Create a folder **cintegration** in your project.
- Create a folder **bin** and add submodule ***https://github.com/stanfy/cintegration.git***
```
$ git submodule add  https://github.com/stanfy/cintegration.git ios-project/cintegration/bin
```
- Create a folder **configs** 
- Open **Keychain access** and add a corresponding certificate with a private key for app signing
- Create a folder **$HOME/keys** and put there mobileprovision. For example: create **/User/jenkins/keys** and put there **dev.mobileprovision**
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
KEY_SERVER_PATH='$HOME/keys'  #Edit

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

- Run build manually or by Jenkins, as described below.


Command line build
---------
If you want to build and sign ipa from a command line, then
go to project root to **bin** folder and run ./build with ***dev*** or ***client*** parameter
```
cd cintegration/bin  && ./build dev
```
Results will be in the **output** folder,  which is ready for installation via iTunes.

Jenkins build
---------
If you want to build and sign ipa by Jenkins, then :
- Open **Keychain access** on the build server and create a new keychain with name **ios**, set a password for its **integrator** 
and add a corresponding certificate with a private key for app signing
- Add parameters to **base.cfg**

```bash
# Build user, keychain owner
CI_USER='jenkins'  #Edit

# Keychain name with build certificate
KEYCHAIN_NAME='ios' #Edit

# Keychain pass to $KEYCHAIN_NAME
KEYCHAIN_PASS='integrator'  #Edit
```

- Run from project root

```
./cintegration/bin/build-jenkins
```
- Results will be in the **output** folder, which is ready for installation via iTunes.


Extended options
------------

You have an option to upload results to your web server with ability to install ipa from web. You need to add additional parameters.
Upload to the web server will be over scp with a public ssh key. 
- Setup SSH Public Key Authentication, [manual] (https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys--2)
- Add parameters to **base.cfg**

```bash
# FTP connection parameters
FTP_UPLOAD_HOST="stanfy.com"  #Edit
FTP_UPLOAD_PORT="4545"        #Edit
FTP_UPLOAD_USER="jenkins"     #Edit
# Public key for upload file to the server, must be placed in $KEY_SERVER_PATH/
UPLOAD_KEY='integrator.pub'  #Edit

# Upload server name, need for plist generation
HTTP_BASE="https://stanfy.com"  #Edit
```

- Add parameters to **dev.cfg**

```bash
# For upload file to $HTTP_BASE server
FTP_UPLOAD_NEEDED=1  #Edit optional

# Full path to upload server folder
FTP_UPLOAD_DIR="/home/releases/${PROJECT_NAME}"  #Edit optional

# Full url to upload server folder, need for plist creation
IPA_URL="${HTTP_BASE}/releases/${PROJECT_NAME}"  #Edit optional


```

If you want to build ipa with extension, then you need to add parameters.

```bash

# Build with extension
EXTENSIONS=1
PROFILE_EXTENSIONS_NAME=AppWidget.mobileprovision
EXTENSIONS_DIRS='WatchKitSupport SwiftSupport' # Copy additional extensions to ipa from xcarchive  
```

If you want to upload ipa to external services (Testflight, Crittercism, Hockeyapp, Amazon S3), then you need to add additional parameters.


```bash

# Upload to TESTFLIGHTS
TESTFLIGHT_UPLOAD_NEEDED=0 # Set 1 to upload
API_TOKEN=''
TEAM_TOKEN=''
DIST_LIST=''

# Upload to CRITTERCISM
CRITTERCISM_UPLOAD_NEEDED=0  # Set 1 to upload
APP_ID=''
API_KEY=''

# Upload to HOCKEYAPP
HOCKEYAPP_UPLOAD_NEEDED=0  # Set 1 to upload
API_TOKEN_HOCKEYAPP=''

# Upload to AMAZON S3
S3_UPLOAD_NEEDED=0  # Set 1 to upload
S3_ACCESS_KEY=''
S3_SECRET_KEY=''
S3_BUCKET=''

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

# Full url or local dir path to keys and provisions
KEY_SERVER_PATH='/User/jenkins/keys'  #Edit

# WARNING: Servers name where project builds and make GIT STASH with GIT STASH CLEAN. 
BUILD_SERVERS='build.stanfy.com'  #Edit carefully

# Build user, keychain owner
CI_USER='jenkins'  #Edit

# Keychain name with build certificate
KEYCHAIN_NAME='ios' # Edit

# Keychain pass to $KEYCHAIN_NAME
KEYCHAIN_PASS='integrator'  #Edit

# Path to Provisioning Profiles store
PROFILE_HOME=$HOME/Library/MobileDevice/Provisioning\ Profiles  #Edit optional

# FTP connection parameters 
FTP_UPLOAD_HOST="stanfy.com"  #Edit
FTP_UPLOAD_PORT="4545"        #Edit
FTP_UPLOAD_USER="jenkins"     #Edit
# Public key for upload file to the server, must be placed in $KEY_SERVER_PATH/
UPLOAD_KEY='integrator.pub'  #Edit

# Change PLIST_BUNDLE_IDENTIFIER_SUFFIX in plist
BUNDLE_IDENT_SUFFIX="" #Edit

# Change CFBundleIdentifier in project info.plist
BUNDLEIDENTIFIER="" #Edit

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
TESTFLIGHT_UPLOAD_NEEDED=0 # Set 1 to upload
API_TOKEN=''
TEAM_TOKEN=''
DIST_LIST=''

# Upload to CRITTERCISM 
CRITTERCISM_UPLOAD_NEEDED=0  # Set 1 to upload
APP_ID=''
API_KEY=''

# Upload to HOCKEYAPP
HOCKEYAPP_UPLOAD_NEEDED=0  # Set 1 to upload
API_TOKEN_HOCKEYAPP=''

# Upload to AMAZON S3
S3_UPLOAD_NEEDED=0  # Set 1 to upload
S3_ACCESS_KEY='' 
S3_SECRET_KEY=''
S3_BUCKET=''

```


