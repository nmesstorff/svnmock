#!/bin/bash
#set -x
# Startup check
REPO="$1"
REV=$2
RESULTDIR="/data/result"

if [ -z "${REPO}" ]; then
	REPO=/Users/normes/svn/mocktest.svn/
	REV=22
fi
REPO="${REPO}/"
TMPDIR=${REPO}tmp

shopt -s nullglob

#
# local basic functions
#
function log {
        logger -t "$0" "$@"
        echo "$@"
}

function die {
        logger -s -t "$0" "ERROR: $@"
        echo "$@"
        exit 1
}


#
# prepare envireonment
#
log starting "$REPO" "$REV"

mkdir -p ${TMPDIR} ${RESULTDIR}
cd ${TMPDIR} || "Could not cd into ${TMPDIR}"
# prevent us to NOT delete the whole hdd :)
if [ ${#TMPDIR} -gt 5 ]; then
	rm -rf ${TMPDIR}/*
else
	die "problems with TMPDIR (${TMPDIR})!"
fi


# 
# check changed repos
#
REPOS=()
for repository in `svnlook dirs-changed --revision ${REV} "${REPO}"`; do
	currentrepo=${repository%%/*}
	
	# check duplicate values
	duplicated=false
	for dup in ${REPOS[@]}; do
		if [ "${dup}" == "${currentrepo}" ]; then
			duplicated=true
			break;
		else
			continue;
		fi
	done
	
	# add value to array
	if [ $duplicated == false ]; then
		log " * repo changed: '${currentrepo}'"
		REPOS=("${REPOS[@]}" "${currentrepo}")
	fi
done


#
# working thru changed packages in all repos
#
for repository in ${REPOS[@]}; do
	#
	# changed packages
	#
	PACKAGES=()
	for package in `svnlook dirs-changed --revision ${REV} "${REPO}"`; do
		currentpkg=${package##$repository/}
		currentpkg=${currentpkg%%/*}
				
		log " * package changed: '${repository}/${currentpkg}'"
		PACKAGES=("${PACKAGES[@]}" "${currentpkg}")
	done
	
	#
	# svn export into TMPDIR
	#
	echo ${PACKAGES}
	for package in ${PACKAGES[@]}; do
		svn export -r $REV file:///"$REPO""${repository}/""${package}"/ --force
		mkdir -p "${package}"/{RPMS,SRPMS}
		log "  . building SRPM '${repository}/${package}'"
		mock --resultdir="${package}"/SRPMS/ --buildsrpm --spec "${package}"/SPECS/"${package}".spec --source "${package}"/SOURCES/
		RET=$?
		log "  . [DONE=${RET}] building SRPM '${repository}/${package}'"
		log "  . building binary RPM '${repository}/${package}'"
		mock --resultdir="${package}"/RPMS/  --rebuild "${package}"/SRPMS/*.src.rpm
		RET=$?
		log "  . [DONE=${RET}] building binary RPM '${repository}/${package}'"
		mv "${package}"/{RPMS,SRPMS} ${RESULTDIR}
	done
done

exit $?
