#!/bin/bash
#
#U Usage: CONTAINER CMD ARGS..
#U	Run CMD with ARGS as root within CONTAINER
#U	Options are passed via environment.
#U	This returns the return value of CMD.
#U	If fails if CONTAINER is not started.
#U
#U	Environment variables which start with the prefix RUN_
#U	or are listed in the comma or blank separated list LXC_ENV
#U	are available inside the container.  LXC_ENV='*' for all.
#U
#U	Example to change owner of /tmp/file to your user:
#U		LXC_UID=1 LXC_GID=1 {CMD} CONTAINER chown 1:1 /tmp/file
#U	This examples DOES NOT WORK yet, as LXC_UID is not yet supported!
#
# This Works is placed under the terms of the Copyright Less License,
# see file COPYRIGHT.CLL.  USE AT OWN RISK, ABSOLUTELY NO WARRANTY.

LXC_ARGS=1-
ME="$(readlink -e -- "$0")" || exit
. "${ME%/*/*}/lxc-inc/lxc.inc" || exit

LXCcontainer "$1"
shift

ARGS=()
if [ '.*' != ".$LXC_ENV" ]
then
	ARGS+=(--clear-env)
	for a in ${!RUN_*} ${LXC_ENV//,/ }
	do
		ARGS+=(--keep-var "$a")
	done
fi
exec lxc-attach -n "$LXC_CONTAINER" "${ARGS[@]}" -v debian_chroot="$LXC_CONTAINER" -- "$@"

