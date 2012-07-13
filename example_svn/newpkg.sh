#!/bin/bash

if [ -z "$2" ]; then
        echo "Usage: $0 [packagename] [reponame]"
        exit 1
fi

mydir=${0%%/newpkg.sh}
mkdir -p "$mydir"/"$1"/"$2"/{SPECS,SOURCES}
echo " [DONE=$?] package $1/$2"
