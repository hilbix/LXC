#!/bin/bash
#
#U Usage: CONTAINER CMD ARGS..
#U	Execute CMD with ARGS as root within stopped CONTAINER.
#U	If the container is started (or another "exec" runs)
#U	this command fails with "Address already in use" error!
#U
#U	In contrast to the command "run", no environment can be passed.
#U	!WARNING!
#U	It does not protect your terminal against the TIOCSTI exploit either!
#U
#U	Not yet implemented:
#U	- Option to wait until no other "exec" runs (exclusive locking).
#
# This Works is placed under the terms of the Copyright Less License,
# see file COPYRIGHT.CLL.  USE AT OWN RISK, ABSOLUTELY NO WARRANTY.

LXC_ARGS=2-
ME="$(readlink -e -- "$0")" || exit
. "${ME%/*/*}/lxc-inc/lxc.inc" || exit

LXCcontainer "$1"
shift
exec lxc-execute -n "$LXC_CONTAINER" -- "$@"

