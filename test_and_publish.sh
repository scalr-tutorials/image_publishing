#!/bin/bash

KITCHEN_INSTANCE=default-ubuntu-1604-us-east-1

kitchen destroy $KITCHEN_INSTANCE
kitchen create $KITCHEN_INSTANCE
if [[ $? != 0 ]]; then
    echo "Can't launch server. Exiting."
    kitchen destroy $KITCHEN_INSTANCE
    exit 1
fi

kitchen converge $KITCHEN_INSTANCE
kitchen setup $KITCHEN_INSTANCE
kitchen verify $KITCHEN_INSTANCE

if [[ $? != 0 ]]; then
    echo "Testing failed. Exiting."
    kitchen destroy $KITCHEN_INSTANCE
    exit 2
fi

# image testing succeeded
echo "Image successfully tested, publishing at the account scope."
SERVER_ID=$(kitchen diagnose | grep 'serverId:' | awk '{ print $2 }')
INSTANCE_ID=$(scalr-ctl servers get --serverId $SERVER_ID --json | jq -r '.data.cloudServerId')
AMI_NAME=ubuntu-16-04-apache2-$(date +"%y%m%d-%H%M%S")
AMI_ID=$(aws ec2 create-image --instance-id $INSTANCE_ID --name "$AMI_NAME" --output text)
LOCATION=$(kitchen diagnose | grep 'imageLocation:' | awk '{ print $2 }')
PLATFORM=$(kitchen diagnose | grep 'imagePlatform:' | awk '{ print $2 }')

NEW_IMAGE_DESC=$(echo "{
  \"architecture\": \"x86_64\",
  \"cloudImageId\": \"$AMI_ID\",
  \"cloudInitInstalled\": true,
  \"cloudLocation\": \"$LOCATION\",
  \"cloudPlatform\": \"$PLATFORM\",
  \"name\": \"$AMI_NAME\", 
  \"os\": {\"id\": \"ubuntu-16-04\"}, 
  \"scalrAgentInstalled\": true, 
  \"type\": \"ebs\"
}" | scalr-ctl account images register --stdin | ruby -e 'require "yaml"; require "json"; puts JSON.dump(YAML.load(STDIN.read))')

# Replacing previous image, which is registered in a given Role
echo "Image created in Scalr, registering in the Role."
ROLE_ID=83045
NEW_IMAGE_ID=$(echo "$NEW_IMAGE_DESC" | jq -r '.id')

OLD_IMGS=$(scalr-ctl account role-images list --roleId $ROLE_ID --json | jq -r '.data[].image.id')
IMG_FOUND=0
# Finding the image to replace, which is the image with the same platform and cloud location in the given Role
for OIMG in $OLD_IMGS; do
    OLD_IMAGE_DESC=$(scalr-ctl account images get --imageId $OIMG --json)
    OLD_PLATFORM=$(echo $OLD_IMAGE_DESC | jq -r '.data.cloudPlatform')
    OLD_LOCATION=$(echo $OLD_IMAGE_DESC | jq -r '.data.cloudLocation')
    if [[ $OLD_PLATFORM == $PLATFORM && $OLD_LOCATION == $LOCATION ]]; then
        echo "Image to replace found: $OIMG. Removing and deprecating it."
        # Replacing the old image in the same location with the new one, and deprecating the old one
        scalr-ctl account images replace --imageId $OIMG --newImageId $NEW_IMAGE_ID --deprecateOldImage --scope account
        IMG_FOUND=1
        break
    fi
done

# No image found in the same location, associating this one to the role
if [[ $IMG_FOUND == 0 ]]; then
    echo "No previous Image in this location for this Role. Adding this Image to the Role."
    echo "{
        \"image\": {
            \"id\": \"$NEW_IMAGE_ID\"
        },
        \"role\": {
            \"id\": $ROLE_ID
        }
    }" | scalr-ctl account role-images create --roleId $ROLE_ID --stdin
fi

# Cleanup
kitchen destroy $KITCHEN_INSTANCE

exit 0

