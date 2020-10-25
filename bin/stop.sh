#!/bin/bash
#
#U Usage: CONTAINER
#U	Stop CONTAINER
#
# This Works is placed under the terms of the Copyright Less License,
# see file COPYRIGHT.CLL.  USE AT OWN RISK, ABSOLUTELY NO WARRANTY.

LXC_ARGS=1
ME="$(readlink -e -- "$0")" || exit
. "${ME%/*/*}/lxc-inc/lxc.inc" || exit

LXCcontainer "$1"

lxc-stop -n "$LXC_CONTAINER" && LXCexit
WARN error code $?: lxc-stop "$LXC_CONTAINER"

LXCexit

