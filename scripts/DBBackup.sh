#!/bin/sh

LS='ls'
CP='cp -r'
 
DATE=`date +"%Y-%m-%d"`

${CP} ../FX_DB ../DB_Backup/FX_DB_${DATE}
echo "make backup db file(FX_DB_${DATE})"