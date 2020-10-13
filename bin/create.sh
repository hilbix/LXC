#!/bin/bash
#
#U Usage: CONTAINER [TEMPLATE]
#U	Create a CONTAINER from a TEMPLATE
#U	- If TEMPLATE is missing, CONTAINER is used as TEMPLATE
#U	- If CONF/lxc-CONTAINER.config is missing, it is created from CONF/lxc-CONTAINER.conf
#U	- If CONF/lxc-CONTAINER.conf is missing, it is created from CONF/lxc-TEMPLATE.conf
#U	- If CONF/lxc-TEMPLATE.conf is missing, it is created from CONF/default.conf
#U	- If CONF/default.conf is missing, it is created from /etc/lxc/default.conf
#U
#U	Container parameters are:
#U	- taken from the template or the defaults
#U	- can be overwritten in the environment.
#U	To list the parameters use 'diag' command
#
# This Works is placed under the terms of the Copyright Less License,
# see file COPYRIGHT.CLL.  USE AT OWN RISK, ABSOLUTELY NO WARRANTY.

LXC_ARGS=1-2
ME="$(readlink -e -- "$0")" || exit
. "${ME%/*/*}/lxc-inc/lxc.inc" || exit

# get commandline args, else present usage
o LXCcontainer "$1"
o LXCtemplate "${2:-$1}"

# Do the install
# (this perhaps is not elaborate enough yet and might change/improve in future)
o LXCsettings-create
o LXCcontainer-setup
o settings-print
o LXCcontainer-mmdebstrap

LXCexit

