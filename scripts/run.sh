#!/bin/sh

RUBY=/Users/koji/.rbenv/versions/1.9.3-p448/bin/ruby
BASE=/Users/koji/workspace/FXAnalyzer/apps
FX=${BASE}/bin/FX.rb

${RUBY} ${FX}
cp -r ${BASE}/result ~/Dropbox