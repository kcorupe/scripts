#!/bin/bash
# Simple script to upload a screenshot or file to remote server for easy download or viewing for another party
# Used mostly for showing screenshots or uploading funny images to be viewed in IRC Chats
# It will also create a new unique folder on the remote folder
# Wrtten by Kyle Corupe
# 6/22/2012

date=`date +"%A, %h %d %Y %H:%m:%S %Z"`
filename=$1
servername="aznetworkuptime.com"
remotepath="/var/www/html/uploads"
uniquefolder=$(uuidgen | awk -F "-" '{print $5}')
renamefile=$(echo ${filename} | tr '[:upper:]' '[:lower:]' | tr -d " " | sed 's/\\/-/g')
fullurl="https://${servername}/uploads/${uniquefolder}/${renamefile}"

#Renaming File to Remove Spaces and Make
mv -v "$filename" $renamefile


# Create New Remote Dir
echo "Creating: ${remotepath}/${uniquefolder}"
ssh ${servername} "mkdir -v ${remotepath}/${uniquefolder}"
if [ $? -eq 0 ];then
        /Users/kyle.corupe/bin/growlnotify -a terminal -t "Success" -m "Unique folder ${uniquefolder} created"
else
        /Users/kyle.corupe/bin/growlnotify -a terminal -t "Failed" -m "Was unable to create unique folder for upload - quitting"
		exit 1
fi

# Copying File to Server
scp ${renamefile} ${servername}:${remotepath}/${uniquefolder}
if [ $? -eq 0 ];then
	echo "Your Image is available at ${fullurl}"
	/Users/kyle.corupe/bin/growlnotify -a terminal -t "Transfer Complete for: ${filename}" -m "${date}\nURL: ${fullurl}"
	exit 0
else
	echo "Transfer failed"
	/Users/kyle.corupe/bin/growlnotify -a terminal -t "Transfer failed for: ${filename}" -m "The file did not xfer successfully"
	exit 1
fi
