#!/bin/bash

set -e

cd "$(dirname -- "$0")"

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

