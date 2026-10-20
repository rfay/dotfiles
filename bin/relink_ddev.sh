#!/bin/bash

#set -x
set -o errexit

BIN_DIR="$PWD/.gotmp/bin/$(go env GOHOSTOS)_$(go env GOHOSTARCH)"
# If this is executed in a ddev repo, link to that repo
if [ -f ${BIN_DIR}/ddev ]; then
  echo "Linking to ddev in ${BIN_DIR}"
  ln -sf ${BIN_DIR}/ddev ~/bin/ddev
  ln -sf ${BIN_DIR}/ddev-hostname ~/bin/ddev-hostname
else
  echo "Linking to ddev in ~/workspace/ddev"
  ln -sf "${HOME}/workspace/ddev/.gotmp/bin$(go env GOHOSTOS)_$(go env GOHOSTARCH)/ddev" ~/bin/ddev
  ln -sf "${HOME}/workspace/ddev/.gotmp/bin$(go env GOHOSTOS)_$(go env GOHOSTARCH)/ddev-hostname" ~/bin/ddev-hostname
fi
