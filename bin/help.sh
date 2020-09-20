#!/bin/bash
#
#U Usage: [cmd]
#U	List possible commands or print help for command
#
# This Works is placed under the terms of the Copyright Less License,
# see file COPYRIGHT.CLL.  USE AT OWN RISK, ABSOLUTELY NO WARRANTY.

ME="$(readlink -e -- "$0")" || exit
. "${ME%/*/*}/lxc-inc/lxc.inc" || exit

had=false
for a
do
	check-name "$a" && [ -x "$BASE/bin/$a.sh" ] || WARN unknown command: "$a" || continue
	$had ||
	cat <<EOF

Notes for all commands:
- Usage is printed if the first arg is -h or --help
- All recognize environment variables, see: LXC diag
- Most automatically invoke 'setup' if needed
- Scripts are located at $BASE/bin/

Standard RC if not noted otherwise:
- 0 positive reply (command OK)
- 1 negative reply (command failed)
- 2 warnings reply (command OK but partially failed)
- 23 something weird happened (AKA: OOPS)
- 42 Usage/Help was printed

EOF
	had=:
	if	[ -z "$LXC_USAGE" ]
	then
		Help "$BASE/bin/$a.sh"
	elif [ lxc = "$a" ]
	then
		Help "$BASE/bin/$a.sh" "${LXC_USAGE%% *}"
	else
		Help "$BASE/bin/$a.sh" "${LXC_USAGE%% *} $a"
	fi
done

echo
$had && exit $MURX

for a in "$BASE"/bin/*.sh
do
	[ -x "$a" ] || continue
	ov b basename -- "$a" .sh
	o awk -vCMD="$b" -vBASE="$BASE" '
		function out(s) { if (ARGS) printf "%-30s %s\n", CMD ARGS, s; ARGS="" }
					{ gsub(/{PATH}/, BASE) }
		$1=="#U" && $2=="Usage:" { $1=""; $2=""; $3=""; gsub(/^  */," "); ARGS=$0; next; }
		$1=="#U" && ARGS	{ $1=""; sub(/^ /,"\t"); out($0) }
		END			{ out() }
		' "$a"
done

echo
finish

