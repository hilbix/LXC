#!/bin/bash
#
#U Usage: {ARG0} CMD ARGS..
#U	This runs {PATH}/CMD.sh ARGS..
#U	where:
#U	CMD is a container command
#U	ARGS.. are additional arguments to the command
#U	For all possible commands run: {ARG0} help

ME="$(readlink -e -- "$0")" || exit
. "${ME%/*/*}/lxc-inc/lxc.inc" || exit

[ 0 = $# ] && Usage
o check-name "$1" invalid command name
[ -x "$BIN/$1.sh" ] || OOPS unknown command: "$1"

LXC_USAGE="${ME##*/} $1" exec "$BIN/$1.sh" "${@:2}"

