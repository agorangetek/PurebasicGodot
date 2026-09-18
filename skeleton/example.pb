; ===========================================================================
; skeleton/example.pb - a minimal PureBasic GDExtension.
;
; This is the whole extension: five IncludeFile lines, one class file, and the
; two callbacks plus the entry point Godot needs. Copy the folder, rename
; example_library_init, and you have your own.
;
; BUILD
;     ../build.sh                      (uses gdexample.pb - not this file)
;     ./build.sh                       (builds THIS extension; see that file)
;
; The include ORDER matters: PureBasic needs procedures defined before use, so
; the framework's bind helpers must be included ahead of gdex_class.pbi.
; ===========================================================================

IncludeFile "../gdex_defs.pbi"          ; constants, structures, globals
IncludeFile "../gdex_api.pbi"           ; the GDExtension interface + load_api
IncludeFile "../generated/Node2D.pbi"   ; Node/Node2D binds, and the helpers
IncludeFile "../generated/Object.pbi"   ; Object.emit_signal, if you add signals
IncludeFile "../generated/Engine.pbi"   ; Engine singleton, if you add singletons
IncludeFile "../gdex_class.pbi"         ; the framework: RegisterGDClass, macros
IncludeFile "../generated/helpers/gdex_helpers.pbi"  ; the godot-cpp-shaped surface

IncludeFile "spinner.pbi"               ; your class(es)

; ===========================================================================
; WHAT THIS EXTENSION EXPOSES
;
; One list, called once by the framework. RegisterGDClass figures out from the
; parent whether a class can exist at CORE or has to wait for SCENE, so there
; is no level ladder and no initialize/deinitialize callback to write.
; ===========================================================================

Procedure GDEX_RegisterClasses()
  GDREGISTER_CLASS(spinner_class, "Spinner", "Node2D")
EndProcedure

; Method binds for the engine classes this class calls into. Called when SCENE
; arrives, because a scene class has no MethodBind before then.
Procedure GDEX_ResolveBinds()
  Register_Node2D_Binds()
  Register_Object_Binds()
EndProcedure

; The dylib entry point Godot calls. The exported name must match entry_symbol
; in example.gdextension.
GDEX_EXTENSION(example_library_init)

; IDE Options = PureBasic 6.41 - C Backend (MacOS X - arm64)
; ExecutableFormat = Shared .dylib
; Executable = godot/libexample.dylib
