all:	setup
	./Build

setup:	manifest
	perl Build.PL

manifest: bin cgi-bin data examples lib t Build.PL Makefile
	find . -type f | grep -vE 'DS_Store|git|_build|META.yml|Build|cover_db|svn|blib|\~|\.old|CVS|build.tap|tap.harness' | sed 's/^\.\///' | sort > MANIFEST
	[ -f Build.PL ] && echo "Build.PL" >> MANIFEST

clean:	setup
	./Build clean
	[ ! -e build.tap ]  || rm -f build.tap
	[ ! -e MYMETA.yml ] || rm -f MYMETA.yml
	[ ! -d _build ]     || rm -rf _build
	[ ! -e Build ]      || rm -f Build

test:	setup
	TEST_AUTHOR=1 ./Build test verbose=1

cover:	setup
	./Build testcover verbose=1

install:	setup
	./Build install

dist:	setup
	./Build dist
