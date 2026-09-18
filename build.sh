#!/bin/sh
# Build libgdexample.dylib from the PureBasic sources.
#
#   ./build.sh              -> libgdexample.dylib here, signed in place
#   ./build.sh --install    -> also copy into demo/ and sign it THERE
#
# Run from anywhere; the script cd's to its own directory.
#
# THIS SCRIPT ONLY COMPILES. It does not run the binding generator, and it
# never touches generated/. See generate-bindings.sh for that - it is a
# one-time step, run when you start using the framework and again only when
# you want more engine classes.
#
# Keeping the two apart is deliberate:
#
#   * the build stays independent of Godot's extension_api.json, which lives in
#     a sibling checkout and has nothing to do with compiling your code;
#   * generated/ behaves like source - generated once, committed, then stable,
#     so a build cannot silently change what your extension is bound against;
#   * a build failure means your code is wrong, not that a 7 MB JSON dump moved.
#
# WHY -dl. That is what makes pbcompiler emit a dynamic library instead of an
# executable; the file has no main program, it only exports
# gdexample_library_init.
#
# WHY codesign. Not strictly required - the linker already ad-hoc signs arm64
# output, and that is what actually makes it loadable. It is kept because it
# costs nothing and covers a build that comes out unsigned, which macOS refuses
# to load.
#
# WHY purebasic.c IS DELETED. pbcompiler's C backend drops its intermediate
# next to whatever it compiled, which otherwise leaves a stray purebasic.c in
# the project root after every build.
set -e
here=$(cd "$(dirname "$0")" && pwd)
cd "$here"

PB=${PBCOMPILER:-/Applications/PureBasic.app/Contents/Resources/compilers/pbcompiler}
if [ ! -x "$PB" ]; then
  echo "pbcompiler not found at $PB - set PBCOMPILER to its path" >&2
  exit 1
fi

INSTALL=0
for arg in "$@"; do
  case "$arg" in
    --install) INSTALL=1 ;;
    -h|--help)
      sed -n '2,5p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *)
      echo "unknown option: $arg" >&2
      exit 1 ;;
  esac
done

if [ ! -d generated ] || [ -z "$(ls -A generated 2>/dev/null)" ]; then
  echo "generated/ is empty or missing." >&2
  echo "Run ./generate-bindings.sh once to create it." >&2
  exit 1
fi

# generated/ is committed source rather than build output, so it can go stale -
# a file left over from an older generator that includes something since
# removed. pbcompiler does report that, but as a File-not-found from the middle
# of an included file. Catch it here with an instruction instead. A check, not
# a generation: nothing is written.
dangling=$(grep -rh '^IncludeFile "' generated/*.pbi 2>/dev/null \
           | sed 's/^IncludeFile "//; s/"$//' | sort -u \
           | while read -r inc; do [ -f "generated/$inc" ] || echo "$inc"; done)
if [ -n "$dangling" ]; then
  echo "generated/ is stale: it includes files that are not there." >&2
  echo "$dangling" | sed 's/^/  /' >&2
  echo "Run ./generate-bindings.sh to rebuild it." >&2
  exit 1
fi

rm -f libgdexample.dylib
"$PB" gdexample.pb -dl libgdexample.dylib
rm -f purebasic.c

codesign -s - -f libgdexample.dylib >/dev/null 2>&1 || {
  echo "warning: codesign failed; the dylib may not load on Apple Silicon" >&2
}

if [ "$INSTALL" = 1 ]; then
  cp libgdexample.dylib demo/libgdexample.dylib
  codesign -s - -f demo/libgdexample.dylib >/dev/null 2>&1 || true
  echo "installed into demo/"
fi

printf "  exports: %s\n" "$(nm -gU libgdexample.dylib | grep -c " T _")"
printf "  size:    %s bytes\n" "$(wc -c < libgdexample.dylib | tr -d ' ')"
