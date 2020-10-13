#!/bin/bash
#
#U Usage: CONTAINER CMD ARGS..
#U	Run CMD with ARGS within CONTAINER
#U	Options are passed via environment.
#U	This returns the return value of CMD
#U
#U	uid/gid defaults to your mapped user in the container
#U	if not overridden with LXC_UID/LXC_GID.
#U
#U	Environment variables which start with the prefix RUN_
#U	or are listed in the comma or blank separated list LXC_ENV
#U	are available inside the container.  LXC_ENV='*' for all.
#U
#U	Example:
#U		LXC_UID=1 LXC_GID=1 {CMD} CONTAINER id
#
# This Works is placed under the terms of the Copyright Less License,
# see file COPYRIGHT.CLL.  USE AT OWN RISK, ABSOLUTELY NO WARRANTY.

ME="$(readlink -e -- "$0")" || exit
. "${ME%/*/*}/lxc-inc/lxc.inc" || exit

[ 0 -lt $# ] || Usage

ARGS=()
if [ '.*' != ".$LXC_ENV" ]
then
	ARGS+=(--clear-env)
	for a in ${LXC_ENV//,/ }
	do
		ARGS+=(--keep-var "$a")
	done
fi
exec lxc-attach "${ARGS[@]}" -v debian_chroot="$1" -- "$@"

