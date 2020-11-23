#!/bin/bash
#
#U Usage: CONTAINER [CMD [TAG[=line]..]]
#U	CONTAINER TAGs management
#
# This Works is placed under the terms of the Copyright Less License,
# see file COPYRIGHT.CLL.  USE AT OWN RISK, ABSOLUTELY NO WARRANTY.

LXC_ARGS=1-
ME="$(readlink -e -- "$0")" || exit
. "${ME%/*/*}/lxc-inc/lxc.inc" || exit

#U	Valid characters in TAGs are ASCII letters and digits and _ and -
#U	All TAGs with lowercase letter are reserved or have a special meaning.
checktag()
{
  LXC_tag="${1%%=*}"
  LXC_inf="${1#"$LXC_tag"}"
  case "$LXC_inf" in
  (*$'\n'*)	OOPS sorry: Extended info cannot contain a linefeed;;
  esac
  LXCvalidU "$LXC_tag"
  o mkdir -p "$TAG_DIR"
  tag="$TAG_DIR/$LXC_tag"
}

#U	Also some information can be set using the format 'TAG=line'
tagknown()
{
  x grep -Fsqx "$LXC_inf" "$tag"
}

tagset()
{
  if	[ -n "$LXC_inf" ]
  then
	tagknown && return 1	# already present, nothing to do
	echo "$LXC_inf" >> "$tag" || OOPS cannot write "$tag"
  elif	[ -f "$tag" ]
  then
	return 1		# already exists, nothing to do
  fi

  o touch "$tag"		# create (only touch when missing!)
}

tagunset()
{
  [ -f "$tag" ] || return	# does not exist, nothing to do

  if	[ -z "$LXC_inf" ]
  then
	[ -s "$tag" ] && OOPS extendet info prevents removal of TAG "$LXC_tag"

	o rm -f "$tag"		# only remove empty files
	return
  fi

  # remove extended info
  tagknown || return 1		# not present, nothing to do

  awk -v INF="$LXC_inf" '$0!=INF { print }' "$tag" >> "$tag.tmp" || OOPS cannot write "$tag.tmp"
  o mv -f "$tag.tmp" "$tag"
}


#T marks CONTAINER as autostart
#T	note that autostart is not yet implemented,
#T	but this prohibits to set the 'delete' tag
Tautostart()
{
  notSet delete
}

#T makes LXC stop CONTAINER fail
#T	Note that we cannot protect the container against
#	low level commands like 'lxc-stop'.
Tunstoppable()
{
  notSet delete
}

#T make CONTAINER deleteable
#T	without this tag 'LXC remove' fails
Tdelete()
{
  notRunning
  notForceable
  notSet autostart protect unstoppable
}

#T protects the CONTAINER against delete
#T	Note that we cannot protect the container against
#	low level commands like 'rm' or 'lxc-destroy'.
Tprotect()
{
  notSet delete
}

#U	Valid CMDs:
#U	check	Checks if a tag is present or not
do-check()
{
  NEED tag

# report all.  To just report the first missing:
# [ 0 = "$LXC_MURX" ] || return		# we already have some result

  if	[ -n "$LXC_inf" ]
  then
	infknown || FAIL missing extended info 'in' TAG "$LXC_tag"
	return
  fi

  [ -f "$TAG_DIR/$LXC_tag" ] || FAIL missing TAG "$LXC_tag"
}

#U	help	Explains a tag or lists all known tags
dohelp()
{
  :
}

#U	list	(default) Lists all set tags (when no tags are given)
d0-list()
{
  for tag in "$TAG_DIR"/*
  do
	[ -f "$tag" ] || { WTF="$tag"; continue; }
	name="${tag##*/}"
	case "$name" in
	(*[^0-9a-zA-Z_-]*)    WTF="$tag"; continue;;
	esac
	if	[ -s "$tag" ]
	then
		read -ru line <"$tag" || :
		printf '%s	%s\n' "$name" "$line"
	else
		echo "$name"
	fi
  done
}

do-list()
{
  NEED tag

  [ -f "$tag" ] || FAIL missing TAG "$LXC_tag" || return
  echo "$LXC_tag:"
  cat "$tag"
}

#U	set	Defines a tag.  Fails if it is in conflict with other TAGs
do-set()
{
  NEED tag

  case "$LXC_tag" in
  ([^a-z]*)	declare -F "T$LXC_tag" >/dev/null || OOPS unknown or reserved TAG "$LXC_tag"
		"T$LXC_tag"
		;;
  esac

  vb noted test -s "$tag"
  vb known test -f "$tag"

  tagset || return

  $noted && STDOUT extended TAG "$LXC_tag" && return
  $known && STDOUT updated TAG "$LXC_tag" && return

  STDOUT new TAG "$LXC_tag"
}

#U	unset	Removes a tag.  This fails if the tag's file is nonempty.
do-unset()
{
  NEED tag

  tagremove || return

  [ -n "$LXC_inf" ] && STDOUT shrunk TAG "$LXC_tag" || STDOUT removed TAG "$LXC_tag"
}

LXCcontainer "$1"
TAG_DIR="$LXC_BASE/LXC/$LXC_CONTAINER/tags"
shift
CMD="$1"
shift || CMD=list

declare -F "do-$CMD" >/dev/null || OOPS unknown command "$CMD"

if	[ 0 = "$#" ]
then
	declare -F "d0-${CMD}" >/dev/null || OOPS "$CMD:" please specify tag on commandline
	"d0-$CMD"
else
	for tag
	do
		checktag "$tag"
		"do-$CMD"
	done
fi

#U	!WARNING!
#U	TAGS ARE CURRENTLY NOT IMPLEMENTED CORRECTLY.
#U	Until this is fixed the description of TAGs is WRONG in many respects
LXCexit

