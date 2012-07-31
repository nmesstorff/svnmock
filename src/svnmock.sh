#!/bin/bash
#set -e -x
set -e
shopt -s nullglob

# default values
REPO="$1"
REV="$2"
REPO="${REPO}/"
TMPDIR="${REPO}tmp"
CLEANUP="true"
RESULTDIR="/opt/svnmock/result"
REPOSDIR="svnmock-repos"
MOCKCONFDIR="/etc/mock/"

if [ -z "${REV}" ]; then
        echo "Usage: $0 [SVN repository] [revision]"
        exit 1
fi


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


if [ -e /etc/svnmock.conf ]; then
	. /etc/svnmock.conf
fi


#
# prepare environment
#
log starting "$REPO" "$REV"
mkdir -p ${TMPDIR} ${RESULTDIR}
cd ${RESULTDIR} || die "Could not cd into ${RESULTDIR}"
cd ${TMPDIR} || die "Could not cd into ${TMPDIR}"

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
REPOS=()
for package in `svnlook dirs-changed --revision ${REV} "${REPO}"`; do
	# package
	currentpkg=${package%%/*}
	
	# repo
	currentrepo=${package##$currentpkg/}
	currentrepo=${currentrepo%%/*}
	
	# buildlist
	if [ ! -z ${currentrepo} ]; then
		# worklist
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
		
		# repos
		if [ -z "${REPOS}" ]; then
			REPOS=("${currentrepo}")
		fi
		
		for dup in ${REPOS[@]}; do
			if [ "${dup}" == "${currentrepo}" ]; then
				continue;
			else
				REPOS=("${REPOS[@]}" "${currentrepo}")
				break;
			fi
		done
	fi
done

if [ -z "${BUILD[@]}" ]; then
        log " * no changed packages."
        exit 0
fi

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
	
	# prepare RESULTDIR
	mkdir -p ${RESULTDIR}/${reponame}/{LOGS,SRPMS,RPMS}
	
	# building SRPM with mock	
	log "  . building SRPM '${target}'"
	mock -v --configdir=${MOCKCONFDIR} --resultdir="${target}"/SRPMS/ --buildsrpm --spec "${target}"/SPECS/"${pkgname}".spec --source "${target}"/SOURCES/ &> ${target}/LOGS/${logprefix}mock_srpm.log
	RET=$?
	log "  . [DONE=${RET}] building SRPM '${target}' in ${TMPDIR}"
	if [ ${RET} != 0 ]; then
		die "Could not build '${target}'"
	fi
	
	# building RPM with mock
	log "  . building binary RPM '${target}'"
	mock -v --configdir=${MOCKCONFDIR} --resultdir=${target}/RPMS/ --rebuild ${target}/SRPMS/*.src.rpm &> ${target}/LOGS/${logprefix}mock_rpm.log
	RET=$?
	log "  . [DONE=${RET}] building binary RPM '${target}' in ${TMPDIR}"
	if [ ${RET} != 0 ]; then
		die "Could not build '${target}'"
	fi
	
	# cleanup
	if [ "${CLEANUP}" == "true" ]; then
		log "  . removing old files"
		rm -f ${RESULTDIR}/${reponame}/SRPMS/${pkgname}*.src.rpm ${RESULTDIR}/${reponame}/RPMS/${pkgname}*.rpm ${RESULTDIR}/${reponame}/LOGS/${pkgname}*.log
	fi
	mv ${target}/SRPMS/*.rpm ${RESULTDIR}/${reponame}/SRPMS/
	mv ${target}/LOGS/* ${RESULTDIR}/${reponame}/LOGS/
	mv ${target}/RPMS/*.rpm	${RESULTDIR}/${reponame}/RPMS/
	rm ${RESULTDIR}/${reponame}/RPMS/*.src.rpm
done

for target in ${REPOS[@]}; do
	# createrepo
	log "  . running createrepo in ${RESULTDIR}/${target}/RPMS"
	createrepo -v --database --update "${RESULTDIR}"/${target}/RPMS  &> ${RESULTDIR}/${target}/LOGS/createrepo.log
	log "  . [DONE=$?] createrepo in ${RESULTDIR}/${target}/"

	#
	# check if we have already a .spec file
	#
	if [ ! -e ${RESULTDIR}/${REPOSDIR}/svnmock-${reponame}.spec ]; then
		log "${RESULTDIR}/${REPOSDIR}/svnmock-${reponame}.spec not existing"
		mkdir -p ${RESULTDIR}/${REPOSDIR}/LOGS || die "Could not create ${RESULTDIR}/${REPOSDIR}/LOGS"
		logprefix="${reponame}_r${REV}_"

		echo "Name:           svnmock-${reponame}
Version:        1
Release:        1%{?dist}
Summary:        svnmock dynamic repository ${reponame}

Group:          System Environment/Base
License:        Internal
Vendor:         Internal
BuildRoot:      %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
BuildArch:      noarch
Requires:       yum

%description
svnmock dynamic repository ${reponame}

%prep
echo '[${reponame}]
me=svnmock dynamic repository ${reponame}
baseurl=${BASEURL}/${reponame}/RPMS
gpgcheck=0
enabled=1' > %{name}.repo


%install
rm -rf $RPM_BUILD_ROOT
mkdir -p %{buildroot}/etc/yum.repos.d
install -m 0644 %{name}.repo %{buildroot}/etc/yum.repos.d/

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
/etc/yum.repos.d/%{name}.repo" > ${RESULTDIR}/${REPOSDIR}/svnmock-${reponame}.spec
		
		log "  . building SRPM '${reponame}'"
		mock -v --configdir=${MOCKCONFDIR} --resultdir="${RESULTDIR}"/${REPOSDIR}/ --buildsrpm --spec "${RESULTDIR}"/${REPOSDIR}/svnmock-${reponame}.spec --source "${RESULTDIR}/${REPOSDIR}/" &> ${RESULTDIR}/${REPOSDIR}/LOGS/${logprefix}mock_srpm.log
		RET=$?	
		log "  . [DONE=${RET}] building SRPM '${reponame}' in ${RESULTDIR}/${REPOSDIR}"
		if [ ${RET} != 0 ]; then
			die "Could not build '${reponame}'.repo SRPM"
		fi
		
		# building RPM with mock
		log "  . building binary RPM '${reponame}'"
		mock -v --configdir=${MOCKCONFDIR} --resultdir="${RESULTDIR}"/${REPOSDIR}/  --rebuild "${RESULTDIR}"/${REPOSDIR}/svnmock-${reponame}*.src.rpm --source "${RESULTDIR}/${REPOSDIR}/" &> ${RESULTDIR}/${REPOSDIR}/LOGS/${logprefix}mock_rpm.log
		RET=$?
		log "  . [DONE=${RET}] building binary RPM '${reponame}' in ${RESULTDIR}/${REPOSDIR}"
		if [ ${RET} != 0 ]; then
			die "Could not build '${reponame}'.repo RPM"
		fi
		
		log "  . running createrepo in ${RESULTDIR}/${REPOSDIR}/"
		createrepo -v --database --update "${RESULTDIR}"/${REPOSDIR}/  &> ${RESULTDIR}/${REPOSDIR}/LOGS/createrepo.log
		log "  . [DONE=$?] createrepo in ${RESULTDIR}/${REPOSDIR}/"
	fi
done


#
# running post-hook (rsync...)
#
if [ -x ${RESULTDIR}/post.sh ]; then
	log "  . running post.sh"
	${RESULTDIR}/post.sh ${reponame} &> ${RESULTDIR}/post.log
	RET=$?
	log "  . [DONE=${RET}] post.sh"
fi

exit $?
