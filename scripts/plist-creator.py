#!/usr/bin/python2.5
import getopt, sys, string

# USAGE: python2.5 plist-creator.py --ipa-url="http://cool.ipa" --plist-bundle-identifier="geomobile.pl" --plist-bundle-version="1.5.14" --plist-app-title="Geomobile" --plist-app-subtitle="Geomobile subtitle" --plist-name="geomobile.plist"
#
# --ipa-url="http://cool.ipa" 
#    URL for download
#
# --plist-bundle-identifier="geomobile.pl" 
#    Aplication bundle identifier 
#
# --plist-bundle-version="1.5.14"
#   Application bundle version
# 
# --plist-app-title="Geomobile" 
#   Application title
#
# --plist-app-subtitle="Geomobile subtitle" 
#   Application subtitle
#
# --plist-name="geomobile.plist"
#   Result plist file name
#


IPA_URL = '<NOT_SPECIFIED>'
PLIST_APPLICATION_INFO_LOCATION = '<NOT_SPECIFIED>'
PLIST_BUNDLE_IDENTIFIER = '<NOT_SPECIFIED>'
PLIST_BUNDLE_VERSION = '<NOT_SPECIFIED>'
PLIST_APP_TITLE = '<NOT_SPECIFIED>'
PLIST_APP_SUBTITLE = '<NOT_SPECIFIED>'
PLIST_NAME = '<NOT_SPECIFIED>'

opts, args = getopt.getopt(sys.argv[1:], "uivtsn", ["ipa-url=", "plist-application-info-location=", "plist-app-title=", "plist-app-subtitle=", "plist-name="])
              
for opt, arg in opts:    
    if opt in ("-u", "--ipa-url"):      
        IPA_URL = arg
    elif opt in ("-l", "--plist-application-info-location"): 
        PLIST_APPLICATION_INFO_LOCATION = arg    
    elif opt in ("-t", "--plist-app-title"): 
        PLIST_APP_TITLE = arg            
    elif opt in ("-s", "--plist-app-subtitle"): 
        PLIST_APP_SUBTITLE = arg                
    elif opt in ("-n", "--plist-name"): 
        PLIST_NAME = arg        


from Foundation import NSMutableDictionary
from Foundation import NSMutableArray
if not PLIST_APPLICATION_INFO_LOCATION:
   print '[ERROR] Cannot find plist file %(PLIST_APPLICATION_INFO_LOCATION)'
   sys.exit(1)
application_info = NSMutableDictionary.dictionaryWithContentsOfFile_(PLIST_APPLICATION_INFO_LOCATION)
PLIST_BUNDLE_IDENTIFIER = application_info.objectForKey_('CFBundleIdentifier')
PLIST_BUNDLE_VERSION = application_info.objectForKey_('CFBundleVersion')
print '[DEBUG] Bundle identifier = %(PLIST_BUNDLE_IDENTIFIER)s' % vars()
print '[DEBUG] Bundle version    = %(PLIST_BUNDLE_VERSION)s' % vars()


root = NSMutableDictionary.dictionary()
items = NSMutableArray.array()
root.setObject_forKey_(items,'items')
main_item = NSMutableDictionary.dictionary()
items.addObject_(main_item)

assets = NSMutableArray.array()
main_item['assets'] = assets

asset_item = NSMutableDictionary.dictionary()

assets.addObject_(asset_item)
asset_item['kind'] = 'software-package'
asset_item['url'] = IPA_URL

metadata = NSMutableDictionary.dictionary()
main_item['metadata'] = metadata
metadata['bundle-identifier'] = PLIST_BUNDLE_IDENTIFIER
metadata['bundle-version'] = PLIST_BUNDLE_VERSION
metadata['kind'] = 'software'
metadata['title'] = PLIST_APP_TITLE
metadata['subtitle'] = PLIST_APP_SUBTITLE

print '[DEBUG] Direct url        = %(IPA_URL)s' % vars()

success = root.writeToFile_atomically_(PLIST_NAME, 1)
if not success:
  print "[ERROR] Failed to write plist file!"
  sys.exit(1)