CLEARPRESSMAJOR ?= $(shell svn info | grep Revision | cut -d\  -f 2)
CLEARPRESSMINOR ?= 1
RELEASE         ?= $(shell whoami)

machine    = $(shell uname -m)
servername = $(shell uname -n)
OS         = $(shell uname -s)

arch = $(machine)

ifeq ($(arch), x86_64)
	arch := amd64
endif

all:	setup
	./Build

setup:	manifest
	perl Build.PL

manifest: bin cgi-bin examples lib t Build.PL Makefile
	find . -type f | grep -vE 'DS_Store|git|_build|META|Build|cover_db|svn|blib|\~|\.old|CVS|build.tap|tap.harness|spec|rpmbuild' | sed 's/^\.\///' | sort > MANIFEST
	[ -f Build.PL ] && echo "Build.PL" >> MANIFEST
	[ -f spec.header ] && echo "spec.header" >> MANIFEST

clean:	setup
	./Build clean
	[ ! -e build.tap ]  || rm -f build.tap
	[ ! -e MYMETA.yml ] || rm -f MYMETA.yml
	[ ! -d _build ]     || rm -rf _build
	[ ! -e Build ]      || rm -f Build
	[ ! -d rpmbuild ]   || rm -rf rpmbuild
	[ ! -e spec ]       || rm -f spec
	[ ! -e tmp ]        || rm -rf tmp
	touch clearpress.rpm clearpress.deb
	rm clearpress*rpm
	rm clearpress*deb

test:	setup
	TEST_AUTHOR=1 ./Build test verbose=1

cover:	setup
	./Build testcover verbose=1

install:	setup
	./Build install

dist:	setup
	./Build dist

rpm:	clean manifest
	cp spec.header spec
	perl -i -pe 's/CLEARPRESSMAJOR/$(CLEARPRESSMAJOR)/g' spec
	perl -i -pe 's/CLEARPRESSMINOR/$(CLEARPRESSMINOR)/g' spec
	perl -i -pe 's/RELEASE/$(RELEASE)/g' spec
	perl -i -pe 's/PREFIX/$(PREFIX)/g' spec
	mkdir -p rpmbuild/BUILD rpmbuild/RPMS rpmbuild/SOURCES rpmbuild/SPECS rpmbuild/SRPMS
	perl Build.PL
	./Build dist
	mv ClearPress*gz rpmbuild/SOURCES/clearpress-$(RELEASE)-$(CLEARPRESSMAJOR)-$(CLEARPRESSMINOR).tar.gz
	cp rpmbuild/SOURCES/clearpress-$(RELEASE)-$(CLEARPRESSMAJOR)-$(CLEARPRESSMINOR).tar.gz rpmbuild/BUILD/
	rpmbuild -v --define="_topdir `pwd`/rpmbuild" \
		    --buildroot `pwd`/rpmbuild/clearpress-$(RELEASE)-$(CLEARPRESSMAJOR)-$(CLEARPRESSMINOR)-root \
		    --target=$(arch)-redhat-linux        \
		    -ba spec
	cp rpmbuild/RPMS/*/clearpress*.rpm .

deb:	rpm
	fakeroot alien  -d clearpress-$(RELEASE)-$(CLEARPRESSMAJOR)-$(CLEARPRESSMINOR).$(arch).rpm
