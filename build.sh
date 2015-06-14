#!/bin/bash

# Path to pub package manager, because it might not be in PATH.
export PUB=pub
if [ ! $(which pub) ]; then
  export PUB=/usr/lib/dart/bin/pub
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

# Install dependencies.
if [ ${#dependencies[@]} != 0 ]; then
  apt-get update
  apt-get install ${dependencies[@]}
fi

# Download additional dependencies.
$PUB get

# Compile to JavaScript.
$PUB build

echo 'Built web application successfully!'

exit 0
