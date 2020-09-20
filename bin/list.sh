#!/bin/bash
#
#U Usage:
#U	List all containers
#
# This Works is placed under the terms of the Copyright Less License,
# see file COPYRIGHT.CLL.  USE AT OWN RISK, ABSOLUTELY NO WARRANTY.

ME="$(readlink -e -- "$0")" || exit
. "${ME%/*/*}/lxc-inc/lxc.inc" || exit

for a in "$BASE"/LXC/*/config
do
	[ -s "$a" ] || continue
	b="${a%/config}"
	b="${b##*/}"
	echo "$b"
done
exit $MURX

