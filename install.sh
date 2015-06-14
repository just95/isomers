#!/bin/bash

export INSTALL_DIR=/usr/lib/isomers
export SCRIPT=$INSTALL_DIR/bin/isomers.dart

export TARGET=/usr/bin/isomers

# Path to pub package manager if it is not in PATH.
export PUB=pub
if [ ! $(which pub) ]; then
  export PUB=/usr/lib/dart/bin/pub
fi

# Already installed?
if  [ -x $TARGET ] && [ -d $INSTALL_DIR ]; then
  echo 'The application has already been installed!'
  while true; do
    echo 'Do you want to reinstall? [Y/n]'
    read yn
    case $yn in
        [Yy]*|'' ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
  done
fi

# Find missing dependencies.
dependencies=()

if [ ! $(which dart) ]; then
  apt-get update
  apt-get install apt-transport-https

  sh -c 'curl https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -'
  sh -c 'curl https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list'

  dependencies+='dart'
fi

if [ ! $(which dot) ]; then
  dependencies+='graphviz'
fi

if [ ! $(which graph-easy) ]; then
  dependencies+='libgraph-easy-perl'
fi

# Install dependencies.
if [ ${#dependencies[@]} != 0 ]; then
  echo 'Installing dependencies...'
  apt-get update > /dev/null
  apt-get install ${dependencies[@]} > /dev/null
fi

# Copy to install directory.
mkdir -p $INSTALL_DIR
cp -r * $INSTALL_DIR
cd $INSTALL_DIR

# Download additional dependencies.
$PUB get

# Create executable.
# We cannot use pub global because it does not work well with pipes.
# i.e. The application never receives EOF.
echo '#!/bin/bash'        > $TARGET
echo 'dart' $SCRIPT '$@' >> $TARGET
chmod +x $TARGET

# Permit access to directories.
chmod +x bin/ lib/ lib/src lib/src/*

# Create uninstall script.
echo '#!/bin/bash'         > uninstall.sh
echo 'rm' $TARGET         >> uninstall.sh
echo 'rm -r' $INSTALL_DIR >> uninstall.sh
if [ ${#dependencies[@]} != 0 ]; then
  echo 'echo "Removing dependencies..."' >> uninstall.sh
  echo 'apt-get remove' ${dependencies[@]} ' > /dev/null' >> uninstall.sh
fi
chmod +x uninstall.sh

echo 'Installation completed successfully!'

exit 0
