#!/bin/sh
# Compare gdextension_interface.pbi, the hand transcription, against Godot's own
# header. PureBasic cannot use the header's declarations directly - it mangles
# its own structures to s_<name> and generates field access against that - so
# the two have to be kept in step, and this is what keeps them honest.
#
# A size is not a full structural check, but it catches the failure that
# matters: Godot pads its structures and PureBasic packs, so one missing
# `Align #PB_Structure_AlignC` makes every field after it read from the wrong
# offset, silently.
set -e
here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/.." && pwd)
PB=${PBCOMPILER:-/Applications/PureBasic.app/Contents/Resources/compilers/pbcompiler}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

clang -I"$root" -o "$tmp/iface_sizes" "$here/iface_sizes.c"
"$tmp/iface_sizes" | sort > "$tmp/c.txt"

"$PB" "$here/iface_sizes.pb" -cl -q -o "$tmp/iface_sizes_pb" >/dev/null
"$tmp/iface_sizes_pb" | grep '^GDExtension' | sort > "$tmp/pb.txt"

if diff -u "$tmp/c.txt" "$tmp/pb.txt" > "$tmp/diff.txt"; then
  echo "interface: all $(wc -l < "$tmp/c.txt" | tr -d ' ') structures match Godot's header"
else
  echo "interface DRIFT - header vs gdextension_interface.pbi:" >&2
  cat "$tmp/diff.txt" >&2
  exit 1
fi
