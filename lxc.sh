#!/bin/bash
#
#U Usage: {ARG0} container [type]
#U	- If settings/type is missing, settings/container is used
#U	- If settings/container is missing, settings/DEFAULT is used

# Quick'n'dirty standards
STDOUT() { local e=$?; printf '%q' "$1"; [ 1 -lt $# ] && printf ' %q' "${@:2}"; printf '\n'; return $e; }
STDERR() { local e=$?; STDOUT "$@" >&2 || exit 23; return $e; }
OOPS() { STDERR OOPS: "$@"; exit 23; }
WARN() { STDERR WARN: "$@"; }
x() { "$@"; }
o() { x "$@" || OOPS rc=$?: "$@"; }
# touch $'hello world\n' && f="$(echo hell*)" && test -f "$f" || echo POSIX fail
# touch $'hello world\n' && v f  echo hell*   && test -f "$f" && echo POSIX corrected
v() { eval "$1"='"$(x "$@" && echo x)"' && eval "$1=\${$1%x}" && eval "$1=\${$1%\$'\\n'}"; }

usage()
{
  awk -vARG0="${0##*/}" '/^#U ?/ { sub(/^#U ?/,""); gsub(/{ARG0}/ARG0/); print }' "$0"
  exit 42
}

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

check-MAP()
{
WARN check-MAP not yet implemented
}

setup-LXC()
{
[ ! -L LXC ] && [ ! -e LXC ] || OOPS LXC exists and is no directory or softlink to directory
WARN setup-LXC not yet completed.  Creating default LXC/
o ln -nsf --backup=t --relative "$HOME/.local/share/lxc" LXC
}

setup-CONF()
{
[ ! -L CONF ] && [ ! -e CONF ] || OOPS CONF exists and is no directory or softlink to directory
WARN setup-LXC not yet completed.  Creating default CONF/
o ln -nsf --backup=t --relative "$HOME/.config/lxc" CONF
}

map2lxc()
{
[ -s "$2" ] || OOPS mapping file "$2" missing, see SUB_UID in man useradd
awk -F: -vU="$U" -vN="$N" -vT="$1" '
BEGIN		{ I=1 }
$1==U || $1==N	{ print lxc.idmap = T " " I " " $2 " " $3; I+=$3 }
' "$2"
}

setup-DEFAULT()
{
[ ! -L CONF/default.conf ] && [ ! -e CONF/default.conf ] || OOPS CONF/default.conf exists and is no file or softlink to file
WARN setup-DEFAULT not yet completed.  Creating default CONF/default.conf
o v TMP mktemp -p CONF default.conf.XXXXXX
o U id -u
o N id -u -n
o G id -g
{
# The ETH Vendor 00163e is XENsource INC
# lxcbr0 is the default LXC bridge
o cat <<EOF
lxc.net.0.type = veth
lxc.net.0.link = lxcbr0
lxc.net.0.flags = up
lxc.net.0.hwaddr = 00:16:3e:xx:xx:xx
lxc.idmap = u 0 $U 1
lxc.idmap = g 0 $G 1
EOF
o map2lxc u /etc/subuid
o map2lxc g /etc/subgid
} > "$TMP" || OOPS cannot write "$TMP"
o mv --backup=t "$TMP" CONF/default.conf
}

check-DEFAULT()
{
WARN check-DEFAULT not implemented, so ignored
: T.B.D.: check network
: T.B.D.: check idmaps
}

check-BIN
check-MAP
[ -d LXC ] || setup-LXC
[ -d CONF ] || setup-CONF
[ -f CONF/default.conf ] || setup-DEFAULT
check-DEFAULT

CONTAINER="$1"
SETTINGS="${2:-$1}"

[ -z "$1" ] || usage

v REL dirname -- "$0"
v HERE readlink -e -- "$REL"
cd "$HERE"

# Patch in our "binaries" which fix the wrong default route taken my mmdebstrap.
# Hopefully "mmdebstrap" continues to use $PATH for them,
# as else it would be more easy to just re-invent something like mmdebstrap from scratch.
export PATH="$HERE/bin:$PATH"

settings-read
lxc-container-config
lxc-container-debian-keyring
lxc-container-mmdebstrap




















C=buster
T=buster
V=minbase
K=debian-archive-keyring.gpg
R=http://192.168.93.8:3142/deb.debian.org/debian/
I=vim

U="$(id -u)"
G="$(id -g)"

L="$(readlink -e -- LXC)"
printf -vD '%s.%(%Y%m%d-%H%M%S)T' "$L/$C" -1

P="$D/trust.d/"
printf -vA '"%q"' "$P"
printf -vX '%06x' "$(stat -tLc %i "$D")"

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

awk -vX="$X" '
/:xx/	{ while (/:xx/) { l=length(X); x=substr(X,l-1); X=substr(X,0,l-2); if (x=="") x="00"; sub(/:xx/,x) } }
			{print}
' $HOME/.config/lxc/default.conf
} >"$D/config"

printf -- '--------------------------------\n%q\n--------------------------------\n' "$D"

