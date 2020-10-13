#!/bin/bash
#
#U Usage:
#U	List all containers
#
# This Works is placed under the terms of the Copyright Less License,
# see file COPYRIGHT.CLL.  USE AT OWN RISK, ABSOLUTELY NO WARRANTY.

LXC_ARGS=0
ME="$(readlink -e -- "$0")" || exit
. "${ME%/*/*}/lxc-inc/lxc.inc" || exit

len=0
for a in "$LXC_BASE"/LXC/*/config
do
	[ -s "$a" ] || continue
	b="${a%/config}"
	b="${b##*/}"
	state="$(lxc-info -n "$b" -Hs)"
	ip="$(lxc-info -n "$b" -Hi)"
	printf -vc "name=%q state=%q ip=%q" "$b" "$state" "$ip"
	MACH+=("$c")
	[ "$len" -lt "${#b}" ] && len="${#b}"
done

for a in "${MACH[@]}"
do
	eval "$a"
	printf "%*q %q %q\n" "$len" "$name" "$state" "$ip"
done

LXCexit

