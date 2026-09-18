# PurebasicGodot

One command turns a Godot binary and a project name into a **complete, compilable
PureBasic GDExtension project**: the API bindings, the framework, an entry file
you can open in the PureBasic IDE, and a Godot project whose `.gdextension` is
already wired to the dylib you are about to build.

Nothing engine-specific is stored here. The bindings are generated from the Godot
binary *you* name, so the project is always bound to the exact engine it will run
against.

## Requirements

| | |
|---|---|
| **PureBasic** | 6.41 or newer, with the C backend. Used both to build this tool and to compile the projects it creates. |
| **Godot** | 4.4 or newer. Any binary will do — it is used only to produce the API dump. Verified against 4.8.dev6; the wizard-generated project was verified against 4.8.dev6. |
| **Platform** | macOS. Verified on macOS arm64. See *Platform support* below. |

`pbcompiler` is expected at
`/Applications/PureBasic.app/Contents/Resources/compilers/pbcompiler`.
Set `PBCOMPILER` to override it (the generated `build.sh` honours the same
variable).

## Build the wizard

```sh
pbcompiler tools/pb_gdext_wizard.pb -c -e tools/pb_gdext_wizard
```

The binary is not committed: it is platform-specific, and PureBasic is already
required to compile the projects the wizard creates.

## Create a project

```sh
./tools/pb_gdext_wizard /path/to/Godot mygame
```

That asks for a destination folder with the system folder picker. To skip the
picker — for scripting, or when there is no GUI:

```sh
./tools/pb_gdext_wizard /path/to/Godot mygame /path/to/parent
```

## What it creates

```
mygame/
  mygame.pb            the entry file: open this in the PureBasic IDE
  spinner.pbi          one example class, to copy and rename
  build.sh             compiles mygame.pb and installs the dylib
  gdex_*.pbi           the framework
  gdextension_interface.pbi
  generated/
    helpers/           the hand-written godot-cpp-shaped surface
    <Class>.pbi        ~880 files, one per engine class
  api/
    extension_api.json the dump this project was generated from (~7 MB)
  godot/
    project.godot
    mygame.gdextension already points at libmygame.dylib
    main.tscn, main.gd
```

## Build and run

```sh
cd mygame
./build.sh --install                                   # compile + install the dylib
cd godot
Godot --headless --path . --import                     # once, so GDScript sees the class
Godot --path .
```

`--import` is required the first time and after adding a class: GDScript resolves
extension classes as global names, and that only happens during import.

## Writing a class

```purebasic
Structure Spinner
  GDBase.GDObject          ; must be first
  speed.d
  angle.d
EndStructure

Procedure Spinner_process(*self.Spinner, delta.d)
  *self\angle + *self\speed * delta
  Node2D::rotate(*self, *self\angle)
  emit_signal(*self, "spinning", @*self\angle)
EndProcedure

Procedure Spinner_bind()
  ClassDB::bind_method(D_METHOD("get_speed"), @Spinner_get_speed(), #FLOAT)
  ClassDB::bind_method(D_METHOD("set_speed", "speed"), @Spinner_set_speed(), #VOID, #FLOAT)
  ADD_PROPERTY(PropertyInfo(#FLOAT, "speed"), "set_speed", "get_speed")
  ADD_SIGNAL("spinning", #FLOAT, "angle")
EndProcedure

Global spinner_class.GDClassInfo
spinner_class\instance_size = SizeOf(Spinner)
spinner_class\constructor   = @Spinner_constructor()
spinner_class\destructor    = @Spinner_destructor()
spinner_class\process       = @Spinner_process()
spinner_class\bind_func     = @Spinner_bind()

Procedure GDEX_RegisterClasses()
  GDREGISTER_CLASS(spinner_class, "Spinner", "Node2D")
EndProcedure

Procedure GDEX_ResolveBinds()
  Register_Node2D_Binds()
  Register_Object_Binds()          ; for emit_signal
EndProcedure

GDEX_EXTENSION(mygame_library_init)
```

The registration is one list: the framework works out from each class's parent
whether it can be registered at CORE or has to wait for SCENE, so there is no
`p_level` ladder and no `initialize`/`deinitialize` callback to write.

## What is in this repository

Only what the wizard needs to run, and what it copies into every project it
creates. There is no pre-generated engine code here at all.

| | |
|---|---|
| `tools/pb_gdext_wizard.pb` | the generator **and** the project wizard |
| `gdex_defs.pbi`, `gdex_types.pbi`, `gdextension_interface.pbi` | framework constants, structures, the interface transcription |
| `gdex_api.pbi`, `gdex_class.pbi` | interface resolution, registration, the generic callbacks |
| `generated/helpers/` | the hand-written surface: `ClassDB::bind_method`, `ADD_PROPERTY`, `ADD_SIGNAL`, `emit_signal`, `D_METHOD`, `GDEX_EXTENSION` |
| `skeleton/` | the entry file, one example class, `build.sh`, and the Godot project |

The wizard copies the framework from the checkout it lives in
(`GetPathPart(ProgramFilename()) + "../"`), so there is exactly one copy of it
and nothing can drift.

## Notes

**The bindings follow your Godot, not this repo.** `--dump-extension-api` asks
the binary you passed, so a 4.8 Godot yields 4.8 bindings. That is the point:
what you compile against is what you load.

**`api/extension_api.json` is worth keeping.** It is what `generated/` was
produced from, and re-running the wizard is how you regenerate after a Godot
upgrade.

**A measured PureBasic caveat.** `ProgramRunning()` and `CloseProgram()`
segfault on the Godot child process on macOS (exit 139), with the dump written
correctly anyway. The wizard therefore never tracks the child: it deletes the
target file, starts the dump, and waits for that file to appear and stop
growing. If you wrap Godot yourself, do the same.

**Platform support.** The tool itself is plain PureBasic and should build
anywhere, but the generated `godot/<name>.gdextension` currently has only
`macos.*` library entries, and `skeleton/build.sh` ad-hoc signs the dylib with
`codesign`. For Windows or Linux, add `windows.*` / `linux.*` entries pointing at
`res://lib<name>.dll` / `.so` and drop the signing step.
