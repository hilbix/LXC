#!/bin/bash
#
#U Usage: {ARG0}
#U	LXC setup
#U	In future you might be able to change some parameters interactively
#U	For now this here is fully automatic.
#U	For now it only works from scratch.
#U	In that case, just do, what it says, to get it up and running.
#U	But, as always, USE AT OWN RISK!

ME="$(readlink -e -- "$0")" || exit
. "${ME%/*/*}/lxc-inc/lxc.inc" || exit

OOPS setup not yet implemented
