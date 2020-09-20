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

ME="$(readlink -e -- "$0")" || exit
. "${ME%/*/*}/lxc-inc/lxc.inc" || exit

LIST=()
for a
do
	o check-name "$a"
	b="$BASE/LXC/$a/config"
	[ -s "$b" ] || WARN cannot find "$b" || continue
	LIST+=("$b")
done

settings SET "${LIST[@]}"

for a in "${PARAM0[@]}" "${PARAM1[@]}"
do
	b="SET_$a"
	printf '%12s = %q\n' "LXC_$a" "${!b}"
done

