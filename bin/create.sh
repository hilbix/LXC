#!/bin/bash
#
#U Usage: CONTAINER [TEMPLATE]
#U	Create a CONTAINER from a TEMPLATE
#U	- If TEMPLATE is missing, CONTAINER is used as TEMPLATE
#U	- If CONF/lxc-CONTAINER.config is missing, it is created from CONF/lxc-CONTAINER.conf
#U	- If CONF/lxc-CONTAINER.conf is missing, it is created from CONF/lxc-TEMPLATE.conf
#U	- If CONF/lxc-TEMPLATE.conf is missing, it is created from CONF/default.conf
#U	- If CONF/default.conf is missing, it is created from /etc/lxc/default.conf
#U
#U	Container parameters are:
#U	- taken from the template or the defaults
#U	- can be overwritten in the environment.
#U	To list the parameters use 'diag' command
#
#	# Default: root.  In Linux the first user usually is 1000/1000
#	LXC_UID=0
#	LXC_GID=0
#	# Parameters to mmdebstrap, see man mmdebstrap
#	LXC_SUITE=buster
#	LXC_VARIANT=minbase
#	LXC_MIRROR=http://deb.debian.org/debian/
#	# Additional comma separated parameters to mmdebstrap:
#	## Keys to use for apt-get to check the signatures
#	LXC_KEYS=debian-archive-keyring.gpg
#	## List of additional packages to install
#	LXC_INCLUDE=vim
#
# This Works is placed under the terms of the Copyright Less License,
# see file COPYRIGHT.CLL.  USE AT OWN RISK, ABSOLUTELY NO WARRANTY.

ME="$(readlink -e -- "$0")" || exit
. "${ME%/*/*}/lxc-inc/lxc.inc" || exit

# get commandline args, else present usage
CONTAINER="$1"
SETTINGS="${2:-$1}"

[ -n "$SETTINGS" ] || Usage


# Do the install
# (this perhaps is not elaborate enough yet and might change/improve in future)
o settings-read-or-create "$BASE/CONF/lxc-$CONTAINER.config"
o lxc-container-config "$BASE/CONF/lxc-$CONTAINER.config"
o settings-print GET
o lxc-container-mmdebstrap "$BASE/LXC/$CONTAINER/rootfs"

EXIT

