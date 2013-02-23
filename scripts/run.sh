#!/bin/sh

RUBY=ruby
BASE=../apps
FX=${BASE}/bin/FX.rb

${RUBY} ${FX}
cp -r ../result ~/Dropbox