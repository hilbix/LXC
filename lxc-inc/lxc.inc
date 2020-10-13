#
# vim: ft=bash :
#
# All functions starting with Uppercase letter are those, you possbly want to call from your own scripts.
# Also x, o, v and ov are "standard" here and environment variables starting with LXC_
# Everything else may change or vanish incompatibly!
#
# Your script could start like:
#
# #!/bin/bash
# #U Usage: args..
# #U	more usage
# LXC_ARGS=- . /path/to/lxc-inc/lxc.inc || exit
# ..your..script..here..
# LXCexit

[ -z "$LXC_DEBUG" ] || set -x

#export LC_ALL=C.UTF-8	# makes this scriptable -- however, setting this globally is wrong, see x() below
set -C			# noclobber


#
# Defaults
#
# PARAM0: Single value
PARAM0=(UID GID SUITE   VARIANT  SCHEMA)
VALUE0=(0   0   buster  minbase  http://)
# PARAM1: Comma separated multiple values
PARAM1=(REPOS                   KEYS                        INCLUDES)
VALUE1=(deb.debian.org/debian/  debian-archive-keyring.gpg  vim)


#
# Quick'n'dirty standards
#
STDOUT() { local e=$?; printf '%q' "$1"; [ 1 -lt $# ] && printf ' %q' "${@:2}"; printf '\n'; return $e; }
STDERR() { local e=$?; STDOUT "$@" >&2 || exit 23; return $e; }
OOPS() { STDERR OOPS: "$@"; exit 23; }
BUG() { OOPS internal error: "$@"; }
NEED() { local a b; for a; do [ -n "${!a}" ] || BUG $a not set; done; }
WARN() { local e=$?; LXC_MURX=2; STDERR WARN: "$@"; return $e; }
x() { local LC_ALL=C.UTF-8; export LC_ALL; "$@"; }
o() { x "$@" || OOPS rc=$?: "$@"; }
# touch $'hello world\n' && f="$(echo hell*)" && test -f "$f" || echo POSIX fail
# touch $'hello world\n' && v f  echo hell*   && test -f "$f" && echo POSIX corrected
v() { eval "$1"='"$(x "${@:2}" && echo x)"' && eval "$1=\${$1%x}" && eval "$1=\${$1%\$'\\n'}"; }
ov() { o v "$@"; }


#
# Interactives
#

sep() { printf '%72s\n' '' | tr ' ' -; }

: LXClocate VAR cmd
LXClocate()
{
  LXCvalid "$2" invalid command name
  # In future we might locate it elsewhere, too.
  eval "$1=\"\$LXC_BASE/bin/\$2.sh\""

  test -x "${!1}" || return
}

# stuff VAR with the correct "human way" to call a command
: Human VAR cmd
Human()
{
  local -n a="$1"
  local b

  o LXClocate b "$2"
  if [ -n "$LXC_WRAPPER" ]
  then
	a="${LXC_WRAPPER} $2"
  else
	a="$b"
  fi
}

# Print out a warning which can be squelched, see LXC squelch
: Squelch tag <<<message
Squelch()
{
  fgrep -sqx "$1" "$LXC_BASE/CFG/lxc.squelch" && return
  LXC_MURX=2
  while read -ru6 line
  do
	printf 'WARN: %s\n' "$line"
  done 6< <(sep; Human CMD squelch; STDOUT To not fix it and squelch following message use:; $CMD "$1"; sep; cat; sep)
}

: MustNotExist path message..
MustNotExist()
{
  [ ! -L "$1" ] && [ ! -e "$1" ] || OOPS "$LXC_CMD:" "$1" exists: "${@:2}"
}

tarcopy()
{
  o set -o pipefail
  o tar Ccf "$1" - . | o tar Cxf "$2" -
}

MvAway()
{
  local a
  for a
  do
	[ -e "$a" ] || [ -L "$a" ] || continue
	o mv --backup=t -T -- "$a" "$a.old"
  done
  :
}


#
# Common
#

LXC_MURX=0
LXCexit()
{
local err="${1:-$LXC_MURX}"
case "$err" in
(''|*[^0-9]*)	BUG LXCexit cannot return "$err";;
(0)	STDERR "$LXC_CMD" finished successfully;;
(2)	STDERR "$LXC_CMD" finished with warning;;
(*)	STDERR "$LXC_CMD" finished with error;;
esac
exit "$err"
}


#
# LXCs
#

# Find entries of /etc/sub?id and output them as LXC configuration items
# Also map your own UID/GID into some other UID of the target,
# usually given as LXC_UID/LXC_GID (default: 0/0)
# so your user can become a certain user in the LXC
# XXX TODO XXX this is shit in shit out, so it must be checked in check-DEFAULT
: map2lxc 1:UG 2:/etc/subUGid 3:UID/GID 4:username/groupname [5:MAP_ID_to_not_if_-1]
map2lxc()
{
  [ -s "$2" ] || OOPS mapping file "$2" missing, see SUB_UID in man useradd
  # /etc/sub?id has format: name_or_id:startid:count
  awk -F: -vT="$1" -vI="$3" -vN="$4" -vC="${5:-"-1"}" '
	BEGIN	{ start=0 }
	function out(pos, n)
	{
		if (n<=0)
			return
		printf("lxc.idmap = %s %d %d %d\n", T, start, pos, n);
		start	+= n
	}
	$1==N || $1==I	{
		pos	= $2;
		n	= $3;
		if (C >= start && C < start+n)
			{
			m	= C-start
			out(pos, m)
			out(I, 1)
			pos	+= m
			n	-= m
			}
		out(pos, n)
		}
	' "$2"
}

#
# Checks
#

: check-env
check-env()
{
(
NEED LXC_BASE LXC_INC
o test ".$LXC_BASE/lxc-inc/lxc.inc" = ".$LXC_INC"
o test -d "$LXC_BASE/bin"
o test -d "$LXC_BASE/wrap"
# $LXC_BASE/CFG and $LXC_BASE/LXC might need setup
)
}

: LXCvalid name message..
LXCvalid()
{
  case "$1" in
  (*[^0-9a-z_-])	;;
  (?*)			return 0;;
  esac
  OOPS "${@:2}:" "$1"
}

# check for needed binaries being in PATH
# Note:  We change the PATH, this must happen afterwards, as we want to replace some of the binaries with our patched version
: check-BIN
check-BIN()
{
  local a

  for a in			\
	ln			\
	awk			\
	mmdebstrap		\
	newgidmap newuidmap	\
	lxc-ls			\
	lxc-attach		\
	;
  do
	which "$a" >/dev/null || OOPS this needs "$a" installed
  done
}

# Check the default LXC setting for possible errors or unknown parts
check-GLOBALS()
{
  local a b

  fgrep -sqx 'USE_LXC_BRIDGE="true"' /etc/default/lxc-net ] ||
  Squelch bridge <<'EOF'
	/etc/default/lxc-net does not contain the line
	USE_LXC_BRIDGE="true"

	To fix try something like:
	sudo tee -a /etc/default/lxc-net <<<'echo USE_LXC_BRIDGE="true"'
EOF

  fgrep -sq 'lxc.net.0.' /etc/lxc/default.conf ||
  Squelch defnet <<'EOF'
	/etc/lxc/default.conf is missing the networking entry, like this:

	# lxcbr0 is the default LXC bridge
	# ETH Vendor 00163e is XENsource INC
	lxc.net.0.type = veth
	lxc.net.0.link = lxcbr0
	lxc.net.0.flags = up
	lxc.net.0.hwaddr = 00:16:3e:xx:xx:xx

	To fix you can do:
	sudo vim /etc/lxc/default.conf
	# add something like the above 4 to 6 lines to it
EOF

  cmp - /proc/sys/kernel/unprivileged_userns_clone <<<1 ||
  Squelch userns <<'EOF'
	/proc/sys/kernel/unprivileged_userns_clone is not set to 1.

	To fix try something like:
	sudo tee -a /etc/sysctl.d/80-lxc-userns.conf <<<'kernel.unprivileged_userns_clone=1'
	sudo sysctl --system
EOF

  ov a printf '%q\t%q\t%q\t%q' "$(id -un)" veth lxcbr0 10
  ov b printf '%q' "$a"
  fgrep -sqx "$a" /etc/lxc/lxc-usernet ||
  Squelch usernet <<EOF
	/etc/lxc/lxc-usernet perhas not contain your user.

	To fix try someting like:
	sudo tee -a /etc/lxc/lxc-usernet <<<$b
	sudo systemctl enable lxc-net
	sudo systemctl restart lxc-net
EOF
}


#
# Set
#

# set the LXC_CONTAINER name to operate on
# LXC_CONTAINER usually is the 1st argument after LXC command)
# This should be always the first thing you do in your scripts
: LXCcontainer name
LXCcontainer()
{
  LXC_CONTAINER="$1"
  LXC_TEMPLATE="$1"
  LXCvalid "$LXC_CONTAINER" not a valid container name
}

# set the LXC_TEMPLATE name to operate on (defaults to LXC_CONTAINER)
: LXCtemplate name
LXCtemplate()
{
  NEED LXC_CONTAINER
  LXC_TEMPLATE="${1:-"$LXC_CONTAINER"}"
  LXCvalid "$LXC_TEMPLATE" not a valid template name
}

# mix settings into PREFIX_names
# 1st: LXC_name
# 2nd: fileN..file1
# Last: Defaults (VALUE#) below
# File format: #LXC#[optspaces]variable=value
: settings-get PREFIX [files]
settings-get()
{
  local a b

  # Preset defaults
  for a in "${!PARAM0[@]}"
  do
	b="_${PARAM0[$a]}"
	eval "$1$b=\"\${VALUE0[\"\$a\"]}\""
  done
  for a in "${!PARAM1[@]}"
  do
	b="_${PARAM1[$a]}"
	eval "$1$b=\"\${VALUE1[\"\$a\"]}\""
  done

  # Now (possibly) override the values by the files
  o . <(o awk -vPREF="$1_" -vLIST="${PARAM0[*]} ${PARAM1[*]}" '
	BEGIN		{
			gsub(/,/," ", LIST);
			n = split(LIST, k)
			while (--n>=0)
				vars[k[n+1]]=1
			}
	/^#LXC#/	{
			gsub(/#LXC#[[:space:]]*/,"");
			v=$0
			gsub(/[[:space:]]*=.*$/, "", v);
			if (v!="" && vars[v])
				print PREF $0
			else
				print FILENAME ":" FNR ": unknown variable ignored: " v >"/dev/stderr"
			}
	' "${@:2}" </dev/null
	)

  # Singular values must not be empty
  for a in "${!PARAM0[@]}"
  do
	b="_${PARAM0[$a]}"
	eval "$1$b=\"\${LXC$b:-\"\${$1$b:-\"\${VALUE[\"\$a\"]}\"}\"}\""
  done
  # Comma separated values get LXC_var appended
  for a in "${!PARAM1[@]}"
  do
	b="_${PARAM1[$a]}"
	eval "$1$b=\"\${$1$b},\${LXC$b}\""
	eval "$1$b=\"\${$1$b%,}\""
  done
}

: settings-print PREFIX
settings-print()
{
  for a in "${PARAM0[@]}" "${PARAM1[@]}"
  do
	b="${1:-GET}_$a"
	printf '%12s = %q\n' "LXC_$a" "${!b}"
  done
}


#
# Helpers
#

: Help script arg0
Help()
{
  o awk -vLXC="${2:-"$1"}" -vPATH="$LXC_BASE" '
	$2=="Usage:"	{ $2="Usage: " LXC }
	/^#U ?/		{ sub(/^#U ?/,""); gsub(/{CMD}/, LXC); gsub(/{PATH}/, PATH); print }
	' "$1"
}

# present usage.  DRY: Take from comments in this file
: Usage
Usage()
{
  Help "$0" "${LXC_USAGE:-"${0##*/}"}"
  exit 42
}


#
# Setups
#

# Create the directory or softlink to LXC.  This is where the containers are stored.
: setup-LXC LXC
setup-LXC()
{
  [ -d "$1" ] && return
  MustNotExist "$1" no directory nor softlink to directory
  WARN interactive LXC setup not yet completed.  Creating default "$1"/
  o ln -nsf --backup=t --relative "$HOME/.local/share/lxc" "$1"
}

# Create the directory or softlink to CFG.
# This is a directory where we want to keep the configuration outside of the container space itself.
# It makes sense to overlay this with the standard LXC configuration directory (so take default.conf always from ~/.config/lxc/).
setup-CFG()
{
  [ -d "$1" ] && return
  MustNotExist "$1" no directory nor softlink to directory
  WARN interactive LXC setup not yet completed.  Creating default "$1"/
  o ln -nsf --backup=t --relative "$HOME/.config/lxc" "$1"
}

# Create a suitable and meaningful ~/.config/lxc/default.conf
# :xx:xx:xx below is the correct LXC way of configuring multiple interfaces
# In OUR case the xx:xx:xx will be replaced by the container config's inode
setup-DEFAULT()
{
  local U G N S D F TMP

  [ -f "$1" ] && return
  MustNotExist "$1" no file nor softlink to file
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
  printf '# from %q\n' "/etc/lxc/default.conf"
  o cat /etc/lxc/default.conf
  o cat <<EOF
# [end]
#
# lxcbr0 is the default LXC bridge
# ETH Vendor 00163e is XENsource INC
# Something like should be included from /etc/lxc/default.conf above:
#
#lxc.net.0.type = veth
#lxc.net.0.link = lxcbr0
#lxc.net.0.flags = up
#lxc.net.0.hwaddr = 00:16:3e:xx:xx:xx
#
# The outside user (you!) becomes "root" in a container (from outside without powers)
# This way it becomes way more easy to interact with containers
#
#lxc.idmap = u 0 $U 1
#lxc.idmap = g 0 $G 1
#
# More mapping from /etc/sub?id
# where our $U is mapped to additional ID ranges
#
EOF
  o map2lxc u /etc/subuid "$U" "$N"
  o map2lxc g /etc/subgid "$G" "$S"
  } >> "$TMP" || OOPS cannot write "$TMP"
  o mv --backup=t "$TMP" "$1"
}


#
# MISC / Unsorted
#

# If the config file CFG/lxc-$LXC_CONTAINER.conf is missing:
# - It will be created.
# - The template to use is taken from CFG/lxc-$LXC_TEMPLATE.conf (LXC_TEMPLATE is 2nd arg to lxc-create)
# - If $LXC_BASE/CFG/lxc-$LXC_TEMPLATE.conf is missing it will be created from CFG/default.conf plus some defaults
LXCsettings-create()
{
  o settings-create
  o LXCsettings "$@"
}

# Read $LXC_BASE/CFG/lxc-$LXC_CONTAINER.config (see: lxc-container)
# The config is a hybrid:
# - It is the lxc.container.conf
# - It also contans the container settings for this script here as comments
: LXCsettings [VAR]
LXCsettings()
{
  NEED LXC_CONTAINER
  o settings-get "${1:-GET}" "$LXC_BASE/CFG/lxc-$LXC_CONTAINER.config"
}

# Create the $LXC_BASE/CFG/lxc-$LXC_CONTAINER.config if it not already exists
settings-create()
{
  NEED LXC_CONTAINER LXC_TEMPLATE
  local a I P C="$LXC_BASE/CFG/lxc-$LXC_CONTAINER.config" T="$LXC_BASE/CFG/lxc-$LXC_TEMPLATE.conf"

  [ -s "$T" ] && return
  MustNotExist "$T" not a nonempty file nor softlink to some

  o conf-create
  o settings-get TPL "$T"

  o touch "$C"			# create inode
  ov I stat -tLc %i "$C"	# get inode number
  ov P readlink -m "$LXC_BASE/LXC/$LXC_CONTAINER/rootfs"
  {
  printf '# Standard settings from %q\n' "$ME"
  cat <<EOF
#
lxc.include = /usr/share/lxc/config/common.conf
lxc.include = /usr/share/lxc/config/userns.conf
lxc.arch = linux64
#
# Container settings (generated)
#
EOF
  printf 'lxc.uts.name = %q\n' "$LXC_CONTAINER"
  printf 'lxc.rootfs.path = dir:%q\n' "$P"
  printf '#\n'
  printf '# Settings from environment:\n'
  for a in "${PARAM0[@]}" "${PARAM1[@]}"
  do
	b="TPL_$a"
	printf '#LXC#%11s=%q\n' "$a" "${!b}"
  done
  printf '# Settings from %q\n' "$S"
  printf '#\n'
  o awk -vI="$I" '	# put inode number into ethernet
	BEGIN		{ X=sprintf("%06x", I) }
	/^#/		{ next }
	$1~/\.hwaddr$/	{ while (/:xx/) { l=length(X); x=substr(X,l-1); X=substr(X,0,l-2); if (x=="") x="00"; sub(/:xx/,":"x) } }
			{print}
	' "$S"
  } >> "$C"
}

# Create the CFG/lxc-$LXC_TEMPLATE.conf if it not already exists
conf-create()
{
  NEED LXC_CONTAINER LXC_TEMPLATE
  local a b D C="$LXC_BASE/CFG/lxc-$LXC_TEMPLATE.conf"

  [ -s "$C" ] && return
  MustNotExist "$C" container already exists
  WARN creating "$C" with defaults

  ov D readlink -e "$LXC_BASE/CFG/default.conf"
  o settings-get DEF "$D"

  {
  printf '# Setting:       %q\n' "$LXC_TEMPLATE"
  printf '# Created for:   %q\n' "$LXC_CONTAINER"
  printf '#\n'
  for a in "${PARAM0[@]}" "${PARAM1[@]}"
  do
	b="DEF_$a"
	printf '#LXC#%11s=%q\n' "$a" "${!b}"
  done
  printf '#\n'
  printf '# defaults from: %q\n' "$D"
  o sed -e '/^#/d' -e '/^[[:space:]]*$/d' "$D"
  } > "$C"
}

# Before call LXCsettings or LXCsettings-create
# Create the LXC/$LXC_CONTAINER/ skeleton
# - populate trust.d/ with the correct GPG key for apt
# - populate bin/ with binaries wrapped for the container
: LXCcontainer-setup
LXCcontainer-setup()
{
  NEED LXC_CONTAINER
  local a b C P FOUND DIR="$LXC_BASE/LXC/$LXC_CONTAINER"

  Human LIST list
  MustNotExist "$DIR" container name already taken.  Try: $LIST
  LXCcontainer-update
}
LXCcontainer-update()
{
  NEED LXC_CONTAINER
  local a b C P FOUND DIR="$LXC_BASE/LXC/$LXC_CONTAINER"

  o mkdir -p "$DIR" "$DIR/rootfs"
  ov C readlink -e "$LXC_BASE/CFG/lxc-$LXC_CONTAINER.config"
  ov P readlink -e "$DIR/rootfs"
  o MvAway "$DIR/config"
  {
  printf '# From %q\n' "$C"
  cat "$C"
  printf '#\n'
  printf '# Container settings (generated)\n'
  printf '#\n'
  printf 'lxc.uts.name = %q\n' "$LXC_CONTAINER"
  printf 'lxc.rootfs.path = dir:%q\n' "$P"
  printf '#\n'
  for a in "${PARAM0[@]}" "${PARAM1[@]}"
  do
	b="GET_$a"
	printf '#LXC#%11s=%q\n' "$a" "${!b}"
  done
  } >"$DIR/config"

  o MvAway "$DIR/trust.d"
  o mkdir "$DIR/trust.d"
  for a in $GET_KEYS
  do
	FOUND=
	for b in '' /etc/apt/trusted.gpg.d/ /usr/share/keyrings/ /home/.gnupg/ /home/.local/share/keyrings/
	do
		[ -s "$b$a" ] && ov FOUND readlink -e "$b$a"
	done
	[ -s "$FOUND" ] || OOPS cannot find source of "$a"
	o ln -s "$FOUND" "$DIR/trust.d/"
  done

  o MvAway "$DIR/bin"
  o mkdir "$DIR/bin"
  o tarcopy "$LXC_BASE/wrap" "$DIR/bin"

  # XXX TODO XXX cleanups of the ".old" variants?
}

# LXCcontainer rest
# LXCsettings-create
# LXCcontainer-setup
# LXCcontainer-mmdebstrap
: LXCcontainer-mmdebstrap
LXCcontainer-mmdebstrap()
{
  NEED LXC_CONTAINER
  local a ARGS I C DIR="$LXC_BASE/LXC/$LXC_CONTAINER"

  I="ifupdown,systemd-sysv,$GET_INCLUDES"
  I="${I%,}"
  ov C readlink -e "$DIR"

  ARGS=()
  ARGS+=(-v)
  ARGS+=(--debug)
  ARGS+=("--variant=$GET_VARIANT")
  ARGS+=("--include=$I")
  ARGS+=("--aptopt=Dir::Etc::TrustedParts \"$C/trust.d/\";")
  ARGS+=("$GET_SUITE")
  ARGS+=("$C/rootfs")
  for a in ${GET_REPOS/,/ }
  do
	ARGS+=("$GET_SCHEMA$a")
  done

  # Patch in our "binaries" which fix the wrong default route taken my mmdebstrap.
  # Hopefully "mmdebstrap" continues to use $PATH for them,
  # as else it would be more easy to just re-invent something like mmdebstrap from scratch.
  export PATH="$C/bin:$PATH"

  o mmdebstrap "${ARGS[@]}"
}


#
# Common Init
#

ov LXC_INC readlink -e "$BASH_SOURCE"
LXC_BASE="${LXC_INC%/lxc-inc/lxc.inc}"
ov LXC_CMD basename -- "$0" .sh

check-env || OOPS please use softlinks: cannot detect install folder of "$0"
o check-BIN

case "$*" in
(-h|--help)	Usage;;
esac

case "$LXC_ARGS" in
(''|*-*-*|*[^0-9-]*)	BUG LXC_ARGS invalid: "$LXC_ARGS";;
(-)	true;;
(*-)	[ $# -ge "${LXC_ARGS%%-*}" ];;
(-*)	[ $# -le "${LXC_ARGS##*-}" ];;
(*-*)	[ $# -ge "${LXC_ARGS%%-*}" ] || [ $# -le "${LXC_ARGS##*-}" ];;
(*)	[ $# = "$LXC_ARGS" ];;
esac || Usage	# or error with hint to try --help?

o setup-LXC	"$LXC_BASE/LXC"
o setup-CFG	"$LXC_BASE/CFG"
o setup-DEFAULT	"$LXC_BASE/CFG/default.conf"
o check-GLOBALS

:

