#!/bin/bash
set -e

#
# local basic functions
#
function die {
        logger -s -t "$0" "ERROR: $@"
        echo "$@"
        exit 1
}

# default values
MYDIR=${0%%/post.sh}

. /etc/svnmock.conf || die "ERROR: /etc/svnmock.conf not existing!"


time rsync -av --delete-after --delay-updates -e ssh --progress --stats ${RESULTDIR}/ ${RSYNC_DEST}
