#!/bin/sh
# The whole regression, in one command. Every claim this project makes about
# itself was checked by hand, one build and one headless run at a time, and
# nothing caught a regression but remembering to look. This is that, scripted.
#
#   tools/check-all.sh
#
# Exits non-zero if anything fails. GODOT and PBCOMPILER override the defaults.
set -u
here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/.." && pwd)
cd "$root"
GODOT=${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}
export PBCOMPILER=${PBCOMPILER:-/Applications/PureBasic.app/Contents/Resources/compilers/pbcompiler}

fails=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fails=$((fails + 1)); }

echo "== static checks =="
./tools/check-interface.sh >/dev/null 2>&1 && ok "interface matches Godot's header" || bad "interface drift"
./tools/check-returns.py   >/dev/null 2>&1 && ok "return types match declarations" || bad "return-type mismatch"

echo "== build =="
if ./build.sh --install >/dev/null 2>&1; then ok "extension builds"; else bad "extension build"; fi

echo "== demo =="
demo=$("$GODOT" --headless --path demo --quit-after 900 2>&1)
demo_rc=$?
[ "$demo_rc" = "0" ] && ok "exit 0" || bad "exit $demo_rc"
case "$demo" in *"=== demo done ==="*) ok "ran to completion";; *) bad "did not finish";; esac
case "$demo" in *"Leaked instance"*) bad "leaked instances";; *) ok "no leaks";; esac
case "$demo" in *"SCRIPT ERROR"*|*"Parse Error"*) bad "script error";; *) ok "no script errors";; esac
# content assertions: the paths that took work to get right
case "$demo" in *"GDService counter after bump+set: 41.5"*) ok "singleton property";; *) bad "singleton property";; esac
case "$demo" in *"bouncer:hi"*) ok "String argument+return";; *) bad "String argument+return";; esac
case "$demo" in *"sum(1, 2, 3)             = 6.0"*) ok "variadic method";; *) bad "variadic method";; esac
case "$demo" in *"variadic call rejected"*) ok "vararg rejection reaches r_error";; *) bad "vararg rejection";; esac
case "$demo" in *"Vector2(3,4).length()            = 5.0"*) ok "builtin method wrapper";; *) bad "builtin method wrapper";; esac
case "$demo" in *"normalized()        = (0.6, 0.8)"*) ok "builtin struct return";; *) bad "builtin struct return";; esac

echo "== selftest =="
if (cd selftest && ./build.sh >/dev/null 2>&1); then ok "selftest builds"; else bad "selftest build"; fi
st=$("$GODOT" --headless --path selftest/godot --quit-after 900 2>&1)
case "$st" in *"0 PARTIAL"*) ok "every bind agrees with the engine";; *) bad "bind mismatch";; esac
case "$st" in *"Leaked instance"*) bad "selftest leaks";; *) ok "selftest no leaks";; esac

echo "== skeleton =="
if (cd skeleton && "$PBCOMPILER" example.pb -dl /tmp/gdex_skeleton_check.dylib >/dev/null 2>&1); then
  ok "skeleton compiles"
else
  bad "skeleton build"
fi
rm -f skeleton/purebasic.c /tmp/gdex_skeleton_check.dylib

echo
if [ "$fails" = "0" ]; then
  echo "all checks passed"
else
  echo "$fails check(s) FAILED"
fi
exit $([ "$fails" = "0" ] && echo 0 || echo 1)
