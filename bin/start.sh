#!/bin/bash
#
#U Usage: CONTAINER
#U	Start CONTAINER
#
# This Works is placed under the terms of the Copyright Less License,
# see file COPYRIGHT.CLL.  USE AT OWN RISK, ABSOLUTELY NO WARRANTY.

LXC_ARGS=1
ME="$(readlink -e -- "$0")" || exit
. "${ME%/*/*}/lxc-inc/lxc.inc" || exit

LXCcontainer "$1"

# I am not convinced that this is correct.  I am puzzled because
# when logging is on WARN something like following can be seen:
# start - start.c:lxc_spawn:1758 - Operation not permitted - Failed to allocate new network name
# Can this be ignored?  If so, why is it a warning and not a notice?
lxc-start -n "$LXC_CONTAINER" && LXCexit

WARN verbose retry due to error code $?: lxc-start "$LXC_CONTAINER"

ov WTF mktemp -d
o test -d "$WTF"
lxc-start -n "$LXC_CONTAINER" -L "$WTF/console" -l INFO -o "$WTF/log"
err=$?
cat "$WTF/console" "$WTF/log"
rm -rf "$WTF"

[ 0 = "$err" ] || ERR error code $err: lxc-start "$LXC_CONTAINER"

LXCexit

