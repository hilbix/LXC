#
# vim: ft=bash :

[ -z "$LXC_DEBUG" ] || set -x
set -C		# noclobber

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

check-env()
{
(
o test ".$BASE" != ".$ME"
o test -d "$BASE/bin"
o test -d "$BASE/wrap"
o test -d "$BASE/lxc-inc"
# $BASE/CONF and $BASE/LXC might need setup
)
}

# present usage.  DRY: Take from comments in this file
Usage()
{
  awk -vARG0="${LXC_USAGE:-"${0##*/}"}" -vPATH="$BASE" '/^#U ?/ { sub(/^#U ?/,""); gsub(/{ARG0}/, ARG0); gsub(/{PATH}/, PATH); print }' "$0"
  exit 42
}

: check-name name message..
check-name()
{
  case "$1" in
  (*[^0-9a-z_-])	;;
  (?*)			return 0;;
  esac
  OOPS "${@:2}:" "$1"
}

: set-container name
set-container()
{
  check-name "$1" not a valid container name
  LXC_CONTAINER="$1"
}

# mix settings into PREFIX_names
# 1st: LXC_name
# 2nd: fileN..file1
# Last: Defaults (VALUE#) below
# File format: #LXC#[optspaces]variable=value
: settings PREFIX [files]
settings()
{
  local a b

  # PARAM0: Single value
  PARAM0=(UID GID SUITE   VARIANT  CACHE    REPO)
  VALUE0=(0   0   buster  minbase  http://  deb.debian.org/debian/)
  # PARAM1: Comma separated multiple values
  PARAM1=(KEYS                        INCLUDES)
  VALUE1=(debian-archive-keyring.gpg  vim)

  # Preset defaults
  for a in "${!PARAM0[@]}"
  do
	b="_${PARAM0[$a]}"
	eval "$1$b=\"\${VALUE0[\$a]}\""
  done
  for a in "${!PARAM1[@]}"
  do
	b="_${PARAM1[$a]}"
	eval "$1$b=\"\${VALUE1[\$a]}\""
  done

  # Now (possibly) override the values by the files
  o . <(o awk -vLIST="${PARAM0[*]} ${PARAM1[*]}" '/^#LXC#/	{
	}
	' "${@:2}"-n "s/^#LXC#[[:space:]]*/$1_/p" "$2")

  # Singular values must not be empty
  for a in "${!PARAM0[@]}"
  do
	b="_${PARAM0[$a]}"
	eval "$1$b=\"\${LXC$b:-\"\${$1$b:-\"\${VALUE[\$a]}\"}\"}\""
  done
  # Comma separated values get LXC_var appended
  for a in "${!PARAM1[@]}"
  do
	b="_${PARAM1[$a]}"
	eval "$1$b=\"\$$1$b,\${LXC$b}\""
	eval "$1$b=\"\${$1$b%,}"
  done
}

ov ME readlink -e "$0"
BASE="${ME%/bin/*}"

check-env || OOPS please use softlinks: cannot detect install folder of "$0"

return 0
exit 0










































# calculate default values PREFIX_$name
# They can be overwritten by environment variables LXC_$name
: defaults PREFIX
defaults()
{
  local a b
}

# read LXC data from file
: data PREFIX file
data()
{
  defaults "$1"	# fills PARAM0 and PARAM1
  # read the config into PREFIX_VARIABLE.  Yes, sorry, silly simple for now
  o . <(o sed -n "s/^#LXC[[:space:]]+/$1_/p" "$2")
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
	eval "$1$b=\"\${$1$b%,}\""
  done
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
# Also map the own UID into some other UID of the target
# so YOU become a certain user in the LXC
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
lxc.idmap = u 0 $U 1
lxc.idmap = g 0 $G 1
#
# More mapping from /etc/sub?id
# where our $U is mapped to 
#
EOF
  o map2lxc u /etc/subuid "$U" "$N"
  o map2lxc g /etc/subgid "$G" "$S"
  } >> "$TMP" || OOPS cannot write "$TMP"
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
  local S I P
  ov S readlink -m "CONF/lxc-$SETTINGS.conf"
  o conf-create "$S"
  o touch "$1"		# create inode
  ov I stat -tLc %i "$1"	# get inode number
  ov P readlink -m "LXC/$CONTAINER/rootfs"
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
  printf 'lxc.uts.name = %q\n' "$CONTAINER"
  printf 'lxc.rootfs.path = dir:%q\n' "$P"
  printf '#\n'
  printf '# Settings from %q\n' "$S"
  printf '#\n'
  o awk -vI="$I" '	# put inode number into ethernet
	BEGIN		{ X=sprintf("%06x", I) }
	/^#/		{ next }
	$1~/\.hwaddr$/	{ while (/:xx/) { l=length(X); x=substr(X,l-1); X=substr(X,0,l-2); if (x=="") x="00"; sub(/:xx/,":"x) } }
			{print}
	' "$S"
  } >> "$1"
}

# Create the CONF/lxc-$SETTINGS.conf if it not already exists
conf-create()
{
  local a b D
  [ -s "$1" ] && return
  mustnotexist "$1"
  WARN creating "$1" with defaults

  ov D readlink -e CONF/default.conf
  o data DEF "$D"
  {
  printf '# Setting:       %q\n' "$SETTINGS"
  printf '# Created for:   %q\n' "$CONTAINER"
  printf '#\n'
  for a in "${PARAM0[@]}" "${PARAM1[@]}"
  do
	b="DEF_$a"
	printf '#LXC#%11s=%q\n' "$a" "${!b}"
  done
  printf '#\n'
  printf '# defaults from: %q\n' "$D"
  o sed -e '/^#/d' -e '/^[[:space:]]*$/d' "$D"
  } > "$1"
}

# Create the LXC/$CONTAINER/ skeleton
# - populate trust.d/ with the correct GPG key for apt
# - populate bin/ with our wrapped container binaries
lxc-container-config()
{
  local a b C P FOUND

  mustnotexist "LXC/$CONTAINER"
  o mkdir -p "LXC/$CONTAINER" "LXC/$CONTAINER/trust.d" "LXC/$CONTAINER/rootfs"
  ov C readlink -e "$1"
  ov P readlink -e "LXC/$CONTAINER/rootfs"
  {
  printf '# From %q\n' "$C"
  cat "$C"
  printf '#\n'
  printf '# Container settings (generated)\n'
  printf '#\n'
  printf 'lxc.uts.name = %q\n' "$CONTAINER"
  printf 'lxc.rootfs.path = dir:%q\n' "$P"
  printf '#\n'
  for a in "${PARAM0[@]}" "${PARAM1[@]}"
  do
	b="GET_$a"
	printf '#LXC#%11s=%q\n' "$a" "${!b}"
	printf '%10q %q\n' "$a" "${!b}" >&3
  done
  } 3>&1 >"LXC/$CONTAINER/config"

  for a in $GET_KEYS
  do
	FOUND=
	for b in '' /etc/apt/trusted.gpg.d/ /usr/share/keyrings/ /home/.gnupg/ /home/.local/share/keyrings/
	do
		[ -s "$b$a" ] && ov FOUND readlink -e "$b$a"
	done
	[ -s "$FOUND" ] || OOPS cannot find source for "$a"
	o ln -s "$FOUND" "LXC/$CONTAINER/trust.d/"
  done
}

lxc-container-mmdebstrap()
{
  local a ARGS I C

  I=ifupdown,systemd-sysv,$GET_INCLUDES
  I="${I%,}"
  ov C readlink -e "LXC/$CONTAINER"

  ARGS=()
  ARGS+=(-v)
  ARGS+=(--debug)
  ARGS+=("--variant=$GET_VARIANT")
  ARGS+=("--include=$I")
  ARGS+=("--aptopt=Dir::Etc::TrustedParts \"$C/trust.d/\";")
  ARGS+=("$GET_SUITE")
  ARGS+=("$1")
  for a in ${GET_REPO/,/ }
  do
	ARGS+=("$GET_CACHE$a")
  done

  # Patch in our "binaries" which fix the wrong default route taken my mmdebstrap.
  # Hopefully "mmdebstrap" continues to use $PATH for them,
  # as else it would be more easy to just re-invent something like mmdebstrap from scratch.
  export PATH="$C/bin:$PATH"

  o mmdebstrap "${ARGS[@]}"
}

