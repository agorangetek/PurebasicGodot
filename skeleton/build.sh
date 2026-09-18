#!/bin/sh
# Build the skeleton extension and drop it into its Godot project.
#
#   ./build.sh
#   cd godot && /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --quit-after 300
#
# This is deliberately not the same script as ../build.sh: that one builds the
# main extension and regenerates the framework's bindings, neither of which
# applies to an extension that only uses the framework.
set -e
here=$(cd "$(dirname "$0")" && pwd)
cd "$here"

PB=${PBCOMPILER:-/Applications/PureBasic.app/Contents/Resources/compilers/pbcompiler}
if [ ! -x "$PB" ]; then
  echo "pbcompiler not found at $PB - set PBCOMPILER to its path" >&2
  exit 1
fi

# -dl makes it a dynamic library rather than an executable; the file has no
# main program, it only exports example_library_init.
rm -f libexample.dylib
"$PB" example.pb -dl libexample.dylib
rm -f purebasic.c

# Ad-hoc sign, and sign the COPY WHERE IT LANDS: the signature covers the file
# as it sat when signed, and macOS kills an unsigned or stale-signed dylib with
# no error message at all.
codesign -s - -f libexample.dylib
cp libexample.dylib godot/libexample.dylib
codesign -s - -f godot/libexample.dylib

printf "  exports: %s\n" "$(nm -gU libexample.dylib | grep -c " T _")"
printf "  size:    %s bytes\n" "$(wc -c < libexample.dylib | tr -d ' ')"
echo "installed into godot/"
