#!/bin/bash
#
#U Usage: CMD ARGS..
#U	Run container command {PATH}/bin/CMD.sh
#U	Example: {ARG0} help
#
# This Works is placed under the terms of the Copyright Less License,
# see file COPYRIGHT.CLL.  USE AT OWN RISK, ABSOLUTELY NO WARRANTY.

ME="$(readlink -e -- "$0")" || exit
. "${ME%/*/*}/lxc-inc/lxc.inc" || exit

[ 0 = $# ] && Usage
o check-name "$1" invalid command name
[ -x "$BASE/bin/$1.sh" ] || OOPS unknown command: "$1"

LXC_USAGE="${0##*/} $1" exec "$BASE/bin/$1.sh" "${@:2}"

