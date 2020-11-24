#!/bin/bash
#
#U Usage: [CONTAINER..]
#U	Show effective LXC environment (--help to explain varaiables)
#U	If CONTAINER is given the settings of CONTAINER are printed
#U
#U	UID/GID of your user within the container:
#U	LXC_UID=-1
#U	LXC_GID=-1
#U	Notes:
#U	- 0 means root, so your user is mapped to root
#U	- Linux containers usually uses 1000/1000 for the first user (you)
#U	- THIS FEATURE DOES NOT WORK YET
#U
#U	Settings for container creation:
#U	LXC_SUITE=buster
#U	LXC_VARIANT=minbase
#U	LXC_SCHEMA=http://
#U	LXC_REPOS=deb.debian.org/debian/
#U	LXC_KEYS=debian-archive-keyring.gpg
#U	LXC_INCLUDE=vim
#U	Notes:
#U	- The last 3 are extensible comma separated lists
#U	- LXC_SCHEMA is prepended to entries in LXC_REPOS
#U	- LXC_SCHEMA can be used to point to apt-cacher-ng (or your mirrors) like:
#U	  LXC_SCHEMA=http://192.168.0.1:3142/
#U
#U	Other settings:
#U	LXC_PRELOAD	LD_PRELOAD while invoking container commands like mmdebstrap
#U	LXC_QUIET	suppresses some default messages
#U	LXC_WRAPPER	used internally
# XXX TODO XXX make it DRY: grab explain from lxc-inc/lxc.inc and defaults from runtime
#
# This Works is placed under the terms of the Copyright Less License,
# see file COPYRIGHT.CLL.  USE AT OWN RISK, ABSOLUTELY NO WARRANTY.

LXC_ARGS=-
ME="$(readlink -e -- "$0")" || exit
. "${ME%/*/*}/lxc-inc/lxc.inc" || exit

LIST=()
for a
do
	LXCcontainer "$a"
	[ -s "$LXC_CONTAINER_CFG" ] || WARN cannot find "$LXC_CONTAINER_CFG" || continue
	LIST+=("$LXC_CONTAINER_CFG")
done

# XXX TODO XXX make it DRY: grab explain from lxc-inc/lxc.inc and defaults from runtime
cat <<EOF
# UID GID default to: -1 -1
#	-1 means do-not-map anything.
#	0 means root.
#	In Linux the first user usually is 1000 1000
#	(This feature does not work yet)
# SUITE VARIANT default to: buster minbase
# SCHEMA REPOS default to: http:// deb.debian.org/debian/
# SCHEMA can be used for something like apt-cacher-ng like in:
#	LXC_SCHEMA=http://192.168.0.1:3142/
# REPOS is a comma separated list, each entry gets SCHEMA appended
# KEYS is a comma separated list and defaults to: debian-archive-keyring.gpg
# INCLUDES is a comma separated list and defaults to: vim
EOF

o settings-get SET "${LIST[@]}"
o settings-print SET

LXCexit

