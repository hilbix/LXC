# Hints 'n TODOs

Things not yet really working out of the box yet.

This must change.  Here are some hints to do after `LXC create CONTAINER`:

## BUGs

- `LXC create $CONTAINER $TEMPLATE` creates some unexpected `CFG/lxc-$CONTAINER.conf`
  - But it works as intended


## TODOs

Following must be improved:

- `LXC run $CONTAINER` fails with `lxc-attach: $CONTAINER: attach.c: lxc_attach: 993 Failed to get init pid`
  - `LXC start $CONTAINER`


## APT

This needs `networking` and perhaps `DNS`:

```
# apt-get update
W: GPG error: http://deb.debian.org/debian buster InRelease: The following signatures couldn't be verified because the public key is not available: NO_PUBKEY 04EE7237B7D453EC NO_PUBKEY 648ACFD622F3D138 NO_PUBKEY DCC9EFBF77E11517
```

Standard solution to this: `apt-key update`

```
# apt-key update
E: gnupg, gnupg2 and gnupg1 do not seem to be installed, but one of them is required for this operation
```

Well, cannot do anything about this, you need `gnupg2` in the container.

```
# apt-key update
Warning: 'apt-key update' is deprecated and should not be used anymore!
Note: In your distribution this command is a no-op and can therefore be removed safely.
```

In that case, there is another fix needed:

```
# apt-key add /etc/apt/trusted.gpg.d/*.gpg
OK
```

## Networking

```
LXC start $CONTAINER;
LXC run $CONTAINER tee /etc/network/interfaces.d/eth0 <<EOF
auto eth0
iface eth0 inet static
address 10.0.3.${CONTAINER_NR:-2}
netmask 255.255.255.0
gateway 10.0.3.1
EOF
LXC stop $CONTAINER;
LXC start $CONTAINER;
```

- How to do `dhcp`?
  - `minbase` does not contain a DCHP client
  - is there more to it?
- We should have a command which
  - modifies a file in the container from within the container
  - and restarts it

### DNS

This **DOES NOT WORK** (yet?):

```
LXC start $CONTAINER;
LXC run $CONTAINER mkdir /etc/systemd/resolved.conf.d;
LXC run $CONTAINER tee /etc/systemd/resolved.conf.d/fallback_dns.conf <<EOF
[Resolve]
FallbackDNS=1.1.1.1 8.8.8.8
EOF
LXC stop $CONTAINER;
LXC start $CONTAINER;
```

So fallback to the old standard:

```
LXC start $CONTAINER;
LXC run $CONTAINER tee /etc/resolv.conf <<EOF
nameserver 1.1.1.1 8.8.8.8
EOF
LXC stop $CONTAINER;
LXC start $CONTAINER;
```


## X11?

T.B.D.

