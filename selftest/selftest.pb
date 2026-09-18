; ===========================================================================
; selftest/selftest.pb - a PureBasic GDExtension that tests the whole library.
;
;   ../generate-bindings.sh     writes generated/, including selftest.pbi
;   ./build.sh                  compiles this into the Godot project
;   cd godot && Godot --headless --path . --import
;   cd godot && Godot --headless --path .
;
; It defines no class. All it does is call GDEX_SelfTest() at SCENE level,
; which resolves every method bind in generated/ against the running Godot and
; reports which failed.
;
; Why this is worth its own extension: tools/gen_binds --check compares the
; generated files against the same extension_api.json they came from, so it
; cannot detect a dump that does not match the Godot binary actually loading
; them. Only the engine can answer "does this class, method and hash exist".
; ===========================================================================

IncludeFile "../gdex_defs.pbi"
IncludeFile "../gdex_api.pbi"
IncludeFile "../generated/selftest.pbi"   ; pulls in all 870 class files
IncludeFile "../gdex_class.pbi"

Procedure initialize_selftest(*p_userdata, p_level)
  ; SCENE: ClassDB has both halves by now, so a null here is meaningful.
  If p_level = #GDEXTENSION_INITIALIZATION_SCENE
    GDEX_SelfTest()
  EndIf
EndProcedure

Procedure deinitialize_selftest(*p_userdata, p_level)
EndProcedure

ProcedureCDLL.a selftest_library_init(*p_get_proc_address, *p_library, *r_initialization)
  GDExtensionClassLibraryPtr = *p_library
  load_api(*p_get_proc_address)
  Protected *ri.GDExtensionInitialization = *r_initialization
  *ri\minimum_initialization_level = #GDEXTENSION_INITIALIZATION_SCENE
  *ri\userdata = 0
  *ri\initialize = @initialize_selftest()
  *ri\deinitialize = @deinitialize_selftest()
  ProcedureReturn 1
EndProcedure

; The framework calls these two; they are how an extension lists its classes
; and resolves engine MethodBinds. This extension has no classes of its own -
; it only runs GDEX_SelfTest() - but the hooks must still exist.
Procedure GDEX_RegisterClasses()
EndProcedure

Procedure GDEX_ResolveBinds()
EndProcedure


; IDE Options = PureBasic 6.41 - C Backend (MacOS X - arm64)
; ExecutableFormat = Shared .dylib
; Executable = libselftest.dylib
