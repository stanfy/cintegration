#!/bin/sh

str="CFBundleVersion"
i=0

list=$(find ../../.. -iname "*-Info.plist" | egrep -iv "Libs|cintegration|Frameworks|test")


while read line
do

if [ $i -eq 1 ]
then
  ver=$(echo "$line" | sed 's/\<string\>//g'| sed 's/\<\/string\>//g')
  echo "$ver"
  i=0
  break
fi

if echo "$line" | grep -i "$str" >/dev/null; then
  i=1
fi

done <  ${list}
