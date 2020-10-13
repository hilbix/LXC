#!/bin/bash
#
#U Usage: [tag..]
#U	Squelch (ignore) the given warning message tags.
#U	If tag is missing, the list of squelchs is output.
#
# This Works is placed under the terms of the Copyright Less License,
# see file COPYRIGHT.CLL.  USE AT OWN RISK, ABSOLUTELY NO WARRANTY.

LXC_ARGS=-
ME="$(readlink -e -- "$0")" || exit
. "${ME%/*/*}/lxc-inc/lxc.inc" || exit

LXC_SQUELCH="$LXC_BASE/CFG/lxc.squelch"

if [ 0 = $# ]
then
	STDERR Remove "$LXC_SQUELCH" to re-enable all squelched tags:
	if	[ -s "$LXC_SQUELCH" ]
	then
		cat "$LXC_SQUELCH"
	else
		STDERR : there are no squelched message tags
	fi
else
	for a
	do
		fgrep -sqx "$a" "$LXC_SQUELCH" && continue
		LXCvalid "$a" invalid message tag
		echo "$a" >> "$LXC_SQUELCH" || OOPS cannot squelch "$a"
		STDERR squelched: $a
	done
fi

LXCexit

