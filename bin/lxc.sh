#!/bin/bash
#
#U Usage: CMD ARGS..
#U	Run container command {PATH}/bin/CMD.sh
#U	Example: {CMD} help
#
# This Works is placed under the terms of the Copyright Less License,
# see file COPYRIGHT.CLL.  USE AT OWN RISK, ABSOLUTELY NO WARRANTY.

LXC_ARGS=1-
ME="$(readlink -e -- "$0")" || exit
. "${ME%/*/*}/lxc-inc/lxc.inc" || exit

o LXCvalid "$1" invalid command name
o LXClocate CMD "$1"
[ -x "$CMD" ] || OOPS unknown command: "$1"

LXC_WRAPPER="${0##*/}" LXC_USAGE="$LXC_WRAPPER $1" exec "$LXC_BASE/bin/$1.sh" "${@:2}"

