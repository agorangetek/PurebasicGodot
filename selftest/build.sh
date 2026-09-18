#!/bin/sh
# Build the self-test extension and drop it into its Godot project.
#
#   ./build.sh
#   cd godot && /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --import
#   cd godot && /Applications/Godot.app/Contents/MacOS/Godot --headless --path .
set -e
here=$(cd "$(dirname "$0")" && pwd)
cd "$here"

PB=${PBCOMPILER:-/Applications/PureBasic.app/Contents/Resources/compilers/pbcompiler}
if [ ! -x "$PB" ]; then
  echo "pbcompiler not found at $PB - set PBCOMPILER to its path" >&2
  exit 1
fi
if [ ! -f ../generated/selftest.pbi ]; then
  echo "../generated/selftest.pbi is missing. Run ../generate-bindings.sh first." >&2
  exit 1
fi

rm -f libselftest.dylib
"$PB" selftest.pb -dl libselftest.dylib
rm -f purebasic.c
codesign -s - -f libselftest.dylib >/dev/null 2>&1 || true
cp libselftest.dylib godot/libselftest.dylib
codesign -s - -f godot/libselftest.dylib >/dev/null 2>&1 || true

printf "  exports: %s\n" "$(nm -gU libselftest.dylib | grep -c " T _" || true)"
printf "  size:    %s bytes\n" "$(wc -c < libselftest.dylib | tr -d ' ')"
echo "installed into godot/"
