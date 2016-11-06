# image_publishing
Example image publishing pipeline using test-kitchen

This repository contains a trivial chef cookbook, a few tests to check that this cookbook has the intended
result, and a script that uses test-kitchen with the kitchen-scalr driver to launch a server, run a recipe
on this server, run the tests, and if they pass, snapshot the server and publish the resulting image at
the Account scope in Scalr.

### Requirements

The test_and_publish.sh script assumes that
 - test-kitchen
 - scalr-ctl
 - the aws CLI tools
are installed and setup.
The aws CLI tools are used to snapshot the server.
