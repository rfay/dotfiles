#!/bin/bash

set -x
set -o errexit

brewprefix="$(brew --prefix)"
rm -f ~/bin/ddev ~/bin/ddev-hostname*
if [ -f "${brewprefix}/bin/ddev" ]; then
  ln -sf "${brewprefix}/bin/ddev" ~/bin/ddev
fi
if [ -f "${brewprefix}/bin/ddev-hostname" ]; then
  ln -sf "${brewprefix}/bin/ddev-hostname" ~/bin/ddev-hostname
fi
# (brew unlink ddev/ddev/ddev || true) && brew link ddev/ddev/ddev || brew install ddev/ddev/ddev
