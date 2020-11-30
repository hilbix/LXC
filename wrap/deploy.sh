#!/bin/sh
#
# Arbitrary deployment script

CMD="$1"
shift || exit

perm()
{
  [ -z "$1" ] || chmod -- "$@"
}

user()
{
  [ -z "$1" ] || chown -- "$@"
}

test file = "$CMD" &&
{
  cat > "$3" && user "$2" "$3" && perm "$2" "$3"
  exit
}

test dir = "$CMD" &&
{
  [ -d "$3" ] || mkdir -- "$d" && user "$2" "$3" && perm "$1" "$3"
  exit
}

test run = "$CMD" &&
{
  exec sh -xc "$*"
  exit 1
}

echo "unknown cmd $CMD"
exit 1

