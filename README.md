# PureBasic GDExtension — reconstructed

A working Godot 4 GDExtension whose framework and classes are written in
PureBasic, built into one dylib by `pbcompiler`, and loaded by Godot through a
`.gdextension` file.

This is the `gdex_*.pbi` framework that the recovered `gdexample.pb` refers to.
That framework was never saved anywhere recoverable: only two files came back
from it. `gdexample.pb` here is the recovered file **verbatim**, and
`gdextension_interface.pbi` is the recovered transcription of Godot's
`GDExtensionInterface` with the single `Align #PB_Structure_AlignC` edit
described under [gotcha 1](#1-purebasic-packs-structures-c-pads-them).
Everything else was written to satisfy those two.

Status: **builds and runs.** `./build.sh --install` then running `demo/`
produces the same lines the original Aug-27 log recorded, plus a signal
emitted from PureBasic.

```
GDService singleton: class=GDService | counter=0.0
GDService counter after bump+set: 41.5
```

## Starting a project from nothing: `pb_gdext_wizard`

```
pb_gdext_wizard <godot-executable> <project-name> [destination]
```

Given a Godot binary and a name, this builds a complete, compilable project:

* asks for a folder with the system folder picker (a third argument skips it,
  which is also what makes the wizard scriptable);
* creates `<destination>/<project-name>/`;
* runs `<godot> --headless --dump-extension-api` and generates the bindings
  from **that** dump — so the project is bound to the engine you named, not to
  whatever dump this repo happens to ship;
* copies the framework, an entry file and a Godot project in, and puts the name
  where it has to appear (`<name>_library_init`, `lib<name>.dylib`,
  `<name>.gdextension`);
* prints the commands to build and run it.

The framework is copied from the checkout the tool lives in
(`GetPathPart(ProgramFilename()) + "../"`), so there is exactly one copy of it
in the world and nothing can drift. The skeleton's `../` includes are
flattened on the way, because a project root is no longer a sibling of the
framework.

`extension_api.json` (~7 MB) is left in `<project>/api/`; it is what
`generated/` was produced from, so keep it if you want to regenerate later.
Note that it comes from the binary you passed, so a 4.8 Godot produces 4.8
bindings, while the `generated/` this project was developed against came from
4.7.

### One measured PureBasic caveat

`ProgramRunning()` and `CloseProgram()` **segfault** on the Godot child process
here (exit 139), with the dump written correctly anyway. The wizard therefore
does not track the child at all: it deletes the target file, starts the dump,
and waits for that file to appear and stop growing. If you wrap Godot yourself,
do the same.

## Getting started with your own extension

`GETTING_STARTED.md` walks through it, and `skeleton/` is a complete working
extension to copy — one class, one property, one `_process`, verified building
and running.

### The whole extension, after the classes

```purebasic
Procedure GDEX_RegisterClasses()
  GDREGISTER_SINGLETON(gdservice_class, "GDService", "Object")
  GDREGISTER_CLASS(gdexample_class, "GDExample", "Sprite2D")
EndProcedure

Procedure GDEX_ResolveBinds()
  Register_Object_Binds()   ; emit_signal
  Register_Node2D_Binds()   ; set_position, rotate, ...
EndProcedure

GDEX_EXTENSION(gdexample_library_init)
```

Two hooks and one line. The framework calls the first once, at the lowest
level, and works out from each class's parent whether it can be registered at
CORE or has to wait for SCENE — so there is no `p_level` ladder, and no
`initialize`/`deinitialize` callback to write either.

`GDREGISTER_SINGLETON` registers the class *and* the singleton in one line - a
singleton is an *instance of* the class, so naming the descriptor once makes it
impossible to register a singleton of a class you forgot to register - and at
deinitialize it unregisters the instance at the level it was created *and*
destroys it, which is what silences both the *"extension class is still
registered at exit"* warnings and the leaked-instance report for the singleton
itself.

`GDEX_ResolveBinds()` is separate because it genuinely has to wait: a scene
class has no MethodBind before SCENE, and resolving one early returns null
(Godot reports `Parameter "mb" is null`). It is the one part of the setup you
still have to get right — and forgetting a class there no longer passes in
silence. Every generated wrapper checks its own bind, and when one is missing it
names itself and the remedy, once per method rather than once per call:

```
ERROR: [gdex] Node2D::set_position: no method bind was resolved, so this call did nothing.
       Either Register_Node2D_Binds() is missing from GDEX_ResolveBinds(),
       or this engine build has no such method - pb_gdext_wizard --check tells them apart.
```

The distinction the message draws matters: a *missing bind* is a setup mistake
and is reported, while a *null instance* is an ordinary runtime condition and
stays quiet. The report survives the mistake it describes because each generated
file takes the reporter's address at top level, where it runs whether or not
`Register_<Class>_Binds()` was ever called.

Both hooks must exist even if they are empty; `selftest/selftest.pb` has two
empty ones you can copy.

## Build and run

```sh
./generate-bindings.sh                    # ONCE, before you start writing code
./build.sh --install                      # compile + sign -> demo/
cd demo
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --import   # once, registers the classes
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --quit-after 900
```

**`build.sh` does not run the generator**, on purpose. The two are separate
steps with separate lifetimes:

| | |
|---|---|
| `./generate-bindings.sh` | **Once**, before you start writing a GDExtension. Walks `extension_api.json`, writes one file per engine class into `generated/`. Re-run only to add classes or move to a newer Godot. |
| `./build.sh` | Compile `gdexample.pb`, sign it, optionally install into `demo/`. Never touches `generated/`. |

Keeping them apart is deliberate:

* the build stays independent of Godot's 7 MB API dump, which lives in a
  sibling checkout and has nothing to do with compiling your code;
* `generated/` is produced once and then left alone, so a build cannot
  silently change what your extension is bound against;
* a build failure means your code is wrong, not that a JSON dump moved.

Whether `generated/` is committed is a per-repo choice and nothing here depends
on it: **this project's published repo excludes `generated/*.pbi`** (only the
hand-written `generated/helpers/` is tracked), so a fresh clone runs
`./generate-bindings.sh` once before its first build.

If `generated/` is missing, `build.sh` says so and stops rather than trying to
fix it:

```
generated/ is empty or missing.
Run ./generate-bindings.sh once to create it.
```

The generator can produce the whole library: all 870 classes that have
methods, one self-contained file each, 11 MB on disk once generated.
`generate-bindings.sh` with no class arguments generates everything; name
classes to generate just those:

```sh
./generate-bindings.sh                        # all 870
./generate-bindings.sh Sprite2D AnimationPlayer
./generate-bindings.sh --check                # verify what is already there
```

Generating all 870 and verifying all 15 389 hashes (the 15 385 in the class
files, plus the framework's own four in `gdex_class.pbi`) costs about **1.3 s**,
and it does *not* make the extension bigger: only the files the entry point
`IncludeFile`s are compiled, so the dylib is the same 101 KB either way. The
rest simply sit there, ready to be included. Generation is additive — naming a
class never deletes the others.

`GDEXT_API` points the generator at a different dump. Without it, the script
looks for `../prototype_gdext/godot-cpp/gdextension/extension_api-4-7.json` — a
4.7 dump that only exists in the author's working checkout, and the one the
`generated/` here was produced from — so **in a fresh clone set `GDEXT_API`**,
or make your own with `godot --headless --dump-extension-api` and point at
that.

To use a class:

```purebasic
IncludeFile "generated/Sprite2D.pbi"
```

**The framework depends on no generated file.** `gdex_class.pbi` resolves the
four engine methods it needs (two on `Node`, two on `Engine`) itself, so a
project that uses only `Sprite2D` includes one class file and nothing else.
That is also a correctness measure, not just tidiness: these files do not
`EnableExplicit`, so a merely *missing* name does not fail the build —
PureBasic silently invents a local and the call does nothing.

`--quit-after` is not decorative: if a script fails to parse, Godot has no main
scene, never calls `quit()`, and runs forever. See gotcha 3.

`--import` is required the first time (and after adding a class): GDScript
resolves extension classes as global names, and that only happens once Godot
has rescanned the project.

**On Godot 4.8.dev6 that `--import` exits 134 and prints a crash** in
`EditorHelp::_gen_extensions_docs` -> `DocTools::generate` ->
`HashMap<String, DocData::ClassDoc>::operator[]`. This is a Godot bug in
editor documentation generation for *any* GDExtension, not something this
extension does: the Beef extension in `../beef-gdext/probe_project`, built
with a completely different binding, crashes with the identical backtrace on a
fresh import. The scan still completes and writes `.godot/`, so the very next
command runs normally — verified from a clean tree:

```
--import   -> exit 134, backtrace, .godot/ written
--path .   -> exit 0, the demo output below
```

Signing is required, but `build.sh`'s `codesign` is belt-and-braces rather than
the thing that makes it work — measured, not assumed:

* `pbcompiler`'s output is **already ad-hoc signed**, by the linker:
  `flags=0x20002(adhoc,linker-signed)`, `Signature=adhoc`. That is `ld`'s
  default for arm64.
* Strip it with `codesign --remove-signature` and Godot refuses to load it —
  though it says so plainly (`Can't open dynamic library ... missing code
  signature`), rather than dying silently.
* A plain `cp` of a signed dylib **does** keep working: an ad-hoc signature
  hashes the code pages, so an identical copy at another path still validates.

So the IDE path is safe on this point. `build.sh` keeps the explicit `codesign`
because it costs nothing and covers the case where a build produces something
unsigned.

## What is here

| File | What it is |
|---|---|
| `gdexample.pb` | The recovered file, **verbatim**. The entry point and the GDExample class. |
| `gdex_defs.pbi` | Constants, the framework structures, and shared globals. |
| `gdex_api.pbi` | `load_api`, the resolved function pointers, StringName/Variant helpers. |
| `gdextension_interface.pbi` | The recovered transcription of Godot's whole `GDExtensionInterface`. Verified against the header below by `tools/check-interface.sh`. |
| `gdextension_interface.h` | Godot's real header, vendored. Not compiled into the extension — it is the authority the transcription is checked against. |
| `tools/check-interface.sh` | Compares the two. `iface_sizes.pb` / `iface_sizes.c` are its two halves. |
| `gdex_class.pbi` | The framework: `RegisterGDClass`, every generic callback, the macros. |
| `tools/pb_gdext_wizard.pb` | The generator, in PureBasic. `--outdir`, `--out`, `--check`, `--stats`. |
| `generate-bindings.sh` | The one-time step. Writes `generated/` from the API dump. |
| `generated/` | Self-contained files produced by `generate-bindings.sh`: 870 engine classes, 34 builtin types and `GlobalScope.pbi`. Not tracked in this project's repo; `build.sh` never touches it. |
| `generated/helpers/` | The one hand-written thing under `generated/`: the godot-cpp-shaped class surface. See [The helper layer](#the-helper-layer). |
| `gdex_bouncer.pbi` | `GDBouncer`, a second Node2D class with its own `bounced` signal. |
| `gdex_ticker.pbi` | `GDTicker`, a Node installed as the `GDNativeTicker` singleton. |
| `gdex_service.pbi` | `GDService`, an `Object` singleton registered at CORE. |
| `gdex_probe.pbi` | `GDSignalProbe` / `GDSignalPing`: one signal, many payload types. |
| `demo/` | The Godot project, `gdex.gdextension`, and the smoke test. |
| `selftest/` | A GDExtension that checks every bind in `generated/` against the running engine. |
| `build.sh` | Build, sign, optionally install. |

## How it works

An instance is laid out as

```
instance -> [ GDObject { object, class_info } ][ the user's own fields ]
```

`GDObject` is first because every generic callback Godot makes hands back only
the instance pointer, and `class_info` is how a callback gets from there to the
per-class descriptor. Each user class supplies a `GDClassInfo` naming its size,
constructor, destructor, optional `process` and a `bind_func`; `RegisterGDClass`
does the rest, including registering it at the level its parent needs.

One set of callbacks serves every class:

* `create_instance_func` constructs the nearest **native ancestor** with
  `classdb_construct_object3` — constructing our own extension class name would
  re-enter this function — then allocates the instance, calls the user's
  constructor, and binds it with `object_set_instance` plus
  `object_set_instance_binding`. Allocation goes through the class's optional
  `alloc_func` when it has one (see gotcha 4).
* `set_func` / `get_func` dispatch by StringName to the per-class property
  table, converting through Variants.
* `get_virtual_call_data_func` + `call_virtual_with_data_func` answer Godot's
  "is `_process` overridden?" and deliver the delta, which is how every
  `process` function runs. `notification_func` at `NOTIFICATION_PROCESS` is the
  alternative, selected by `gdex_process_via_notification`.
* Methods all share two dispatchers; which procedure to run comes from
  `method_userdata`, so no trampoline is generated per method.

A class's `bind_func` declares its surface with `ClassDB::bind_method` and
`ADD_PROPERTY`, as shown under [Declaring a class](#declaring-a-class) below.
The `get_<name>` / `set_<name>` methods that `ADD_PROPERTY` names are what make
`obj.amplitude` work from GDScript; the class-wide `get_func`/`set_func`
callbacks handle `obj.get(...)` and `obj.set(...)`.

## Methods and properties of Godot builtin types

Any plain builtin can cross the boundary, and **nothing is special-cased per
type**. A method entry carries the Variant type and the native size, so the
framework converts generically:

```purebasic
Procedure GDBouncer_axes(*self.GDBouncer, *out.GDVector3)
  *out\x = *self\amplitude
  *out\y = *self\speed
  *out\z = *self\phase
EndProcedure
...
ClassDB::bind_method(D_METHOD("axes"), @GDBouncer_axes(), #VECTOR3)
```

Two conventions:

* **PureBasic moves structures only by pointer.** `Procedure Foo(v.Vec)` is a
  syntax error; `Procedure Foo(*v.Vec)` is not — there is no by-value structure
  parameter. So a builtin argument arrives as a typed pointer, and a builtin
  result comes back through a caller-provided `*out`. That also matches Godot's
  own contract: the callback is handed `r_ret` pointing at storage Godot owns,
  so it must write there. The three shapes are `(*self, *out)`,
  `(*self, *in)` and `(*self, *in, *out)`, and callers pass addresses —
  a caller builds a `GDVector2` and passes `@v` to the generated wrapper.

  PureBasic *can* return an address — `Procedure.i` whose result is assigned to
  a `*Type` variable — but that needs storage the wrapper does not own: a heap
  allocation the caller must free, or a static buffer that is not reentrant.
  The out-parameter avoids both, which is why it is the convention here.
* **The Variant type and the structure must agree.** Pass the constant and the
  matching type from `gdex_types.pbi`.

The binding call states the signature rather than naming a macro for it: the
trailing `#`-constants of `ClassDB::bind_method` are
`(return, arg0, arg1, arg2, arg3)`, and the procedure's own signature follows
from them - `() -> T` is `(..., @Proc(), #T)`, `(T) -> void` is
`(..., @Proc(), #VOID, #T)`, and `(T) -> U` is `(..., @Proc(), #U, #T)`. See
the table under [Declaring a class](#declaring-a-class).

### More than one argument

C++ reads a whole signature off the member function pointer, so godot-cpp never
counts arguments. A PureBasic procedure pointer carries no signature, and there
are no templates or varargs, so every signature is a shape the framework has to
be told about. A method may declare up to `#GDEX_MAX_METHOD_ARGS` (4).

Two arguments that are both scalars name their parameters, exactly as in C++:

```purebasic
Procedure.d GDBouncer_mix(*self.GDBouncer, a.d, b.d)
  ProcedureReturn *self\amplitude * a + *self\speed * b
EndProcedure
ClassDB::bind_method(D_METHOD("mix", "a", "b"), @GDBouncer_mix(), #FLOAT, #FLOAT, #FLOAT)
```

Everything the typed shapes do not cover - three or more arguments, or a
builtin anywhere in a multi-argument list - goes through one generic shape:

```purebasic
Procedure GDBouncer_grow_by(*self.GDBouncer, *args, *out.GDRect2)
  Protected *v.GDVector2 = GDEX_ArgPtr(*args, 0)
  Protected f.d = GDEX_ArgD(*args, 1)
  *out\size\x = *v\x * f
  *out\size\y = *v\y * f
EndProcedure
ClassDB::bind_method(D_METHOD("grow_by", "size", "factor"), @GDBouncer_grow_by(), #RECT2, #VECTOR2, #FLOAT)
```

A generic-shape callee always has the shape `(*self, *args, *out)`. `*args` is
an array of pointers, one per declared argument, each aimed at that argument's
native value, and `GDEX_ArgPtr` / `GDEX_ArgD` / `GDEX_ArgL` read the Nth. The
result is written through `*out`, which is storage for the declared return type
and is `0` when the method returns nothing.

That is deliberately the shape of the raw GDExtension `call_func` ABI - the
array-of-pointers form godot-cpp's templates exist to hide. Carrying the types
in the entry instead of in the signature is what makes arity unlimited here
too, rather than capped at the typed signatures.

### What can be returned

The supported builtins, with the native size taken from Godot's own
`extension_api.json` for the `float_64` configuration (single-precision
`real_t`, 64-bit pointers — what an official macOS build is). All sixteen are
declared in `gdex_types.pbi` and **verified equal to Godot's numbers** by a
compile-time `SizeOf` comparison:

| Type | Bytes | | Type | Bytes |
|---|---|---|---|---|
| `Vector2` | 8 | | `Vector4` | 16 |
| `Vector2i` | 8 | | `Plane` | 16 |
| `Rect2` | 16 | | `Quaternion` | 16 |
| `Rect2i` | 16 | | `Color` | 16 |
| `Vector3` | 12 | | `AABB` | 24 |
| `Vector3i` | 12 | | `Basis` | 36 |
| `Transform2D` | 24 | | `Transform3D` | 48 |
| `Projection` | 64 | | `RID` | 8 |

The demo returns Vector2, Vector3, Rect2, Transform2D and Transform3D and reads
back a Color property, so the nested cases (struct-of-structs, embedded arrays)
are exercised, not just the flat ones.

### What is not covered

They are the **pointer types**, and they now cross the boundary — but not the
way a builtin does. `String`, `StringName`, `NodePath`, `Object`, `Dictionary`,
`Array`, `Callable` and `Signal` are handles onto storage Godot owns, so their
bytes cannot be copied with `FillMemory` or released with `FreeMemory`. Passing
one is a three-step borrow:

* the framework **constructs** the native value from the Variant (Godot's
  per-type "to type" constructor),
* the callee reads or writes it through that type's own API,
* the framework **releases** it with Godot's per-type destructor
  (`variant_get_ptr_destructor`), which is what drops the reference the
  construction took.

Nothing about the callee's shape changes: a pointer type occupies the same
`*in` / `*out` slot a builtin does, and in a multi-argument signature it is read
with `GDEX_ArgPtr`. Only the reading and writing differ, and for `String` two
helpers cover it: `GDEX_StringText(*s)` (a two-call length-then-fill dance,
because `string_to_utf8_chars` writes no terminator) and
`GDEX_StringNew(*dest, text)`.

```purebasic
; (String) -> String
Procedure GDBouncer_label(*self.GDBouncer, *in, *out)
  GDEX_StringNew(*out, "bouncer:" + GDEX_StringText(*in))
EndProcedure
```

**Verified:** `String` as an argument and a return, on both the one-argument and
generic paths, plus `StringName` — enough to show the marshalling is per-type
data rather than special-cased code. A 50 000-call round-trip moves static
memory by −384 bytes, so the references are genuinely released rather than
merely looking right.

**Not yet exercised:** `NodePath`, `Object`, `Array`, `Dictionary`, `Callable`,
`Signal` and the `Packed*Array` family go through the same path, but nothing
has driven them yet. `Object` additionally needs a reference-count decision for
`RefCounted`-derived returns, and reporting an `Object` argument to Godot also
means naming its class in the `PropertyInfo`, which is not wired up.

### One caveat: `real_t`

The sizes above assume single-precision `real_t`. In a `precision=double` build
every `real_t`-based type doubles: `Vector2` becomes 16, `Vector3` 24,
`Transform3D` 96, and these structures would have to change to `.d`. This is
the same build-time choice godot-cpp makes. Integer types (`Vector2i`,
`Vector3i`, `Rect2i`) and `RID` are unaffected.

### Caps per class

A class's tables are fixed arrays inside its `GDClassInfo`, so the caps are
paid for in static data by every registered class whether or not it uses them.
They fill faster than they look, too: a property expands into **two** methods
(`get_` and `set_`).

| Cap | Value | Entry | Cost |
|---|---|---|---|
| `#GDEX_MAX_PROPS` | 64 | 48 bytes | 3 KB |
| `#GDEX_MAX_METHODS` | 128 | 72 bytes | 9 KB |
| `#GDEX_MAX_SIGNALS` | 16 | 64 bytes | 1 KB |

That is about 13 KB per class — with `#GDEX_MAX_CLASSES` at 8, roughly 100 KB of
static data for a full extension. Raising a number is therefore cheap; the caps
are a bound, not a budget.

The first two are coupled, which is easy to miss: a property costs **two**
methods, so `#GDEX_MAX_METHODS` must be at least twice `#GDEX_MAX_PROPS` or the
property cap can never be reached — the method table fills first and the failed
getter/setter binding then rejects the property. At 128 and 64 the pair is
exactly balanced. Measured on a 35-property class (70 methods), which overflows
the old 32/64 pair with six `too many methods` reports and registers cleanly
under the new one.

Overflow is reported through Godot's `print_error` rather than dropped silently
— see gotcha 3 below for why that matters.

`#GDEX_MAX_SIGNAL_ARGS` (4) is deliberately **not** in that table. It is a
*shape*, not a table bound: a signal's arguments are typed in `ADD_SIGNAL` and
passed to `emit_signal` as separate pointer parameters, so raising it means
extending two call signatures rather than sizing an array.

## Generating the bindings

**Under `generated/`, only `generated/helpers/` is hand-written.** Everything
else there is emitted by `tools/pb_gdext_wizard.pb`, which reads Godot's own
`extension_api.json` and writes one file per engine class — and is itself
written in PureBasic, so the whole project is one toolchain: `pbcompiler`
builds both the extension and the generator that writes part of it.

```sh
./tools/pb_gdext_wizard --outdir generated        # every class, one file each
./tools/pb_gdext_wizard --outdir bindlib          # every class, one file each
./tools/pb_gdext_wizard --check generated/*.pbi
./tools/pb_gdext_wizard --stats
```

Each file is **purely generated and self-contained**: it declares its own
binds and its own `Register_<Class>_Binds()`, and includes nothing — not even
its ancestors. That is deliberate. PureBasic has no include-once, so a file that
pulled in an ancestor would collide with a caller that included that ancestor
directly; and nothing hand-written is grafted on, so what you read is what the
generator wrote. Files can be mixed in any combination and any order:

```purebasic
IncludeFile "bindlib/Node2D.pbi"    ; Sprite2D, CharacterBody2D, ...
IncludeFile "bindlib/AnimationPlayer.pbi"
```

`generated/` is reproducible — delete it freely:
`generate-bindings.sh` re-creates the class files byte for byte, and writes
`generated/helpers/` back if it is gone. There is no *per-class* helper layer:
for a method call, use the generated name directly — `Node2D::set_position(*self, @v)`.
The helpers that do exist are generic and live in their own folder (see
[The helper layer](#the-helper-layer)). `--out` still exists for writing one
combined file instead of a directory.

Iterating on the generator itself is the one case that needs a manual step:
`pbcompiler tools/pb_gdext_wizard.pb -c -e tools/pb_gdext_wizard` (which `build.sh` also
does whenever `tools/pb_gdext_wizard.pb` is newer than the binary).

The file it writes is split deliberately: everything mechanical is generated.
The only hand-written code under `generated/` is `generated/helpers/`, and it is
never per-class — so regenerating the class files cannot lose an edit, and there
is no helper layer standing between you and a generated name.

### Writing it in PureBasic

Fortuitously easy in one place and fiddly in four:

* **Parsing is a non-issue.** PureBasic has a built-in JSON library and chews
  through the 7 MB file in **28 ms** — `ParseJSON`, `GetJSONMember`,
  `GetJSONElement`, `JSONArraySize` cover everything needed.
* **A missing member reads back as `0`, which is `#PB_JSON_Null`.** An
  unguarded `JSONArraySize(0)` segfaults; 166 of the 1036 classes have no
  `methods` array at all, so the guard is load-bearing, not defensive.
* **Structures cross procedure boundaries only by pointer.** The generator
  itself hit this: `Procedure DescribeMethod(mi.MethodInfo)` is a syntax error,
  hence `*mi.MethodInfo` throughout.
* **No line continuation.** A long expression has to be built up over several
  statements.
* **No escape for a double quote inside a string literal.** `Chr(34)` is the
  only way to emit one — needed on four lines that write `GDEX_SNFrom(...,
  "Name")` and the `IncludeFile` directive.
* **Fixed-size arrays in a structure are indexed with `[ ]`**, while `Dim`'d
  arrays use `( )`. Mixing them is a syntax error.
* **`Structure S` is rejected** — `S` is the String type suffix. Same trap as
  `Structure L`, `Structure D`, `Structure I`, `Structure F`, `Structure Q`.
* **Godot's argument names are not usable as PureBasic parameters.** Around
  thirty of them are keywords: `step`, `data`, `next`, `default`, `debug`,
  `with`, and also `string`, `array`, `object`, `constant`, `align`, `lines`,
  `message`, `boolean`, `character`, `error`, `global`, `icon`, `interface`,
  `internal`, `language`, `library`, `output`, `parallel`, `progress`,
  `repeat`, `resource`, `restore`, `source`, `target`, `threaded`, `unicode`.
  Every generated parameter is therefore prefixed (`p_step`, `p_position`);
  the original name is kept in the generated comment. Parameter names never
  appear at a call site, so this costs nothing and removes the whole class of
  collision rather than maintaining a keyword list. It only became visible when
  generating classes beyond the curated set — which is one reason that set is
  curated.

The rewritten tool also fixed a real defect: `RID` was mapped to a struct,
which produced a by-value structure parameter (invalid PureBasic) and a return
value that was declared but never actually returned. `RID` is a single 8-byte
handle in every build configuration, so the generator now treats it
as a scalar. That is why the two were not byte-identical until the fix.

### Does it scale to all classes?

The API describes **1036 classes, 16 822 methods, 503 signals, 4162 properties**.
Every single method carries a `hash`, so bind resolution is fully mechanical,
and only **15** methods are vararg — the one shape that cannot be called through
a typed wrapper. **11 733** methods (70%) have a signature expressible with the
types in `gdex_types.pbi`; the rest take or return `String`, `StringName`,
`NodePath`, an `Object` subclass, `Array`, `Dictionary` or an enum-returning
array, and get a bind without a wrapper.

The generator for the whole API would be the same program with `--classes`
left off and every class emitted; nothing in it is specific to two classes.

The reason this is cheap in PureBasic and expensive in C++ is that **PureBasic
generates data, not code**. A method bind is resolved at runtime and invoked
through `object_method_bind_ptrcall` with an array of argument pointers, so
godot-cpp's typed wrapper per method has no PureBasic equivalent — and none is
needed. The generated file is mostly a `Global` per method plus a
`Register_<Class>_Binds()` that resolves them; the typed wrappers are a
convenience on top.

`--check` re-verifies every `_pGetMethodBind(...)` hash already present in the
`.pbi` files against the API. PureBasic has no regex, so it scans the two line
shapes by hand. It reports:

```
checked 157 binds in 4 file(s): all match the API
```

Run it after any regeneration, and after editing a hand-written bind.

### What the generator does not do

* **Vararg methods** (15) get a bind only; call them through
  `object_method_bind_call` with Variants, as `Object.pbi` does for
  `emit_signal`.
* **Pointer-typed values** (`String`, `StringName`, `Object`, `Array`,
  `Dictionary`) get a bind only. They need construct/destroy semantics rather
  than a struct copy — see above.
* **Signals and properties** are not emitted. The API has them (503 / 4162),
  but wiring them needs the `GDExtensionPropertyInfo` path in
  `gdex_class.pbi`, which is per class rather than per engine method.
* **Enum types** map to `int`, which is correct on the wire but loses the
  symbolic name.

## The helper layer

`generated/` is generator output with one deliberate exception:
`generated/helpers/`. It holds five small files that give a class the surface
godot-cpp has, so a PureBasic class is declared the way a C++ one is.

| File | What it adds |
|---|---|
| `gdex_helpers.pbi` | The one to include; pulls in the other four. |
| `gdex_variant.pbi` | native value <-> Variant for **every** type, through Godot's per-type constructors. |
| `gdex_classdb.pbi` | `ClassDB::bind_method`, `ClassDB::add_property`, `ClassDB::add_signal`. |
| `gdex_macros.pbi` | `D_METHOD`, `PropertyInfo`, `ADD_PROPERTY`, `ADD_SIGNAL`, `GDREGISTER_CLASS`, `GDREGISTER_SINGLETON`, `GDEX_EXTENSION`. |
| `gdex_signal.pbi` | `emit_signal`. |

Include it **after** `gdex_class.pbi` (it drives the framework tables) and
**before** your own classes:

```purebasic
IncludeFile "gdex_defs.pbi"
IncludeFile "gdex_api.pbi"
IncludeFile "generated/Node2D.pbi"
IncludeFile "generated/Object.pbi"
IncludeFile "gdex_class.pbi"
IncludeFile "generated/helpers/gdex_helpers.pbi"
IncludeFile "myclass.pbi"
```

`generate-bindings.sh` writes these files **only if they are missing**, so
editing them is safe and `rm -rf generated` stays recoverable.

## Declaring a class

Side by side with the godot-cpp version of the same class:

```cpp
static void _bind_methods() {
    ClassDB::bind_method(D_METHOD("set_amplitude", "amplitude"), &GDExample::set_amplitude);
    ClassDB::bind_method(D_METHOD("get_amplitude"), &GDExample::get_amplitude);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "amplitude"), "set_amplitude", "get_amplitude");
    ADD_SIGNAL(MethodInfo("position_changed", PropertyInfo(Variant::VECTOR2, "new_position")));
}
```

```purebasic
Procedure GDExample_bind()
  ClassDB::bind_method(D_METHOD("get_amplitude"), @GDExample_get_amplitude(), #FLOAT)
  ClassDB::bind_method(D_METHOD("set_amplitude", "amplitude"), @GDExample_set_amplitude(), #VOID, #FLOAT)
  ADD_PROPERTY(PropertyInfo(#FLOAT, "amplitude"), "set_amplitude", "get_amplitude")
  ADD_SIGNAL("position_changed", #VECTOR2, "new_position")
EndProcedure
```

Properties must be named, not passed, and their accessors must already have
been bound with `ClassDB::bind_method` - the same rule godot-cpp has, enforced
with an error rather than a silent no-op.

### The four places PureBasic forces a difference

1. **Types are explicit.** C++ reads argument and return types off the member
   function pointer; a PureBasic procedure pointer carries no signature, so
   `ClassDB::bind_method` takes `(return, arg0, arg1, arg2, arg3)` as
   `#VOID` / `#FLOAT` / `#VECTOR2` constants. C++ also gets a call path per
   signature for free from that pointer; here each one is a shape, so beyond
   the typed signatures a method's arguments travel through the generic shape
   instead - see [More than one argument](#more-than-one-argument).
2. **`ADD_SIGNAL` takes the pairs directly** - `ADD_SIGNAL("bounced", #VECTOR2,
   "position")` - rather than `ADD_SIGNAL(MethodInfo(...))`. PureBasic expands
   an inner macro while it is still parsing the outer one's arguments, and two
   levels of nesting do not survive. One level, as `ADD_PROPERTY` uses with
   `PropertyInfo`, is fine.
3. **`GDREGISTER_CLASS` goes in `GDEX_RegisterClasses()`**, not at file scope.
   C++'s version is a static initialiser; PureBasic has none, and registration
   has to happen at a level anyway (a scene class cannot be registered at CORE).
4. **Structures cannot be returned by value**, so a `Vector2`-returning method
   writes through an out parameter the framework supplies.

### Calling engine methods

Each engine class's generated wrappers live in a PureBasic module named after
the class, so an inherited call reads the way it does in C++:

```purebasic
Node2D::set_position(*self, @new_position)
Node2D::rotate(*self, *self\angle)
```

The module owns that class's method-bind pointers, and the flat
`Register_<Class>_Binds()` injects them from outside
(`Node2D::gdb_set_position = _pGetMethodBind(...)`), together with the
`object_method_bind_ptrcall` address. This works because a module is a black
box that cannot reach main code, but main code can write into a module's
public globals — the reverse direction. A method name that is a PureBasic
keyword gets a leading underscore (`_debug`, `_next`, `_read`, `_select`).

Every generated module starts with `EnableExplicit`, and that is load-bearing
rather than tidiness: `EnableExplicit` in main code does **not** apply inside a
module, and a module does not inherit it, so without that line a name the
wrapper cannot see silently becomes a module-local. The wrapper then compiles
cleanly and does nothing at all. It caught exactly that class of bug while this
was being built.

### Engine virtuals and notifications

Godot delivers almost every engine virtual as a **notification** — `_ready`,
`_enter_tree`, `_exit_tree`, `_physics_process`, `_draw` and the rest — so one
optional handler covers all of them. A class supplies it in its descriptor:

```purebasic
Procedure GDExample_notify(*self.GDExample, what.l)
  Select what
    Case #NOTIFICATION_ENTER_TREE
      *self\entered + 1
    Case #NOTIFICATION_READY
      *self\ready + 1
    Case #NOTIFICATION_PHYSICS_PROCESS
      *self\physics + 1
  EndSelect
EndProcedure

gdexample_class\notify = @GDExample_notify()
```

`_process` is the exception and stays separate: it is the only virtual Godot
asks about through virtual call data, and the only one handed a delta, which is
what the `process` field is for. The two do not conflict — a class may have
either, both, or neither.

**Physics needs asking for.** Godot delivers `NOTIFICATION_PHYSICS_PROCESS` only
to a node whose physics processing is *enabled*, and it is off by default —
unlike a script, an extension class has no `_physics_process` for Godot to
notice. Call `GDEX_EnablePhysics(PeekI(*self))` from `NOTIFICATION_ENTER_TREE`,
where the object exists. (`GDEX_EnableProcessing` is the same thing for the
notification-based `_process` path.) This is easy to get wrong quietly: the
handler is correct and simply never runs.

### Calling a builtin type's method, or an `@GlobalScope` function

Engine *classes* live in ClassDB, which is why they need `Register_<Class>_Binds()`
and a level to wait for. A builtin type's methods and the `@GlobalScope`
functions are not in ClassDB at all — Godot hands them out by type plus hash, and
they exist at every initialization level. So there is nothing to list in
`GDEX_ResolveBinds()` and nothing to wait for, and the generator emits a module
per builtin type plus one for `GlobalScope`:

```purebasic
IncludeFile "generated/Vector2.pbi"
IncludeFile "generated/GlobalScope.pbi"
...
Vector2::_length(*v)                    ; -> float
Vector2::_normalized(*v, *out)          ; -> Vector2, through *out
GlobalScope::_deg_to_rad(x)             ; -> float
```

**Every builtin and utility wrapper carries a leading underscore**, and that is
not cosmetic. The class wrappers only rename the four names measured to collide
with PureBasic keywords, but these collide far more widely —
`floor`, `ceil`, `round`, `abs`, `min`, `max`, `sign`, `dot`, `lerp`, `length`,
`str`, `hex`, `find`, `insert`, `left`, `right`, `replace` are all PureBasic
commands — and the compiler reports only the first failure per build, so a
measured list is not obtainable here. One unconditional prefix is cheaper than a
list that is wrong in a way nobody notices until someone calls
`Vector2.floor()`.

Both call conventions are one array of argument pointers — the same shape the
generic dispatcher uses — so a callee's own signature is all that differs from a
class wrapper.

**Two traps are worth knowing, both of which cost a crash here.** The recovered
`gdextension_interface.pbi` records parameter *names*, not types, and these two
getters do not take what they look like they take:
`variant_get_ptr_builtin_method` wants a **StringName**, and so does
`variant_get_ptr_utility_function`, despite its parameter being called
`p_function`. Both must be checked against Godot's header.

### Emitting a signal

```purebasic
Define new_position.GDVector2
new_position\x = x
new_position\y = y
emit_signal(*self, "position_changed", @new_position)
```

The argument types come from the `ADD_SIGNAL` declaration, so no type constant
appears at an emit site - it would only repeat what the class already said.
`emit_signal` takes up to four value pointers, so a multi-argument signal is the
same call:

```purebasic
ADD_SIGNAL("pair", #INT, "a", #FLOAT, "b")     ; declared in bind()
emit_signal(*self, "pair", @i, @f)             ; emitted elsewhere
```

A class may declare up to `#GDEX_MAX_SIGNALS` (8) signals, each with up to
`#GDEX_MAX_SIGNAL_ARGS` (4) arguments. Pointer-typed Variants (`String`,
`StringName`, `Object`, `Array`, `Dictionary`) are the one case `emit_signal`
cannot build for you: the value must be a Godot object you constructed.

## Verifying the library

`tools/pb_gdext_wizard --check` compares the generated files against the same
`extension_api.json` they were generated from, so it cannot tell you whether
that dump matches the Godot binary actually loading them — and this project's
dump is 4.7 while the test binary is 4.8.dev6.

`selftest/` closes that gap. It is an ordinary PureBasic GDExtension: it
includes `generated/selftest.pbi` (all 870 class files plus a check per bind)
and calls `GDEX_SelfTest()` at SCENE level.

```sh
./generate-bindings.sh          # writes generated/selftest.pbi too
cd selftest && ./build.sh
cd godot
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --import
/Applications/Godot.app/Contents/MacOS/Godot --headless --path .
```

It reports one line, plus a line naming the absent classes:

```
[gdex] selftest: 14846 binds ok, 539 null; 53 class(es) absent, 0 PARTIAL
```

**`PARTIAL` is the number that matters.** A whole class being null means the
class is not registered in this context — editor-only, or platform-gated like
`JavaClass` and `JavaScriptBridge` — which is expected and harmless. A class
that is *partly* null can only mean a class/method/hash triple that Godot does
not agree with, which is a real defect. Classifying per class like this is also
why the test does not rely on `api_type`: that field says `core` for Android and
Web classes a macOS game run simply does not have.

Result against Godot 4.8.dev6 with the 4.7 dump: **14 846 binds resolve, 0
partial** — no stale hashes. The 53 absent classes are all editor-only or
Android/Web-only, and Godot's own count of unresolved lookups (539) matches the
harness's exactly.

The test is not a rubber stamp; it was checked in both directions by corrupting
one hash in a copy of the library:

```
PARTIAL Node2D: 1 binds null, 32 ok
[gdex] selftest: 14845 binds ok, 540 null; 53 class(es) absent, 1 PARTIAL
```

Note what it does *not* do: it resolves binds, it does not call methods. Calling
15 385 methods would need a valid instance and meaningful arguments for each,
and some (`Object.free`, `Node.queue_free`) are destructive by design. Actual
invocation is covered by `demo/` and `skeleton/` instead.

## The five things that cost the most time

The first two are silent — no error, just a crash — and are traps for any
PureBasic (or other non-C) language binding. The third is silent corruption
with no crash at all, the fourth is a crash at free time from mixing two
allocation idioms, and the fifth is a lookup that returns null at the wrong
initialization level.

### 0. The transcription is checked, not trusted

`gdextension_interface.pbi` was reconstructed by hand from Godot's header, and a
transcription is only as good as the day it was made: a structure that gains,
loses or reorders a field still compiles, and every field after the change is
read from the wrong offset. Godot's real header is vendored beside it and
`tools/check-interface.sh` compares the two — it prints `sizeof` from C and
`SizeOf` from PureBasic and diffs them:

```
interface: all 19 structures match Godot's header
```

It is not a full structural check, but it catches the failure that matters, and
it was checked in the negative direction by removing one `Align
#PB_Structure_AlignC`:

```
-GDExtensionMethodInfo 96        +GDExtensionMethodInfo 80
-GDExtensionPropertyInfo 48      +GDExtensionPropertyInfo 36
-GDExtensionClassVirtualMethodInfo 88   +GDExtensionClassVirtualMethodInfo 80
```

Note what that shows: the two structures that *embed* `PropertyInfo` drifted
with it, which is exactly how one missing alignment reaches everything
downstream.

**Why the header is not simply included instead.** `HeaderSection` can pull C
into the translation unit, and it was tried first. Two things stop it being the
build's mechanism: `pbcompiler` compiles the generated C from a temporary
directory, so a relative `#include` does not resolve (the workspace's own
inline-C examples use absolute paths, and every one of those paths is now dead);
and PureBasic cannot use the header's declarations anyway — it mangles its own
structures to `s_<lowercased-name>` and generates field access against that, so
it needs its own `Structure` and `Prototype` declarations regardless. The header
is therefore the *authority*, not the source.

### 1. PureBasic packs structures; C pads them

`Structure Foo` in PureBasic has **no** alignment padding. Every
`GDExtension*` structure crossing the C ABI needs

```purebasic
Structure GDExtensionClassCreationInfo6 Align #PB_Structure_AlignC
```

Without it, `GDExtensionClassCreationInfo6` is 156 bytes instead of 160 and
Godot reads every pointer four bytes early. Carried through, that is what made
the recovered Aug-19 `SimpleGDExtension` attempt fail, and it is why all 19
structures in `gdextension_interface.pbi` were changed from the recovered text
— the only edit made to that file. That it is the only one is now checked rather
than asserted: see [gotcha 0](#0-the-transcription-is-checked-not-trusted).

### 2. Godot dereferences `PropertyInfo.name`, `.class_name` and `.hint_string`

`PropertyInfo(const GDExtensionPropertyInfo &)` does

```cpp
name = *reinterpret_cast<StringName *>(pinfo.name);
class_name = *reinterpret_cast<StringName *>(pinfo.class_name);
hint_string = *reinterpret_cast<String *>(pinfo.hint_string);
```

unconditionally. A null pointer is an immediate segfault inside
`GDExtensionMethodBind::update`. Absent fields must be a **valid empty** Godot
object, so `load_api` builds one empty `StringName` and one empty `String` and
everything points at those. godot-cpp does the same.

### 3. A full per-class table rewrote the previous method's signature

Not a C-ABI trap but the nastiest failure in this build, because nothing
crashed and nothing was printed.

A property expands into two methods, so `GDBouncer`'s 14 `bind` calls became
18 method entries against a limit of 16. `GDEX_AddMethodEntry` correctly
refused the 17th — but the generic path added the type and size *after*
appending, by writing to `methods[method_count - 1]`. With the table full that
index was the **previous** entry, so `frame()`'s declared return type was
overwritten by the next registration's and became `Rect2`. GDScript then
rejected, at parse time:

```
Cannot assign a value of type Rect2 to variable "t2" with specified type Transform2D
```

and, because the main scene failed to load, headless Godot had no main loop and
sat there forever instead of exiting — which is what "something hung" looked
like from outside.

Two fixes, both worth keeping:

* `GDEX_AddBuiltinMethod` now records `method_count` before appending and only
  writes the types if it actually grew.
* Overflow is reported through `GDEX_Fail` (Godot's `print_error`) instead of
  `Debug`. **`Debug` is compiled out of a dylib**, so the original "too many
  methods" warning could never have been seen.

The limits are now 64 properties / 128 methods, and because overflow reports
loudly the failure mode above cannot recur silently.

Practical corollary: when running headless, pass `--quit-after`, or a script
error leaves a process with no main loop running indefinitely.

### 4. `AllocateStructure` must be freed with `FreeStructure`, not `FreeMemory`

PureBasic has two ways to make a structure in heap memory:

| allocate | free |
|---|---|
| `AllocateStructure(T)` | `FreeStructure(*p)` |
| `AllocateMemory(SizeOf(T))` + `InitializeStructure(*p, T)` | `ClearStructure(*p, T)` + `FreeMemory(*p)` |

**They are not interchangeable.** `AllocateMemory` and `AllocateStructure` do
not come from the same allocator, and calling `FreeMemory` on an
`AllocateStructure` block crashes with `Trace/BPT trap` — even for a structure
with no managed members at all. It happens at free time, so it looks like the
object was fine right up until teardown.

The framework's instance storage originally used only the raw path, which is
fine for a class of plain numbers — and silently wrong for a class with
**PureBasic-managed members**. `FillMemory` zeroes a `List`, `Map` or dynamic
array header, but does not initialise it, and the first `AddElement` segfaults:

```
AllocateMemory+FillMemory: got 4311018968
Segmentation fault: 11
```

So `GDClassInfo` carries an optional `alloc_func` / `free_func` pair. A class
with managed members supplies them:

```purebasic
Structure GDTicker
  GDBase.GDObject
  counter.d
  List marks.l()          ; needs AllocateStructure
EndStructure

Procedure.i GDTicker_alloc()
  ProcedureReturn AllocateStructure(GDTicker)
EndProcedure

Procedure GDTicker_free(*p.GDTicker)
  FreeStructure(*p)
EndProcedure

gdticker_class\alloc_func = @GDTicker_alloc()
gdticker_class\free_func  = @GDTicker_free()
```

Classes without managed members need neither, and use the raw path. The demo
exercises the List from both sides — `mark_count()` called from GDScript, and
`announce()` printing `counter=4.00 marks=5 last=4` from PureBasic into Godot's
log.

### 5. A method bind for a scene class is not available at CORE

Godot's `ClassDB` is populated in halves. Core classes (`Object`, `Engine`,
`Resource`, …) exist from CORE initialization; **scene classes (`Node`,
`Node2D`, `Sprite2D`, …) do not exist until SCENE.** Ask for one too early and
`classdb_get_method_bind` returns null and logs:

```
ERROR: Parameter "mb" is null.
   at: gdextension_classdb_get_method_bind (core/extension/gdextension_interface.cpp:1653)
```

Nothing crashes — the bind is just 0, and whatever used it silently does
nothing. This bit when the framework started resolving its own engine methods:
it resolved all four at the first `RegisterGDClass`, which is `GDService` at
**CORE**, so the two `Node` binds came back null — and a one-shot "already
resolved" flag meant they were never retried at SCENE.

The fix is to resolve per need, at first *use*, rather than once at
registration: `Node`'s binds are only wanted by the notification-based
`_process` path, which never runs before SCENE, and `Engine`'s are wanted by
`GD_RegisterSingleton`, which is legitimately called at CORE.

The general rule: **resolve a bind at or after the level that owns the class**,
and treat a null bind as "try again later", never as "done".

## Building from the PureBasic IDE

**Yes**, and this file is already set up for it. The recovered
`gdexample.pb` carries the IDE's settings as a trailer:

```
; IDE Options = PureBasic 6.41 - C Backend (MacOS X - arm64)
; ExecutableFormat = Shared .dylib
; Optimizer
; EnableThread
; Executable = test.dylib
```

`ExecutableFormat = Shared .dylib` is the IDE's shared-library setting, and
`Optimizer` / `EnableThread` are `-z` and `-t`. Open `gdexample.pb`, press
Compile, and the IDE writes a real GDExtension dylib. The equivalent command
line is:

```sh
pbcompiler gdexample.pb -z -t -dl test.dylib
```

Three differences from `./build.sh`, all of which matter:

1. **The name and where it lands.** The IDE writes `test.dylib` next to the
   source, in the project root — while `demo/gdex.gdextension` points at
   `libgdexample.dylib` in `demo/`. Either change the trailer's
   `; Executable = ...` line, or copy the result across:
   `cp test.dylib demo/libgdexample.dylib`.
2. **The generator does not run.** The IDE knows nothing about
   `tools/pb_gdext_wizard`, so `generated/` has to be current before you compile.
   It is committed, so this is only a concern after changing the API dump or
   `GEN_CLASSES` — run `./build.sh` once in that case.
3. **`--install` does not happen.** Nothing signs or copies for you (`build.sh`
   copies into `demo/` and signs where it lands).

For everyday work the IDE is fine and faster to iterate with; `./build.sh` is
what keeps `generated/` honest.

## Shutdown is clean

Running `demo/` exits 0, prints everything, and Godot reports **nothing** at
exit: no leaked instances, no `still registered` warnings, no resources still
in use. Verified over repeated runs.

That took two fixes. The six reported instances were really four objects with
two independent causes — two the demo created and never freed, and two the
framework created and never destroyed — plus two knock-on `GDScript` entries
that disappeared with the first fix:

* **Two were the demo's own.** `GDSignalProbe` and `GDSignalPing` are
  `Node`-derived; `main.gd` created them with `.new()`, never added them to the
  tree and never freed them. It now calls `probe.free()` and `ping.free()`.
  That alone took the reported count from 6 to 2 — and also cleared a
  `1 resources still in use` for `res://main.gd`, which was a knock-on: the
  leaked Nodes were what kept the script alive. So the `GDScript` and
  `GDScriptNativeClass` entries were never independent leaks.
* **Two were the framework's.** `GD_UnregisterSingleton` calls
  `Engine.unregister_singleton`, which drops the *name* and not the object, so
  `GDService` and `GDTicker` were still in ObjectDB at exit.
  `GDEX_UnregisterSingletonsAt` now calls `object_destroy` on the instance
  after unregistering it — which runs the instance's own destructor, so
  `GDTicker`'s managed `List` is released through its `free_func` (gotcha 4)
  rather than abandoned.

`object_destroy` is resolved in `load_api` beside the other object operations,
and the call is guarded, so a build where it does not resolve degrades to the
old behaviour instead of crashing.

Note that `GDEX_UnregisterAllClasses` — the blunt entry point for an extension
that drives the levels itself — unregisters classes only; the destroy lives in
the level-aware `GDEX_UnregisterSingletonsAt` that `GDEX_Deinitialize` uses.

The output this project used to produce, for reference:

```
WARNING: Extension class 'GDService' is still registered at exit; its GDExtension did not unregister it.
WARNING: 2 ObjectDB instances were leaked at exit
```

## Verified against

Godot `4.8.dev6.official`. The original log was `4.7.2.stable`; the GDExtension
ABI used here (`classdb_register_extension_class6`,
`GDExtensionClassCreationInfo6`) is the same on both.

The demo exercises: two Node2D classes, an `Object` singleton at CORE, a `Node`
singleton at SCENE, float / Vector2 / Color properties read and written from
GDScript, exported float / int / Vector2 / Vector3 / Rect2 / Transform2D /
Transform3D methods (each as return value, argument, or both - so nested
structs and embedded arrays are covered), `_process` running under a `Node` in
the tree, a signal emitted from PureBasic arriving in GDScript with a Vector2
payload, dynamic `set()`/`get()` through the class callbacks, and a
PureBasic-managed `List` living inside an extension instance (gotcha 4).

It also covers multi-argument methods on all three paths: a typed
`(float, float) -> void`, a typed `(float, float) -> float`, a typed
`(int, int) -> int`, a generic three-argument method, and a generic method
mixing a `Vector2` argument with a float and returning a `Rect2`.

## Todo

- [x] **One argument per method.** Done: two scalar arguments use a typed
      shape, and anything beyond that goes through a generic shape that carries
      the declared types instead of the signature, so arity is unlimited. See
      [More than one argument](#more-than-one-argument).
- [x] **Pointer-typed values now cross the boundary** — `bind_method` accepts
      them, and the framework constructs and releases them with Godot's own
      per-type constructor and destructor. `String` and `StringName` are
      verified end to end; `NodePath`, `Object`, `Array`, `Dictionary`,
      `Callable`, `Signal` and the `Packed*Array` family share the path but are
      untested, and `Object` still needs a `RefCounted` decision for returns.
      See [What is not covered](#what-is-not-covered).
- [x] **Builtin and utility methods are callable.** `GDEX_BuiltinMethodBind`
      and `GDEX_UtilityFunctionBind` resolve them by type plus hash, needing no
      registration, and both are verified end to end (`Vector2(3,4).length()`
      gives 5.0; `deg_to_rad(180)` gives π).
- [x] **Those wrappers are generated.** One module per builtin type plus
      `GlobalScope.pbi`, resolve-on-first-use so nothing needs registering:
      `Vector2::_length(*v)`, `Vector2::_normalized(*v, *out)`,
      `GlobalScope::_deg_to_rad(x)`, all verified end to end. 634 of the 999
      builtin methods and 77 of the 114 utility functions are expressible in the
      current type set; the rest want `Variant`, `Callable` or a `Packed*Array`
      and get no wrapper until those are driven — the same rule as an engine
      class method.
- [x] **Engine virtuals.** `_process` is still the only one Godot asks about
      through virtual call data, but every virtual that arrives as a
      *notification* — `_ready`, `_enter_tree`, `_exit_tree`,
      `_physics_process`, `_draw`, … — now reaches a per-class `notify` handler,
      verified for the first four. See [Engine virtuals and
      notifications](#engine-virtuals-and-notifications).
- [x] **Forgetting a resolver is no longer silent.** A wrapper whose bind was
      never resolved reports `class::method` and the remedy, once per method.
      See [`GDEX_ResolveBinds()`](#getting-started-with-your-own-extension).
- [ ] **`Register_*_Binds()` is still written by hand** in `GDEX_ResolveBinds()`.
      Automating it is not reachable in PureBasic: no templates, no reflection
      and no static initialisers, so a procedure cannot be discovered by name
      and a class file cannot register itself. A generated project-wide resolver
      would work but has to be kept in step with the entry point's includes,
      which trades one silent failure for another. Until then the report above
      is what makes the omission announce itself.
- [x] **Caps per class:** now 16 signals, 128 methods, 64 properties, with the
      cost and the reasoning written down under [Caps per
      class](#caps-per-class). `#GDEX_MAX_SIGNAL_ARGS` stays at 4: it is a shape
      shared with `emit_signal` rather than a table bound, and nothing has needed
      more.
