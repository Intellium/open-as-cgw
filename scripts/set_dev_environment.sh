#!/bin/bash
# This script is intended to set the needed environment variables
# for an Open AS developer environment

echo '+ Appending variables to your ~/.bashrc...'
echo '' >> ~/.bashrc
echo '# Open AS developer environment' >> ~/.bashrc
echo 'export LIMESDEV=1' >> ~/.bashrc
echo 'export LIMESLIB="'$(dirname $(pwd))'/lib"' >> ~/.bashrc
echo 'export LIMESGUI="'$(dirname $(pwd))'/gui/lib"' >> ~/.bashrc
echo '+ Done! Please exit and re-login to your current shell!'
