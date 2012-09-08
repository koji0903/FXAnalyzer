#!/bin/sh

BASE=../apps
FX=${BASE}/bin/FXView.rb

########
# EXE
########
ruby ${FX}

########
# COPY
########
#cp -r ../result ~/I-Drive/Koji
cp -r ../result ~/Dropbox
#cp -r ../result/* ~/I-Drive/Koji/FenrirFS\ Storage/Koji.profile/files/


