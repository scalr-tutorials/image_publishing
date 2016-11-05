#!/bin/bash

KITCHEN_INSTANCE=default-ubuntu-1604-us-east-1

kitchen destroy $KITCHEN_INSTANCE
kitchen create $KITCHEN_INSTANCE
kitchen converge $KITCHEN_INSTANCE
kitchen setup $KITCHEN_INSTANCE
kitchen verify $KITCHEN_INSTANCE

if [[ $? != 0 ]]; then
    echo "Testing failed. Exiting."
    kitchen destroy $KITCHEN_INSTANCE
    exit 1
fi

# image testing succeeded
echo "Image successfully tested, publishing at the account scope."
SERVER_ID=$(kitchen diagnose | grep 'serverId:' | awk '{ print $2 }')
INSTANCE_ID=$(scalr-ctl servers get --serverId $SERVER_ID | grep 'cloudServerId:' | awk '{ print $2 }')
AMI_NAME=ubuntu-16-04-apache2-$(date +"%y%m%d-%H%M%S")
AMI_ID=$(aws ec2 create-image --instance-id $INSTANCE_ID --name "$AMI_NAME" --output text)
LOCATION=$(kitchen diagnose | grep 'imageLocation:' | awk '{ print $2 }')
PLATFORM=$(kitchen diagnose | grep 'imagePlatform:' | awk '{ print $2 }')

echo "{
  \"architecture\": \"i386\",
  \"cloudImageId\": \"$AMI_ID\",
  \"cloudInitInstalled\": true,
  \"cloudLocation\": \"$LOCATION\",
  \"cloudPlatform\": \"$PLATFORM\",
  \"name\": \"$AMI_NAME\", 
  \"os\": {\"id\": \"ubuntu-16-04\"}, 
  \"scalrAgentInstalled\": true, 
  \"type\": \"ebs\"
}" | scalr-ctl account images register --stdin

kitchen destroy $KITCHEN_INSTANCE

exit 0

