#!/bin/bash
#
#U Usage: [cmd]
#U	List possible commands or print help for command
#
# This Works is placed under the terms of the Copyright Less License,
# see file COPYRIGHT.CLL.  USE AT OWN RISK, ABSOLUTELY NO WARRANTY.

LXC_ARGS=-1
ME="$(readlink -e -- "$0")" || exit
. "${ME%/*/*}/lxc-inc/lxc.inc" || exit

Human DIAG diag
had=false
for a
do
	LXClocate CMD "$a" || WARN unknown command: "$a" || continue

	$had ||
	cat <<EOF

Notes for all commands:
- Usage is printed for commandline arguments -h or --help
- Most commands allow some environment variables, see command: $DIAG
- Most commands automatically invoke 'setup' if needed
- Commands' scripts are located at $LXC_BASE/bin/

Standard RC if not noted otherwise:
- 0 positive reply (command OK)
- 1 negative reply (command failed)
- 2 warnings reply (command OK but partially failed)
- 23 something weird happened (AKA: OOPS)
- 42 Usage/Help was printed

EOF
	had=:
	if	[ -z "$LXC_WRAPPER" ]
	then
		Help "$CMD" "$CMD"
	elif [ lxc = "$a" ]
	then
		Help "$CMD" "$LXC_WRAPPER"
	else
		Help "$CMD" "$LXC_WRAPPER $a"
	fi
done

echo
$had && LXCexit

LIST=()
len=0
for a in "$LXC_BASE"/bin/*.sh
do
	[ -x "$a" ] || continue
	ov b basename -- "$a" .sh
	o Human CMD "$b"
	ov LINE awk -vCMD="$CMD" -vBASE="$LXC_BASE" '
		function out(s) { if (ARGS) printf "%s\t%s\n", CMD ARGS, s; ARGS="" }
					{ gsub(/{PATH}/, BASE) }
					{ gsub(/\t/, " ") }
					{ gsub(/   */, " ") }
		$1=="#U" && $2=="Usage:" { $1=""; $2=""; sub(/^   */, " "); ARGS=$0; next; }
		$1=="#U" && ARGS	{ $1=""; sub(/^ /,""); out($0) }
		END			{ out("") }
		' "$a"
	LIST+=("$LINE")
	LINE="${LINE%%$'\t'*}"
	[ "$len" -lt "${#LINE}" ] && len="${#LINE}"
done

for a in "${LIST[@]}"
do
	printf '%-*s\t%s\n' "$len" "${a%%$'\t'*}" "${a#*$'\t'}"
done

echo
LXCexit

