svnmock
=======
This is a PoC of using a subversion infrastructure to build (staged) RPM's with mock.
I was inspired from http://yadt-project.org and see it as extension in integrated system management with YADT.

svnmock.sh: SVN post-commit hook
post.sh: post hook used by svnmock.sh to take care of RPM repos (createrepo...)
schema.txt and packages/: show you how to organize the SVN repo. simply create a directory for each RPM package with SPECS and SOURCES subdirs as you would do it with rpmbuild. Doesn't know if we actually need these subdirs, but it feels comfortable. Still a PoC :o)
