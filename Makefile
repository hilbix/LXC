#

.PHONY:	love
love:	all

.PHONY:	all
all:	install

.PHONY:	install
install:
	[ -d '$(HOME)/bin' ] || mkdir '$(HOME)/bin'
	ln -s --relative bin/lxc.sh '$(HOME)/bin/LXC'

