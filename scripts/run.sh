#!/bin/sh
###################################################
#
# All Run Shell Script
#
###################################################
./run_FXAnalyzer.sh
if [ $? -eq 0 ] ; then
    ./run_FXViewer.sh
fi

