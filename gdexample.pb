;====================================================================
;  gdexample.pb
;  GDExample Godot node defined declaratively on top of gdex_class.pbi.
;
;  Build (macOS, arm64):
;    pbcompiler gdexample.pb -dl libgdexample.dylib
;
;  Exports "gdexample_library_init", the C ABI entry Godot calls when
;  it loads the extension.
;====================================================================

IncludeFile "gdex_defs.pbi"
IncludeFile "gdex_api.pbi"
; Generated method-bind bindings (from extension_api.json, per class).
; Included BEFORE gdex_class.pbi so gdex_class.pbi sees their bind globals.
IncludeFile "generated/Node2D.pbi"
IncludeFile "generated/Object.pbi"
IncludeFile "generated/Engine.pbi"
; Builtin types and @GlobalScope: not ClassDB classes, so nothing to register.
IncludeFile "generated/Vector2.pbi"
IncludeFile "generated/GlobalScope.pbi"
; The helper layer: generic Variant + signal emission, over the generated binds
; above. Its own folder under generated/, so it is easy to find and to drop.
IncludeFile "gdex_class.pbi"
; The godot-cpp-shaped surface. Needs gdex_class.pbi first.
IncludeFile "generated/helpers/gdex_helpers.pbi"

IncludeFile "gdex_bouncer.pbi"
IncludeFile "gdex_ticker.pbi"
IncludeFile "gdex_service.pbi"
IncludeFile "gdex_probe.pbi"

;====================================================================
; ==================== USER-CLASS DEFINITION =========================
; Everything a real end user must write for a Godot class:
;   * a Structure (first field = GDObject)
;   * constructor / destructor
;   * getter / setter / _process procedures
;   * a small descriptor + RegisterGDClass(...)
;====================================================================

Structure GDExample
  GDBase.GDObject
  amplitude.d
  speed.d
  time_passed.d
  time_emit.d
EndStructure

Procedure GDExample_constructor(*self.GDExample)
  *self\amplitude   = 10.0
  *self\speed       = 1.0
  *self\time_passed = 0.0
  *self\time_emit   = 0.0
EndProcedure

Procedure GDExample_destructor(*self.GDExample)
EndProcedure

Procedure.d GDExample_get_amplitude(*self.GDExample)
  ProcedureReturn *self\amplitude
EndProcedure

Procedure GDExample_set_amplitude(*self.GDExample, v.d)
  *self\amplitude = v
EndProcedure

Procedure.d GDExample_get_speed(*self.GDExample)
  ProcedureReturn *self\speed
EndProcedure

Procedure GDExample_set_speed(*self.GDExample, v.d)
  *self\speed = v
EndProcedure

Procedure GDExample_process(*self.GDExample, delta.d)
  *self\time_passed + *self\speed * delta
  Define x.d = *self\amplitude + (*self\amplitude * Sin(*self\time_passed * 2.0))
  Define y.d = *self\amplitude + (*self\amplitude * Cos(*self\time_passed * 1.5))

  ; Node2D.set_position(Vector2). The generated wrapper lives in a module named
  ; after the engine class and takes our instance pointer, so this reads exactly
  ; like the inherited C++ call.
  Define new_position.GDVector2
  new_position\x = x
  new_position\y = y
  Node2D::set_position(*self, @new_position)
  
  *self\time_emit + delta
  If *self\time_emit >= 1.0
    ; emit_signal(*self, "position_changed", new_position), as in godot-cpp.
    ; The argument's type comes from ADD_SIGNAL, so nothing is repeated here.
    emit_signal(*self, "position_changed", @new_position)
    *self\time_emit = 0.0
  EndIf
EndProcedure

; Called automatically by RegisterGDClass.
Procedure GDExample_bind()
  ClassDB::bind_method(D_METHOD("get_amplitude"), @GDExample_get_amplitude(), #FLOAT)
  ClassDB::bind_method(D_METHOD("set_amplitude", "amplitude"), @GDExample_set_amplitude(), #VOID, #FLOAT)
  ClassDB::bind_method(D_METHOD("get_speed"), @GDExample_get_speed(), #FLOAT)
  ClassDB::bind_method(D_METHOD("set_speed", "speed"), @GDExample_set_speed(), #VOID, #FLOAT)
  ADD_PROPERTY(PropertyInfo(#FLOAT, "amplitude"), "set_amplitude", "get_amplitude")
  ADD_PROPERTY(PropertyInfo(#FLOAT, "speed"), "set_speed", "get_speed")
  ADD_SIGNAL("position_changed", #VECTOR2, "new_position")
EndProcedure

; Per-class descriptor.
Global gdexample_class.GDClassInfo
gdexample_class\instance_size = SizeOf(GDExample)
gdexample_class\constructor   = @GDExample_constructor()
gdexample_class\destructor    = @GDExample_destructor()
gdexample_class\process       = @GDExample_process()
gdexample_class\bind_func     = @GDExample_bind()

;====================================================================
;====================================================================
; WHAT THIS EXTENSION EXPOSES
;
; One list, called once by the framework. RegisterGDClass works out from the
; parent whether a class can exist at CORE or has to wait for SCENE, so there
; is no level ladder here; GDREGISTER_SINGLETON keeps the instance and
; unregisters it at the level it was created.
;====================================================================

Procedure GDEX_RegisterClasses()
  ; Object-derived singleton: ready at CORE, so its name is a compile-time
  ; global for GDScript before the editor scans scripts (the godot-cffi
  ; pattern).
  GDREGISTER_SINGLETON(gdservice_class, "GDService", "Object")

  ; Scene classes: their parents only exist from SCENE, so the framework holds
  ; them back until then.
  GDREGISTER_CLASS(gdexample_class, "GDExample", "Sprite2D")
  GDREGISTER_CLASS(gdbouncer_class, "GDBouncer", "Node2D")
  GDREGISTER_SINGLETON(gdticker_class, "GDTicker", "Node", "GDNativeTicker")
  GDREGISTER_CLASS(gdsignalprobe_class, "GDSignalProbe", "Node")
  GDREGISTER_CLASS(gdsignalping_class, "GDSignalPing", "Node")
EndProcedure

; Method binds for the engine classes this extension calls into. Called when
; SCENE arrives, because a scene class has no MethodBind before then.
Procedure GDEX_ResolveBinds()
  Register_Object_Binds()   ; emit_signal
  Register_Node2D_Binds()   ; set_position, rotate, ...
EndProcedure

; The dylib entry point Godot calls. The exported name must match entry_symbol
; in gdex.gdextension.
GDEX_EXTENSION(gdexample_library_init)
; IDE Options = PureBasic 6.41 - C Backend (MacOS X - arm64)
; ExecutableFormat = Shared .dylib
; CursorPosition = 142
; FirstLine = 95
; Folding = --
; Optimizer
; EnableThread
; EnableXP
; DPIAware
; Executable = test.dylib