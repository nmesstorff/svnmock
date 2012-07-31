# svnmock
=======
This is a PoC of using a subversion infrastructure to build (staged) RPM's with mock.
I was inspired from http://yadt-project.org and see it as extension in integrated system management with YADT.

## Files
 * svnmock.sh: SVN post-commit hook
 * post.sh: post hook used by svnmock.sh to take care of RPM repos (createrepo...)
 * schema.txt and packages/: show you how to organize the SVN repo.
Simply create a directory for each RPM package with SPECS and SOURCES subdirs as you would do it with rpmbuild. Doesn't know if we actually need these subdirs, but it feels comfortable. Still a PoC :o)

## Quickstart
 * <code>yum install subversion mock createrepo</code>
 * add the svn user to mock group. If you use mod_dav_svn: <code>/usr/sbin/usermod -a -G mock apache</code>
 * Download svnmock.sh to /usr/local/bin/svnmock.sh
 * Create /etc/svnmock.conf:
  <code>
RESULTDIR="/opt/svnmock/result"
MOCKCONFDIR="/etc/mock"

BASEURL="http://$(hostname --fqdn)/svnmock"	
  </code>
 * (maybe) modify your local mock configuration
 * <code>svnadmin create /opt/svn/testrepo</code>
 * <code>ln -s /usr/local/bin/svnmock.sh /opt/svn/testrepo/hooks/post-commit</code>
 * checkout the new repo
 * create directories <code>mkdir mypackage/testing/{SPECS,SOURCES}</code>
 * put in your .spec file and sources
 * commit your stuff
 * look at /opt/svnmock/result/{repos,testing}

Logging via syslog and via $RESULTDIR/{repos,$YOUR_STAGES}/LOGS/*
