#!/bin/bash
#
#U Usage: [CONTAINER..]
#U	Show effective LXC environment
#U	If CONTAINER is given the settings of CONTAINER are printed
#U
#U	UID/GID of your user within the container:
#U	LXC_UID=0
#U	LXC_GID=0
#U	Note: Linux containers usually uses 1000/1000 for the first user (you)
#U
#U	Settings for container creation:
#U	LXC_SUITE=buster
#U	LXC_VARIANT=minbase
#U	LXC_SCHEMA=http://
#U	LXC_REPOS=deb.debian.org/debian/
#U	LXC_KEYS=debian-archive-keyring.gpg
#U	LXC_INCLUDE=vim
#U	Notes:
#U	- The last 3 are comma separated lists
#U	- LXC_SCHEMA is prepended to entries in LXC_REPOS
#U	- LXC_SCHEMA can be used to point to apt-cacher-ng (or your mirrors) like:
#U	  LXC_SCHEMA=http://192.168.0.1:3142/
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

cat <<EOF
# UID GID default to: 0 0
#	0 means root.  In Linux the first user usually is 1000 1000
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

