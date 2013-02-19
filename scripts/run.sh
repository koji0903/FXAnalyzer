#!/bin/sh

RUBY=ruby
BASE=../apps
FX=${BASE}/bin/FX.rb


# Execute
${RUBY} ${FX}


# Copy result
cp -r ../result ~/Dropbox