#!/bin/bash
#
#U Usage: [NAME]
#U	Unprivileged LinuX Containers initial setup
#U	Other commands implicitely invoke this if needed.
#U
#U	If NAME is given this creates a wrapper in $HOME/bin/NAME to LXC
#U
#U	In future you might be able to change some parameters interactively
#U	- For now this here is fully automatic.
#U	- For now it only works from scratch.
#U	- In that case, just do, what it says, to get it up and running.
#U
#U	As always, think first, as everything you do is AT YOUR OWN RISK!
#
# This Works is placed under the terms of the Copyright Less License,
# see file COPYRIGHT.CLL.  USE AT OWN RISK, ABSOLUTELY NO WARRANTY.

LXC_ARGS=-1
ME="$(readlink -e -- "$0")" || exit
. "${ME%/*/*}/lxc-inc/lxc.inc" || exit

# If we cannot find our wrapper somethings is broken anyway
ov SRC readlink -e "$LXC_BASE/bin/lxc.sh"

note()
{
  local a
  {
	printf 'Cannot detect wrapper\n'
	printf 'for %q\n' "$SRC"
	ov a readlink -e "$HOME/bin/."
	printf 'in  %q\n' "$a"
	for a
	do
		printf '%s\n' "$a"
	done
  } | Squelch wrapper
}

check()
{
  for CMD in "$HOME"/bin/*
  do
	[ -L "$CMD" ] || continue
	ov DST readlink -m "$CMD"
	[ ".$SRC" = ".$DST" ] && return 0
  done
  note 'Creating default wrapper'
  return 1	# invokes setup
}

setup()
{
  local SETUP

  o LXCvalidU "$1" not a valid wrapper name

  CMD="$HOME/bin/$1"
  ov DST readlink -m "$CMD"
  [ ".$SRC" = ".$DST" ] && return 0
  if	[ -L "$DST" ] || [ -e "$DST" ]
  then
	Human SETUP setup
	note "Please re-invoke $SETUP with a proper wrapper name as first argument." "(Name $1 already taken.)"
	return 1
  fi

  STDOUT Creating wrapper "$DST"
  o ln -nsf --backup=t --relative "$SRC" "$DST"
}

[ -z "$1" ] && check || setup "${1:-LXC}" && STDOUT && STDOUT You can run: "$CMD" && STDOUT

STDERR note: Setup still needs a lot improvement.
LXCexit

