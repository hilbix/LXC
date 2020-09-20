#!/bin/bash
#
#U Usage:
#U	Unprivileged LinuX Containers initial setup
#U	Other commands implicitely invoke this if needed.
#U
#U	In future you might be able to change some parameters interactively
#U	- For now this here is fully automatic.
#U	- For now it only works from scratch.
#U	- In that case, just do, what it says, to get it up and running.
#U
#U	As always, think first, as everything you do is AT YOUR OWN RISK!
#
# This Works is placed under the terms of the Copyright Less License,
# see file COPYRIGHT.CLL.  USE AT OWN RISK, ABSOLUTELY NO WARRANTY.

ME="$(readlink -e -- "$0")" || exit
. "${ME%/*/*}/lxc-inc/lxc.inc" || exit

STDERR note: It is likely that setup is still missing some bits.
finish

