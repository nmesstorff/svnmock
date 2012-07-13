all:
	@echo "Targets:"
	@echo " * tgz - create a svnmock-XX.YY.tar.gz"

tgz:
	tar --exclude .git --exclude .gitignore -C ../ -cvzf ../svnmock-0.1.tar.gz svnmock
