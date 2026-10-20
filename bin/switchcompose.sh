#!/bin/bash

# Switch DDEV docker-compose version

ddev config global --required-docker-compose-version=$1
if [ -f ~/.ddev/bin/docker-compose.$1 ]; then
  cp ~/.ddev/bin/docker-compose.$1 ~/.ddev/bin/docker-compose
else 
  echo "no prepped docker-compose version found for $1"
fi
