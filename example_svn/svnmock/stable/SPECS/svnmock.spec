Name:		svnmock
Version:	0.1
Release:	2%{?dist}
Summary:	SVN hook to build RPMs
Packager:	Norman Meßtorff <normes@normes.org>

Group:		Applications/System
License:	GPL
URL:		https://github.com/nmesstorff/svnmock
Source0:	%{name}-%{version}.tar.gz
BuildRoot:	%(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)

#BuildRequires:	
Requires:	subversion, mock


%description
This is a PoC of using a subversion infrastructure to build (staged) RPM's with mock.
I was inspired from http://yadt-project.org and see it as extension in integrated system management with YADT.

svnmock.sh: SVN post-commit hook
post.sh: post hook used by svnmock.sh to take care of RPM repos (createrepo...)


%prep
%setup -q -c


%build


%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT%{_bindir} $RPM_BUILD_ROOT%{_docdir}/%{name}

cp src/svnmock.sh $RPM_BUILD_ROOT%{_bindir}/%{name}
cp src/post.sh $RPM_BUILD_ROOT%{_docdir}/%{name}

%clean
rm -rf $RPM_BUILD_ROOT


%files
%defattr(755,root,root,-)
%{_bindir}/*
%{_docdir}/%{name}/*.sh

%defattr(-,root,root,-)
%doc README.md TODO schema.txt 


%changelog
* Wed Jul 11 2012 Norman Meßtorff <normes@normes.org> 0.1-1
- initial version
