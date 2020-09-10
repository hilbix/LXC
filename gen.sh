#!/bin/bash

set -e

cd "$(dirname -- "$0")"

C=buster

ARGS=()
ARGS+=(--aptopt="Dir::Etc::TrustedParts \"$PWD/debian.trusted/\";")
ARGS+=(-v --debug)
ARGS+=(--variant=minbase)
ARGS+=(--include=ifupdown,systemd-sysv,vim)
ARGS+=(buster)
ARGS+=("lxc/$C/rootfs")
ARGS+=(http://192.168.93.8:3142/deb.debian.org/debian/)

LXC="$(readlink -e -- LXC)"

mkdir "lxc/$C"
mmdebstrap "${ARGS[@]}"

cat <<EOF >"lxc/$C/config/$C.config"

# Distribution configuration
lxc.include = /usr/share/lxc/config/common.conf
lxc.include = /usr/share/lxc/config/userns.conf
lxc.arch = linux64

# Container specific configuration
lxc.idmap = u 0 `id -u` 1
lxc.idmap = g 0 `id -g` 1
lxc.idmap = u 1 100000 65536
lxc.idmap = g 1 100000 65536
lxc.rootfs.path = dir:$(readlink -e/home/tino/.local/share/lxc/buster/rootfs
lxc.uts.name = buster

# Network configuration
lxc.net.0.type = veth
lxc.net.0.link = lxcbr0
lxc.net.0.flags = up
lxc.net.0.hwaddr = 00:16:3e:54:a3:0d
EOF

