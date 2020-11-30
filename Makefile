#

.PHONY:	love
love:	all

.PHONY:	all
all:	install

.PHONY:	install
install:
	echo running setup
	bin/setup.sh

