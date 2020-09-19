#!/bin/bash
#
# Run a command as the container's LXC_UID and LXC_GID
# run.sh container command args..
#
# There are no options:
# - Drop environment
# - Allow all variables LXC_xxx
# - Allow all variables in LXC_ENV

ARGS=()
ARGS+=(--clear-env)
for a in ${LXC_ENV//,/ }
do
	ARGS+=(--keep-var 
done
exec lxc-attach "${ARGS[@]}" -- "$@"

