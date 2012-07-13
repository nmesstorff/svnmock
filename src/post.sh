#!/bin/bash

MYDIR=${0%%/post.sh}
REPONAME=$1

if [ -z "${REPONAME}" ]; then
	echo "Usage: $0 [REPONAME]"
	exit 1
fi

createrepo -v --database --update "${MYDIR}/${REPONAME}/RPMS" &> ${MYDIR}/${REPONAME}/LOGS/createrepo.log
