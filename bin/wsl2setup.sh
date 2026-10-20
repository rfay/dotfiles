#!/bin/bash

# Set up WSL2 thingies


# Keychain
if command -v keychain >/dev/null ; then
  keychain -q --nogui $HOME/.ssh/id_rsa
  source $HOME/.keychain/$HOSTNAME-sh
fi

# Services
sudo service docker start
sudo service ssh start
