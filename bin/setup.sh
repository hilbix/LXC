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

ME="$(readlink -e -- "$0")" || exit
. "${ME%/*/*}/lxc-inc/lxc.inc" || exit

[ 1 -ge $# ] || Usage

note()
{
  local a
  {
	printf 'Cannot detect wrapper\n'
	printf 'for %q\n' "$CMP"
	ov a readlink -e "$HOME/bin/."
	printf 'in  %q\n' "$a"
	for a
	do
		printf '%s\n' "$a"
	done
  } | squelch wrapper
}

check()
{
  ov CMP readlink -e "$BASE/bin/lxc.sh"
  for a in "$HOME"/bin/*
  do
	[ -L "$a" ] || continue
	ov CHK readlink -e "$a"
	[ ".$CMP" = ".$CHK" ] && return 0
  done

  ov a readlink -m "$HOME/bin/LXC"
  if	[ -L "$a" ] || [ -e "$a" ]
  then
	note 'Please re-invoke setup with a proper name as first argument.' '(Name LXC already taken.)'
  else
	note "Creating default wrapper $a"
	return 1
  fi
}

setup()
{
  o check-name "$1"
  ov a readlink -m "$HOME/bin/$1"
}

[ -z "$1" ] && check || setup "${1:-LXC}"

STDERR note: Setup still needs a lot improvement.
EXIT

