# Getting started

How to go from this checkout to your own working Godot extension in PureBasic.

`skeleton/` is a complete, working extension — one class, one property, one
`_process` — and it builds and runs as it stands. Copy it, rename it, grow it.
Everything below has been run; the commands are exact.

---

## 0. Prerequisites

| | |
|---|---|
| PureBasic 6.41+ | `pbcompiler` normally at `/Applications/PureBasic.app/Contents/Resources/compilers/pbcompiler`. Set `PBCOMPILER` if yours is elsewhere. |
| Godot 4.4+ | Tested against the 4.8.dev6 at `/Applications/Godot.app/Contents/MacOS/Godot`. |
| Xcode command line tools | `pbcompiler`'s C backend shells out to `clang`. |

Check it in one go:

```sh
cd purebasic_gdext
./generate-bindings.sh     # once: writes generated/ from Godot's API dump
./build.sh --install       # compile, sign, install into demo/
```

`generated/` is already committed, so the first line is only needed if it is
missing or you want more classes. Then prove the whole chain works:

```sh
cd demo
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --import     # once
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --quit-after 900
```

You should see `GDService counter after bump+set: 41.5` and `=== demo done ===`.
If you don't, stop here and fix that before writing any code — see
*Troubleshooting* at the bottom.

---

## 1. Make your own extension

```sh
cd purebasic_gdext
cp -R skeleton myext
cd myext
```

You now have:

```
myext/
  example.pb     the entry point + module glue   -> rename to myext.pb
  spinner.pbi    your class                      -> rename to yourclass.pbi
  build.sh       builds into godot/
  godot/         a minimal Godot project
```

Pick the symbol Godot will call. It must match in two places:

| where | what |
|---|---|
| `myext.pb` | `ProcedureCDLL.a myext_library_init(...)` |
| `godot/example.gdextension` | `entry_symbol = "myext_library_init"` |

## 2. Write a class

A class is one `Structure` plus a handful of procedures plus a descriptor.
`spinner.pbi` is the template; the shape is always:

```purebasic
Structure YourClass
  GDBase.GDObject          ; MUST be first - this is how callbacks find the class
  someField.d              ; your fields follow
EndStructure

Procedure YourClass_constructor(*self.YourClass)      ; initialise your fields
Procedure YourClass_destructor(*self.YourClass)       ; free anything you own
Procedure YourClass_process(*self.YourClass, delta.d) ; optional: per-frame work

Procedure YourClass_bind()                            ; declare properties and methods
  ClassDB::bind_method(D_METHOD("get_someField"), @YourClass_get_someField(), #FLOAT)
  ClassDB::bind_method(D_METHOD("set_someField", "someField"), @YourClass_set_someField(), #VOID, #FLOAT)
  ADD_PROPERTY(PropertyInfo(#FLOAT, "someField"), "set_someField", "get_someField")
EndProcedure

Global yourclass_class.GDClassInfo                    ; wire it together
yourclass_class\instance_size = SizeOf(YourClass)
yourclass_class\constructor   = @YourClass_constructor()
yourclass_class\destructor    = @YourClass_destructor()
yourclass_class\process       = @YourClass_process()
yourclass_class\bind_func     = @YourClass_bind()
```

Only `GDBase.GDObject` first, a constructor and a destructor are mandatory;
drop `process` if you have no per-frame work, and `bind_func` if the class has
no properties or methods.

To declare more surface, add macros to `bind()`:

```purebasic
ClassDB::bind_method(D_METHOD("get_speed"), @Get_speed(), #FLOAT)
ClassDB::bind_method(D_METHOD("set_speed", "speed"), @Set_speed(), #VOID, #FLOAT)
ADD_PROPERTY(PropertyInfo(#FLOAT, "speed"), "set_speed", "get_speed")
ClassDB::bind_method(D_METHOD("reset"), @My_reset())                        ; reset()
ClassDB::bind_method(D_METHOD("get_phase"), @My_get_phase(), #FLOAT)        ; -> float
ClassDB::bind_method(D_METHOD("axes"), @My_axes(), #VECTOR3)                ; -> Vector3
```

Note that **structures always cross by pointer**, so a getter or a
Vector2-returning method writes through an out parameter the framework
supplies:

```purebasic
Procedure Get_span(*self.YourClass, *out.GDVector2)
  *out\x = ...
  *out\y = ...
EndProcedure
```

The full macro list and the supported builtin types are in `README.md`.

## 3. Register the class

In the entry file, one line in `GDEX_RegisterClasses()`:

```purebasic
GDREGISTER_CLASS(yourclass_class, "YourClass", "Node2D")
```

The third argument is the Godot class you inherit from — `Node2D`, `Node`,
`Sprite2D`, `Object`, … The name in quotes is what GDScript sees.

You do not say *when*: the framework registers a class whose parent is `Object`
straight away, and holds anything else back until SCENE, when that parent
exists. There is no `p_level` ladder to write.

## 4. Point a Godot project at it

`godot/` already is one. Rename `example.gdextension` if you like, and make sure
its `entry_symbol` matches your export. Nothing else needs editing unless you
want a different project name.

## 5. Build and run

```sh
cd myext
./build.sh
cd godot
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --import
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --quit-after 600
```

`--import` is needed once so Godot discovers the class and GDScript can resolve
`YourClass` as a global name. Expect it to exit 134 with a crash in
`DocTools::generate` — that is a **Godot bug affecting every GDExtension** on
4.8.dev6, not your code; the scan still completes. Always pass `--quit-after`:
if a script fails to parse, Godot has no main scene and would otherwise run
forever.

### Or build it from the PureBasic IDE

`skeleton/example.pb` ends with an IDE trailer, so opening it and pressing
Compile produces a shared library rather than an executable:

```
; IDE Options = PureBasic 6.41 - C Backend (MacOS X - arm64)
; ExecutableFormat = Shared .dylib
; Executable = libexample.dylib
```

Two differences from `./build.sh`, both easy to trip over:

* the IDE writes the dylib **next to the source**, not into `godot/` — copy it
  across: `cp libexample.dylib godot/`
* the IDE cannot regenerate `generated/`, so run `./build.sh` once if you have
  changed the API dump or `GEN_CLASSES`

Signing is not a problem: `pbcompiler`'s output is already ad-hoc signed by the
linker.

---

## The helper layer

`generated/helpers/` is the one hand-written thing under `generated/`. Include
it **after** `gdex_class.pbi`:

```purebasic
IncludeFile "../generated/Node2D.pbi"
IncludeFile "../generated/Object.pbi"
IncludeFile "../gdex_class.pbi"
IncludeFile "../generated/helpers/gdex_helpers.pbi"
IncludeFile "yourclass.pbi"
```

It gives your class godot-cpp's surface:

```purebasic
Procedure YourClass_bind()
  ClassDB::bind_method(D_METHOD("get_speed"), @YourClass_get_speed(), #FLOAT)
  ClassDB::bind_method(D_METHOD("set_speed", "speed"), @YourClass_set_speed(), #VOID, #FLOAT)
  ADD_PROPERTY(PropertyInfo(#FLOAT, "speed"), "set_speed", "get_speed")
  ADD_SIGNAL("spinning", #FLOAT, "angle")
EndProcedure

Procedure YourClass_process(*self.YourClass, delta.d)
  *self\angle + *self\speed * delta
  emit_signal(*self, "spinning", @*self\angle)
EndProcedure
```

The argument and return types are `#`-constants (`#VOID`, `#FLOAT`, `#INT`,
`#VECTOR2`, `#COLOR`, `#TRANSFORM2D`, ...) because a PureBasic procedure pointer
carries no signature; `emit_signal` needs no type at all, because it reads them
off the `ADD_SIGNAL` declaration.

`README.md` has the full surface and the four places PureBasic forces a
difference from C++ (`ClassDB::bind_method` rather than `ClassDB::bind_method`,
and so on).

`generate-bindings.sh` writes these files only if they are missing, so you can
edit them without losing the changes to a regeneration.

## Making it standalone

`myext/` reaches back into the framework with `IncludeFile "../gdex_defs.pbi"`
and friends, so it has to stay a sibling of those files. To ship it as its own
repo, copy the framework alongside it:

```
myext/
  gdex_defs.pbi              gdex_api.pbi
  gdex_types.pbi             gdextension_interface.pbi
  gdex_class.pbi             generated/         (+ generated/helpers/)
```

then change the five `IncludeFile "../..."` lines to drop the `../`, and in
`build.sh` drop the `../` from `GEN_HELPERSDIR`. Nothing else depends on the
layout, and `generated/` can simply be deleted and rebuilt.

---

## When you need an engine method the framework doesn't have

`generated/` already holds **every** engine class — 870 self-contained files,
one per class. To use one, just include it:

```purebasic
IncludeFile "generated/Sprite2D.pbi"
```

**Including a file is only half of it.** It gives you the definitions; the
binds are resolved at runtime by that class's `Register_<Class>_Binds()`, which
you call from `GDEX_ResolveBinds()`:

```purebasic
Procedure GDEX_ResolveBinds()
  Register_Sprite2D_Binds()          ; <- without this, every bind stays null
  Register_Node2D_Binds()
  Register_Object_Binds()            ; emit_signal
EndProcedure
```

That hook runs when SCENE arrives, because a scene class has no MethodBind
before then — resolving one at CORE returns null and Godot reports
`Parameter "mb" is null`. Skip it and a wrapper does nothing at all, silently:
it checks its bind, finds it null, and returns. This is the one part of the
setup that is still yours to get right.

No generation step is needed, and it costs nothing until you use it: only
included files are compiled, so the dylib stays the same size.

If you ever do need to regenerate — a newer Godot, or a class that is somehow
missing — it is the one-time script, not the build:

```sh
./generate-bindings.sh                     # everything
./generate-bindings.sh Sprite2D TileMap     # or just these
```

`build.sh` never runs it. Generation is additive: naming a class does not
delete the others.

That gives you `Sprite2D::gdb_set_frame` and a typed wrapper
`GDSprite2D_set_frame(*obj, frame.p_i)`. Call it the way the shipped helpers
do — call the generated wrapper, e.g. `GDSprite2D_set_frame(*obj, frame)`.

Two things worth knowing:

* **Every generated file is self-contained.** No file includes another, because
  PureBasic has no include-once and a cross-include would collide with a caller
  that included the same file directly. So include exactly what you use, in any
  order.
* **The framework needs no generated file.** `gdex_class.pbi` resolves the four
  engine methods it uses for itself, so a project that uses only `Sprite2D`
  does not drag in `Node2D`, `Node` or `Engine`.

## Verifying the bindings

`selftest/` is a GDExtension that checks every generated bind against the
running Godot. Worth running once after generating, and again after a Godot
upgrade:

```sh
cd selftest && ./build.sh && cd godot
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --import
/Applications/Godot.app/Contents/MacOS/Godot --headless --path .
```

`0 PARTIAL` is the pass condition. See the README for what the numbers mean.

## Regenerating the bindings

Not part of the build, and not something you do often:

```sh
./generate-bindings.sh              # all classes into generated/
./generate-bindings.sh Node2D       # or a subset (additive, never deletes)
./generate-bindings.sh --check      # verify every hash against the API dump
```

It builds `tools/pb_gdext_wizard` from source first if needed, then rewrites only the
files whose bytes change. `GDEXT_API` overrides where the API dump comes from.

`generated/` is source: commit it, and delete it freely — `./generate-bindings.sh`
re-creates the class files byte for byte, and writes `generated/helpers/` back if
it is gone. The class files contain no hand-written additions; the only
hand-written code under `generated/` is that helpers folder.

Hand-written binds are possible too (`_pGetMethodBind` plus
`object_method_bind_ptrcall`), but the hashes are easy to get wrong. Check any
of them with:

```sh
./tools/pb_gdext_wizard --check generated/*.pbi
```

---

## Troubleshooting

**Godot dies with no message.** The dylib isn't signed, or the copy in the
Godot project wasn't signed *after* it was copied. `codesign -s - -f` the file
where it actually sits.

**`Could not find type "YourClass"` in GDScript.** Run `--import` once. A newly
registered class isn't visible until Godot rescans.

**Nothing happens, no output, process just exits.** Command line only shows
`Debug` output when a debugger is attached; in a compiled dylib `Debug` is
compiled out entirely. Use `GDEX_Report("...")`, which goes to Godot's log.

**A crash at load, before any of your code runs.** `load_api` failed to resolve
something, or a structure layout is wrong. `README.md` lists the four ABI traps
that produce exactly this, with the fix for each.

**Godot warns `Extension class 'X' is still registered at exit`.** Call
`GDEX_UnregisterAllClasses()` from your SCENE-level deinitialize, as the
skeleton does.

**The extension builds but nothing you declared shows up in GDScript.** A class
whose `bind_func` overflowed `#GDEX_MAX_METHODS` reports it through
`GDEX_Report` now, so look for a `[gdex] too many methods` line in the log.
