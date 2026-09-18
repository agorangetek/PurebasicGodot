# PureBasic GDExtension

A Godot 4 GDExtension whose framework and classes are written in PureBasic,
built into one dylib by `pbcompiler`, and loaded through a `.gdextension` file.
Godot's C interface is declared in PureBasic and checked against Godot's own
header; the engine's bindings are generated from the API dump.

Status: builds and runs, verified on macOS arm64 against Godot 4.8.dev6.
For the internals, the measurements, and the things that cost the most time, see
[NOTES.md](NOTES.md).

## Quick start

```sh
./generate-bindings.sh        # once: writes generated/ from Godot's API dump
./build.sh --install          # compile + sign into demo/
cd demo
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --import   # once
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --quit-after 900
```

```sh
tools/check-all.sh            # the whole regression: static checks, build,
                              # demo, selftest, skeleton - exits non-zero on failure
```

## A class

```purebasic
Structure Spinner
  GDBase.GDObject      ; must be first: how a callback finds the class
  speed.d
  angle.d
EndStructure

Procedure Spinner_constructor(*self.Spinner)
  *self\speed = 1.0
EndProcedure

Procedure Spinner_destructor(*self.Spinner)
EndProcedure

Procedure.d Spinner_get_speed(*self.Spinner)
  ProcedureReturn *self\speed
EndProcedure

Procedure Spinner_set_speed(*self.Spinner, v.d)
  *self\speed = v
EndProcedure

Procedure Spinner_process(*self.Spinner, delta.d)
  *self\angle + *self\speed * delta
  Node2D::rotate(*self, *self\angle)
EndProcedure

Procedure Spinner_bind()
  ClassDB::bind_method(D_METHOD("get_speed"), @Spinner_get_speed(), #FLOAT)
  ClassDB::bind_method(D_METHOD("set_speed", "speed"), @Spinner_set_speed(), #VOID, #FLOAT)
  ADD_PROPERTY(PropertyInfo(#FLOAT, "speed"), "set_speed", "get_speed")
EndProcedure

Global spinner_class.GDClassInfo
spinner_class\instance_size = SizeOf(Spinner)
spinner_class\constructor   = @Spinner_constructor()
spinner_class\destructor    = @Spinner_destructor()
spinner_class\process       = @Spinner_process()
spinner_class\bind_func     = @Spinner_bind()
```

`bind_method` states the signature because a PureBasic procedure pointer carries
none: the trailing constants are `(return, arg0, arg1, ...)`. Include only the
engine classes you call into — `generated/Node2D.pbi` gives you `Node2D::rotate`.

## A whole extension

```purebasic
IncludeFile "../gdex_defs.pbi"
IncludeFile "../gdex_api.pbi"
IncludeFile "../generated/Node2D.pbi"
IncludeFile "../generated/Object.pbi"
IncludeFile "../generated/Engine.pbi"
IncludeFile "../gdex_class.pbi"
IncludeFile "../generated/helpers/gdex_helpers.pbi"

IncludeFile "spinner.pbi"

Procedure GDEX_RegisterClasses()
  GDREGISTER_CLASS(spinner_class, "Spinner", "Node2D")
EndProcedure

Procedure GDEX_ResolveBinds()
  Register_Node2D_Binds()
  Register_Object_Binds()
EndProcedure

GDEX_EXTENSION(example_library_init)
```

`GDEX_RegisterClasses` works out each class's initialization level from its
parent, so there is no level ladder. `GDEX_ResolveBinds` resolves the engine
method binds and has to wait for SCENE; forgetting a class there is reported by
name rather than passing silently. The exported symbol must match `entry_symbol`
in the `.gdextension` file.

From GDScript:

```gdscript
var s := Spinner.new()
s.speed = 2.0
print(s.get_speed())
add_child(s)
```

`skeleton/` is this extension complete and compiling; copy the folder and rename
the entry symbol.

## What is supported

| | |
|---|---|
| methods | up to 4 typed arguments; two scalars use a typed shape, the rest a generic one |
| variadic methods | `ClassDB::bind_vararg`, with `argc` and Godot's `r_error` |
| properties | 64 per class; float, int, the builtin structures, or a pointer type |
| signals | 16 per class, up to 4 arguments each |
| builtin structures | 16, sizes verified against Godot's numbers |
| pointer types | `String` and `StringName` verified; the rest share the path, untested |
| engine methods | generated wrappers, 11,733 of 16,822 methods |
| builtin / `@GlobalScope` | generated wrappers, 634 of 999 and 77 of 114 |
| engine virtuals | `_process`, plus any virtual Godot delivers as a notification |

Not supported: `Variant`, reference counting for `Object` returns, editor
plugins, and anything outside macOS arm64. `NOTES.md` says which of these are
language limits and which are simply not done.

## Requirements

| | |
|---|---|
| PureBasic | 6.41 or newer, with the C backend. Set `PBCOMPILER` if it is not at the default path. |
| Godot | 4.4 or newer, for the API dump. The dump this repo was built against is 4.7. |
| Platform | macOS arm64. The Windows and Linux entries in the `.gdextension` are untested. |
