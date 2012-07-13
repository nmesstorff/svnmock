all:
	@echo "Targets:"
	@echo " * tgz - create a svnmock-XX.YY.tar.gz"

tgz:
	tar --exclude .git --exclude .gitignore -cvzf example_svn/svnmock/stable/SOURCES/svnmock-0.1.tar.gz src TODO README.md schema.txt
