#!/bin/bash
#
#U Usage: {ARG0} container [type]
#U	- If settings/type is missing, settings/container is used
#U	- If settings/container is missing, settings/DEFAULT is used

set -C		# noclobber

# calculate default values PREFIX_$name
# They can be overwritten by environment variables LXC_$name
: defaults PREFIX
defaults()
{
local a b
PARAM0=(SUITE VARIANT KEYS REPO INCLUDES)
VALUE0=(buster minbase debian-archive-keyring.gpg http://deb.debian.org/debian/ vim)
PARAM1=(INCLUDES)
VALUE1=(vim)
for a in "${!PARAM0[@]}"
do
	b="_${PARAM0[$a]}"
	eval "$1$b=\"\${LXC$b:-\${VALUE0[\$a]}}\""
done
for a in "${!PARAM1[@]}"
do
	b="_${PARAM1[$a]}"
	eval "$1$b=\"\${LXC$b-\${VALUE1[\$a]}}\""
done
}

# read LXC data from file
: data PREFIX file
data()
{
defaults "$1"	# fills PARAM0 and PARAM1
# read the config into PREFIX_VARIABLE.  Yes, sorry, silly simple for now
o . <(sed -n "s/^#LXC[[:space:]]+/$1_/p" "$2")
# PARAM0: Overwrite PREFIX_VARIABLE with LXC_VARIABLE from the environment
for a in "${!PARAM0[@]}"
do
	b="_${PARAM0[$a]}"
	eval "$1$b=\"\${LXC$b:-\${$1$b:-\${VALUE0[\$a]}}}\""
done
# PARAM1: Create , separated list from PREFIX_VARIABLE and LXC_VARIABLE
for a in "${!PARAM1[@]}"
do
	b="_${PARAM1[$a]}"
	eval "$1$b=\"\$$1$b,\$LXC$b\""
	eval "$1$b=\"\${$1$b#,}\""
done
}

# Quick'n'dirty standards
STDOUT() { local e=$?; printf '%q' "$1"; [ 1 -lt $# ] && printf ' %q' "${@:2}"; printf '\n'; return $e; }
STDERR() { local e=$?; STDOUT "$@" >&2 || exit 23; return $e; }
OOPS() { STDERR OOPS: "$@"; exit 23; }
WARN() { STDERR WARN: "$@"; }
x() { "$@"; }
o() { x "$@" || OOPS rc=$?: "$@"; }
# touch $'hello world\n' && f="$(echo hell*)" && test -f "$f" || echo POSIX fail
# touch $'hello world\n' && v f  echo hell*   && test -f "$f" && echo POSIX corrected
v() { eval "$1"='"$(x "${@:2}" && echo x)"' && eval "$1=\${$1%x}" && eval "$1=\${$1%\$'\\n'}"; }
ov() { o v "$@"; }

# present usage.  DRY: Take from comments in this file
usage()
{
  awk -vARG0="${0##*/}" '/^#U ?/ { sub(/^#U ?/,""); gsub(/{ARG0}/, ARG0); print }' "$0"
  exit 42
}

# check for needed binaries being in PATH
# Note:  We change the PATH, this must happen afterwards, as we want to replace some of the binaries with our patched version
check-BIN()
{
for a in			\
	awk			\
	mmdebstrap		\
	newgidmap newuidmap	\
	lxc-ls			\
	;
do
	which "$a" >/dev/null || OOPS this needs "$a" installed
done
}

mustnotexist()
{
[ ! -L "$1" ] && [ ! -e "$1" ] || OOPS "$HERE:" "$1" exists: "${@:2}"
}

# Create the directory or softlink to LXC.  This is where the containers are stored.
setup-LXC()
{
mustnotexist "$1"
WARN setup-LXC not yet completed.  Creating default "$1"/
o ln -nsf --backup=t --relative "$HOME/.local/share/lxc" "$1"
}

# Create the directory or softlink to CONF.
# This is a directory where we want to keep the configuration outside of the container space itself.
# It makes sense to overlay this with the standard LXC configuration directory (so take default.conf always from ~/.config/lxc/).
setup-CONF()
{
mustnotexist "$1"
WARN setup-CONF not yet completed.  Creating default "$1"/
o ln -nsf --backup=t --relative "$HOME/.config/lxc" "$1"
}

# Find entries of /etc/sub?id and output them the LXC way
# XXX TODO XXX this is shit in shit out, so it must be checked in check-DEFAULT
: map2lxc 1:? 2:/etc/sub?id 3:?id 4:?name 5:[startvalue:-1]
map2lxc()
{
[ -s "$2" ] || OOPS mapping file "$2" missing, see SUB_UID in man useradd
awk -F: -vT="$1" -vU="$3" -vN="$4" -vC="${5:-1}" '
$1==U || $1==N	{ print "lxc.idmap = " T " " C " " $2 " " $3; C+=$3 }
' "$2"
}

# Create a suitable and meaningful ~/.config/lxc/default.conf
# :xx:xx:xx below is the correct LXC way of configuring multiple interfaces
# In OUR case the xx:xx:xx will be replaced by the container config's inode
setup-DEFAULT()
{
local U G N S D F TMP
mustnotexist "$1"
WARN setup-DEFAULT not yet completed.  Creating default "$1"
ov D dirname "$1"
ov F basename "$1" .conf
ov TMP mktemp -p "$D" "$F".XXXXXX.tmp
ov U id -u
ov G id -g
ov N id -u -n
ov S id -g -n
{
# I did not find a proper authentic documentation about default.conf
# man lxc.system.conf is only partially helpful,
# it is more like an example where all the problems with lxc start ..
#
# xx:xx:xx will be replaced by some random value (LXC),
# in our case we fill in the container config's inode
o cat <<EOF
# lxcbr0 is the default LXC bridge
# ETH Vendor 00163e is XENsource INC
lxc.net.0.type = veth
lxc.net.0.link = lxcbr0
lxc.net.0.flags = up
lxc.net.0.hwaddr = 00:16:3e:xx:xx:xx
# The outside user (you!) becomes "root" in a container (from outside without powers)
# This way it becomes way more easy to interact with containers
lxc.idmap = u 0 $U 1
lxc.idmap = g 0 $G 1
# More mapping from /etc/sub?id
EOF
o map2lxc u /etc/subuid "$U" "$N"
o map2lxc g /etc/subgid "$G" "$S"
} > "$TMP" || OOPS cannot write "$TMP"
o mv --backup=t "$TMP" "$1"
}

# Check the default LXC setting for possible errors or unknown parts
check-DEFAULT()
{
WARN check-DEFAULT not implemented: setting not checked yet
# XXX TODO XXX check network
# XXX TODO XXX check idmaps for enough range
}

# Read CONF/lxc-$CONTAINER.config (CONTAINER is the 1st commandline argument)
# This is a hybrid:
# - It is the lxc.container.conf
# - It also contans the container settings for this script
# If the config file is missing
# - It will be created.
# - The template to use is taken from CONF/lxc-$SETTINGS.conf (SETTINGS is 2nd commandline argument)
# - If CONF/lxc-$SETTINGS.conf is missing it will be created from CONF/default.conf plus some defaults
settings-read-or-create()
{
o settings-create "$1"
o data GET "$1"
}

# Create the CONF/lxc-$CONTAINER.config if it not already exists
settings-create()
{
[ -s "$1" ] && return
local S
o conf-create "CONF/lxc-$SETTINGS.conf"
o touch "$1"		# create inode
o v S stat -tLc %i "$1"	# get inode number
o awk -vS="$S" '	# put inode number into ethernet
BEGIN		{ X=sprintf("%06x", S) }
$1~/\.hwaddr$/	{ while (/:xx/) { l=length(X); x=substr(X,l-1); X=substr(X,0,l-2); if (x=="") x="00"; sub(/:xx/,x) } }
		{print}
' "CONF/lxc-$SETTINGS.conf" >> "$1"
}

# Create the CONF/lxc-$SETTINGS.conf if it not already exists
conf-create()
{
local a b
[ -s "$1" ] && return
mustnotexit "$1"
WARN creating "$1" with defaults

o data DEF
{
printf '# Setting:       %q\n' "$SETTINGS"
printf '# Created for:   %q\n' "$CONTAINER"
for a in "${PARAM0[@]}" "${PARAM1[@]}"
do
	echo "$a"
done
#	b="LXC_$a"
#	printf '#LXC#%11s=%q\n' "$a" "${!b}"
#done
printf '# defaults from: %q\n' "$(o readlink -e -- CONF/default.conf)"
o sed -e '/^#/d' -e '/^[[:space:]]*$/d' CONF/default.conf
} > "$1"
}

#
# MAIN
#

# prepare the environment
ov REL dirname -- "$0"
ov HERE readlink -e -- "$REL"
o cd "$HERE"

o check-BIN
[ -d LXC ] || o setup-LXC LXC
[ -d CONF ] || o setup-CONF CONF
[ -f CONF/default.conf ] || o setup-DEFAULT CONF/default.conf
o check-DEFAULT

# get commandline args, else present usage
CONTAINER="$1"
SETTINGS="${2:-$1}"

[ -n "$SETTINGS" ] || usage

# Patch in our "binaries" which fix the wrong default route taken my mmdebstrap.
# Hopefully "mmdebstrap" continues to use $PATH for them,
# as else it would be more easy to just re-invent something like mmdebstrap from scratch.
export PATH="$HERE/bin:$PATH"

# Do the install
o settings-read-or-create "CONF/lxc-$CONTAINER.config"
o lxc-container-config
o lxc-container-debian-keyring
o lxc-container-mmdebstrap

# done
:
return 0
exit 0


















#printf -vD '%s.%(%Y%m%d-%H%M%S)T' "$L/$C" -1

P="$D/trust.d/"
printf -vA '"%q"' "$P"

mkdir "$D" "$P"
for a in /usr/share/keyrings
do
	[ -s "$a/$K" ] && ln -vs --backup=t --relative "$a/$K" "$P"
done

ARGS=()
ARGS+=(-v)
ARGS+=(--debug)
ARGS+=("--variant=$V")
ARGS+=("--include=ifupdown,systemd-sysv,$I")
ARGS+=("--aptopt=Dir::Etc::TrustedParts $A;")
ARGS+=("$T")
ARGS+=("$D/rootfs")
ARGS+=("$R")

mmdebstrap "${ARGS[@]}"

{
cat <<EOF
# Distribution configuration
lxc.include = /usr/share/lxc/config/common.conf
lxc.include = /usr/share/lxc/config/userns.conf
lxc.arch = linux64
lxc.rootfs.path = dir:$D/rootfs
lxc.uts.name = $C
EOF

## Container specific configuration
#lxc.idmap = u 0 $U 1
#lxc.idmap = g 0 $G 1
#lxc.idmap = u 1 100000 65536
#lxc.idmap = g 1 100000 65536
#
## Network configuration
#lxc.net.0.type = veth
#lxc.net.0.link = lxcbr0
#lxc.net.0.flags = up
# 00163e is Xensource, Inc.:
#lxc.net.0.hwaddr = 00:16:3e:xx:xx:xx`

} >"$D/config"

printf -- '--------------------------------\n%q\n--------------------------------\n' "$D"

