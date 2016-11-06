# image_publishing

Example image publishing pipeline using test-kitchen

This repository contains a trivial chef cookbook, a few tests to check that this cookbook has the intended
result, and a script that uses test-kitchen with the kitchen-scalr driver to launch a server, run a recipe
on this server, run the tests, and if they pass, snapshot the server and publish the resulting image at
the Account scope in Scalr. It will then add this Image to a predefined Role, replacing any previous Image
in the same location.

Test-kitchen is used here as a convenient way to launch a Server in Scalr and run a Chef cookbook on it,
but you could replace it with the scalr-ctl command line tool, or with the provisioning tool of your choice.

### Using the script with your Scalr install

Make sure you installed the requirments (see below).

Edit the `.kitchen.yml`, in particular the "platform" section, to your Scalr installation.
Edit the `test_and_publish.sh` script. You will likely have to change the `KITCHEN_INSTANCE`, `OS`, 
`ROLE_ID` and `AMI_NAME` (which is used both for the AMI name in EC2 and the image name in Scalr) variables.

### Next steps

If you want to use this process as-is, the next step is simply to add a real chef cookbook here, write
associated tests, and potentially customize the configuration to build more than 1 image. You could also
modify the script to publish the Images in more than one location.

### Requirements

The `test_and_publish.sh` script assumes that
 - jq (a simple command line tool to handle JSON objects)
 - test-kitchen
 - scalr-ctl
 - the aws CLI tools
are installed and setup.

The aws CLI tools are used to snapshot the server.

