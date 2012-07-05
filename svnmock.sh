#!/bin/bash
#set -x
shopt -s nullglob

# default values
REPO="$1"
REV=$2
REPO="${REPO}/"
TMPDIR=${REPO}tmp
RESULTDIR="/data/result"


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
# prepare environment
#
log starting "$REPO" "$REV"
mkdir -p ${TMPDIR}
cd ${TMPDIR} || "Could not cd into ${TMPDIR}"

# prevent us to NOT delete the whole hdd :)
if [ ${#TMPDIR} -gt 5 ]; then
	rm -rf ${TMPDIR}/*
else
	die "problems with TMPDIR (${TMPDIR})!"
fi


#
# check changed packages
#
BUILD=()
for package in `svnlook dirs-changed --revision ${REV} "${REPO}"`; do
	# package
	currentpkg=${package%%/*}
	
	# repo
	currentrepo=${package##$currentpkg/}
	currentrepo=${currentrepo%%/*}
	
	# buildlist
	if [ -z "${BUILD}" ]; then
		BUILD=("${currentpkg}/${currentrepo}")
	fi
	
	for dup in ${BUILD[@]}; do
		if [ "${dup}" == "${currentpkg}/${currentrepo}" ]; then
			continue;
		else
			BUILD=("${BUILD[@]}" "${currentpkg}/${currentrepo}")
			break;
		fi
	done
done
log " * changed packages: ${BUILD[@]}"


#
# build changed packages
#
for target in ${BUILD[@]}; do
	log "*-* build target: $target"
	pkgname=${target%%/*}
	reponame=${target##$pkgname/}
	logprefix="${pkgname}_${reponame}_r${REV}_"
	
	# svn export into TMPDIR
	mkdir -p "${target}"/{RPMS,SRPMS,LOGS}
	svn export -r $REV file:///"$REPO""${target}"/ ${target}  --force &> ${target}/LOGS/${logprefix}svn_export.log

	# building SRPM with mock	
	log "  . building SRPM '${target}'"
	mock --resultdir="${target}"/SRPMS/ --buildsrpm --spec "${target}"/SPECS/"${pkgname}".spec --source "${target}"/SOURCES/ &> ${target}/LOGS/${logprefix}mock_srpm.log
	RET=$?
	log "  . [DONE=${RET}] building SRPM '${target}' in ${TMPDIR}"
	if [ ${RET} != 0 ]; then
		die "Could not build '${target}'"
	fi
	
	# building RPM with mock
	log "  . building binary RPM '${target}'"
	mock --resultdir="${target}"/RPMS/  --rebuild "${target}"/SRPMS/*.src.rpm &> ${target}/LOGS/${logprefix}mock_rpm.log
	RET=$?
	log "  . [DONE=${RET}] building binary RPM '${target}' in ${TMPDIR}"
	if [ ${RET} != 0 ]; then
		die "Could not build '${target}'"
	fi
	
	# move stuff into RESULTDIR
	mkdir -p ${RESULTDIR}/${reponame}/{LOGS,SRPMS,RPMS}
	mv ${target}/LOGS/* ${RESULTDIR}/${reponame}/LOGS/
	mv ${target}/SRPMS/*.rpm ${RESULTDIR}/${reponame}/SRPMS/
	mv ${target}/RPMS/*.rpm	${RESULTDIR}/${reponame}/RPMS/
done

# running post-hook (createrepo...)
if [ -x ${RESULTDIR}/post.sh ]; then
	${RESULTDIR}/post.sh ${reponame}
fi

exit $?
