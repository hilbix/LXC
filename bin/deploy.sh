#!/bin/bash
#
#U Usage: NAME DEPLOY params..
#U	Deploy DEPLOY into a LXC
#U	WARNING!  This is in it's early stage.
#U
#U	deploy/DEPLOY.deploy contains the sourced deploy scripts.  Example:
#U	ip 5	# sets IP to .5 inside the container
#U	ip	# sets IP to the next free subip
#
# This Works is placed under the terms of the Copyright Less License,
# see file COPYRIGHT.CLL.  USE AT OWN RISK, ABSOLUTELY NO WARRANTY.

LXC_ARGS=2-
ME="$(readlink -e -- "$0")" || exit
. "${ME%/*/*}/lxc-inc/lxc.inc" || exit

LXCcontainer "$1"
LXCvalidU "$2" invalid deploy script name

ERROR()
{
  if [ ".$PC" = ".$CNR" ]
  then
	printf '#E#%s#%d##cmd %s: %s#\n' "$INPUT" "$[PC-1]" "$CMD" "$*" >&2
	OOPS "$INPUT" line "$PC" cmd "$CMD": "$@"
  else
	printf '#E#%s#%d##cmd %s line %d: %s#\n' "$INPUT" "$[PC-1]" "$CMD" "$CNR" "$*" >&2
	OOPS "$INPUT" line "$PC": cmd "$CMD" at line "$CNR": "$@"
  fi
}

good()
{
  case "$1" in
  (*[^a-zA-Z0-9_-]*)	ERROR invalid identifier "$1"
  esac
}

args()
{
  local a="$1" b="$2"
  shift 2 || BUG 1
  [ $# -ge "$a" ] || ERROR too few args
  [ $# -le "$b" ] || [ "$b" -lt "$a" ] || ERROR excess args: "${@:$[b+1]}"
}

active()
{
  local a

  [ -n "$TARGET" ] &&				# execution switched off
  for a in "${DEPLOY[@]}"
  do
	[ ".$a" = ".$TARGET" ] && return 0	# TARGET is "deploy"'s set, so execute
  done

  return 1					# not active currently
}

#C deploy TARGET..
#C	set the deployment TARGETs, inverted with !TARGET
#C	If this does not match, the following code is not executed
#C	in the container, thus not changing anything.
#C	!! THIS CURRENTLY IS NOT IMPLEMENTED and MUST BE: debian
Cdeploy()
{
  args 1 0 "$@"
  DEPLOY=("$@")
}

#C depend OTHER..
#C	Automatically invode OTHER dependencies
Cdepend()
{
  local	a

  args 1 0 "$@"
  active || return 0
  for a
  do
	good "$a"
	include "$a"
  done
}

#C default function [args..]
#C	set the defaults using a function
#C default
#C	set the defaults to the lines given
#C	until end marker (END) is reached
Cdefault()
{
  local	DEF=()

  if [ 0 = "$#" ]
  then
	while	getline
	do
		DEF+=("$line")
	done
  else
	declare -F "D$1" >/dev/null || ERROR unknown defaults function: "$1"
	o "D$1" "${@:2}"
  fi

  [ -n "${VARS[ARGS]}" ] || setVAR ARGS "${DEF[@]}"
}

Dfree-ips()
{
  local cfg a b j

  args 0 0 "$@"

  while read -ru6 cfg
  do
	cfg="${cfg// /}"
	cfg="${cfg//$'\t'/}"
	b="${cfg%%=*}"
	a="${b#lxc.net.}"
	a="${a%.link}"
	case "$a" in
	(''|*[^0-9]*)	continue;;
	esac
	b="${cfg#*=}"
	ov j ip -4 -j -p a s lxcbr0
	j="${j#*'"local"'}"
	j="${j%%,*}"
	j="${j%\"*}"
	j="${j#*\"}"
	case "$j" in
	(*[^0-9.]*|'')	continue;;
	(*.*.*.*.*)	continue;;
	(?*.?*.?*.?*)	;;
	(*)		continue;;
	esac
	a="${j%.*}"
	b=0
	while	let b++
		[ 255 -gt "$b" ]
	do
		[ "$j" = "$a.$b" ] || fgrep -qx "$a.$b" "$LXC_BASE/LXC"/*/IPS.txt && continue
#		printf 'IP %q\n' "$a.$b"
		DEF+=("$a.$b")
		break
	done
  done 6<"$LXC_CONTAINER_CFG"
}


#C for CNT ARGS..
#C  body
#C END
#C	loop CNT over (space separated) ARGS evaluating lines
#C	CNT counts from 0 upwards
#C	If ARGS is empty it does still evaluate the body
#C	but does not run anything (like "deploy")
#C	There is no way to access ARGS directy.
#C for CNT {VAR}
#C	allows to access {VAR:{CNT}}
#C for CNT .{VAR}
#C	ditto, but always loops a single time, even if VAR is empty
Cfor()
{
  local VAR="$1" NR=0 WAS="$PC" a
  args 1 0 "$@"
  shift

  if	[ 0 = $# ]
  then
	run '' ''			# ignore
  else
	for a in "$@"
	do
		VARS["$VAR"]="$NR"
		run "$WAS"
		let NR++
	done
  fi
  :
}

#C end STRING
#C	set end-of-data marker to STRING, default: END
#C	This marker is used in multi-line-commands to end the input.
#C	Change it in case you need this in your data.
#C	(It must stand on a separate line with no replacements etc.)
Cend()
{
  args 1 1 "$@"
  good "$1" invalid end marker
  END="$1"
}

#C set VAR STR
#C	set VAR to STRING
Cset()
{
  args 1 0 "$@"
  good "$1" invalid variable name
  setVAR "$1" "${*:2}"
}

#C replace VAR /regex/ replacement
#C replace VAR VAR2 replacement
#C	replace the given regex (in VAR2) with the given replacement
Creplace()
{
  local v="$1" r="$2"
  args 2 1 "$@"

  good "$v"
  v="${VARS["$v"]}"

  case "$r" in
  (/*/)	r="${2#/}"; r="${r%/}";;
  (*)	good "$r"; r="${VARS["$r"]}";;
  esac

  case "$r" in
  (^*\$)	;;
  (^*)		r="^()(${r#^})(.*)\$";;
  (*\$)		r="^(.*)(${r%\$})()\$";;
  (*)		r="^(.*)($r)(.*)\$";;
  esac

  if	[[ $v =~ $r ]]
  then
	setVAR "$1" "${BASH_REMATCH[1]}${*:3}${BASH_REMATCH[3]}"
  else
	printf 'NOMATCH %q=%q %q\n' "$1" "$v" "$r"
  fi
}

# This runs the given command in the container
# with the help of a script named /.deploy.sh
#
# Munchausens welcome
deploy()
{
  NEED LXC_CONTAINER_DIR

  active || return 0

  cmp -s "$LXC_BASE/wrap/deploy.sh" "$LXC_CONTAINER_DIR/rootfs/.deploy.sh" ||
	o LXCexec tee /.deploy.sh < "$LXC_BASE/wrap/deploy.sh" >/dev/null
  LXCtest -x /.deploy.sh ||
	o LXCexec chmod +x /.deploy.sh
  LXCexec /.deploy.sh "$@"
}

#C file PERM:UID:GID FILE
#C  ..
#C END
#C	Write the given data to FILE in VM
Cfile()
{
  local DATA perm user

  args 2 0 "$@"

  DATA=()
  while IFS= getline
  do
	DATA+=("$LINE")
  done

  perm="${1%%:*}"
  user="${1#"$perm"}"
  user="${user#:}"

  cmp -s - "$LXC_CONTAINER_DIR/roofs/${*:2}" < <(printf '%s\n' "${DATA[@]}") ||
  o deploy file "$perm" "$user" "${*:2}"     < <(printf '%s\n' "${DATA[@]}")
}


#C mkdir PERM:UID:GID DIR
#C	create the directory with the given permission set
#C	If PERM is missing, it is 750.
#C	If UID:GID is missing, it is unchanged (default: 0:0)
Cmkdir()
{
  local perm user

  args 2 1 "$@"

  perm="${1%%:*}"
  user="${1#"$perm"}"
  user="${user#:}"

  o deploy dir "$perm" "$user" "${*:2}"
}

#C run CMDLINE
#C	run a commandline
#C	SPC/TAB cannot be passed in args, as args are space separated
Crun()
{
  args 1 0 "$@"
  o deploy run "$@"
}

setV()
{
  local X

  case "$1" in
  (*:*)	;;
  (*)	V="${VARS["$1"]}"; return;;
  esac

  read -ra X <<<"${VARS["${1%%:*}"]}"
# printf 'X %q\n' "${X[@]}"
# printf 'N %q\n' "${1#*:}"
  # Maybe implement something different like :from-to etc.
  V="${X["${1#*:}"]}"
}

getline()
{
  local V
  [ "$PC" -le "${#LINES[@]}" ] || return
  LINE="${LINES[$PC]}"
  let PC++
  [ ".$END" != ".$LINE" ] || return
  while [[ $LINE =~ ^(.*)\{([^{}]*)\}(.*)$ ]]
  do
	setV "${BASH_REMATCH[2]}"
	LINE="${BASH_REMATCH[1]}${V}${BASH_REMATCH[3]}"
  done
  case "$LINE" in (*'{'*|*'}'*)	ERROR unexpanded "$LINE";; esac
}

proc()
{
  local LINE CMD CNR="$PC"
  getline || return

  o read -ra CMD <<<"$LINE"

  printf '%4d:' "$[PC-1]"
  printf ' %q' "${CMD[@]}"
  printf '\n'

#C #	comment line
#C	Comment lines and empty lines are skipped while reading commands
  case "$LINE" in
	(''|'#'*)	return;;
  esac

  declare -F "C$CMD" >/dev/null || ERROR unknown command: "$CMD"
  o "C$CMD" "${CMD[@]:1}"
}

# run		run current PC with current TARGET
# run ''	same
# run PC	run from PC with current TARGET
# run PC TARGET	run with given TARGET
#
# TARGET is the distribution target, see "deploy TARGET"
# If TARGET is empty nothing is executed.
run()
{
  local TARGET="${2-"$TARGET"}"
  PC="${1:-$PC}"
  while	proc; do :; done
}

setVAR()
{
  VARS["$1"]="${*:2}"
# printf 'VAR %q = %q\n' "$1" "${*:2}"
}

include()
{
  local LINES PC="$PC" INPUT="$INPUT" TMP="$LXC_BASE/deploy/$1.deploy"

  [ -z "${DONE["$1"]}" ] || return 0
  DONE["$1"]=:

  [ -f "$TMP" ] || ERROR "$TMP" missing
  mapfile -tO1 LINES <"$TMP" || ERROR cannot read "$TMP"

  printf '%4d: processing %q\n' 0 "$TMP"

  INPUT="$TMP"
  run 1
}

#settings-get GET "$LXC_CONTAINER_CFG"

declare -A VARS DONE
setVAR ARGS "${@:3}"

END=END
DEPLOY=()
TARGET=debian		# XXX TODO XXX detect this somehow!

PC=0
include "$2"

LXCexit

