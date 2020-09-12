# LXC unprivileged containers

This works around several shortcomings of LXC and mmdebstrap:

- The way how to create working unprivileged containers is barely documented.  This here sums it up.
- The mapped UIDs are taken from `~/.config/lxc/default.conf` instead of `/etc/subuid`+`/etc/subgid`
- The latter are registries and can only be changed by `root`
- while `default.conf` can be created by you as you like it.
- `~/.config/lxc/default.conf` is way to complex for normal users, so a default one is provided.

TODO:

- Currently everything is automatic and defined in LXC's `default.conf`.  This should change.

## Usage

	cd
	git clone https://github.com/hilbix/LXC.git
	./gen.sh
	# Follow the menu

Later you can do:

	./gen.sh $CONTAINER ${TYPE:-DEFAULT}


