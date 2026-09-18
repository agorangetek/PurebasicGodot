; ===========================================================================
; skeleton/spinner.pbi - a minimal GDExtension class.
;
; Copy this file, rename everything, and you have your own class. The three
; things that matter:
;
;   1. the structure's FIRST field is GDObject          (required)
;   2. constructor / destructor / optional process      (function pointers)
;   3. a bind_func declaring properties and methods, then a GDClassInfo
;      global wiring them together
;
; Only the first field is mandatory. A class with no properties and no
; per-frame work needs neither bind_func nor process.
; ===========================================================================

Structure Spinner
  GDBase.GDObject      ; must be first: this is how callbacks find the class
  speed.d
  angle.d
EndStructure

Procedure Spinner_constructor(*self.Spinner)
  *self\speed = 1.0
  *self\angle = 0.0
EndProcedure

Procedure Spinner_destructor(*self.Spinner)
EndProcedure

Procedure.d Spinner_get_speed(*self.Spinner)
  ProcedureReturn *self\speed
EndProcedure

Procedure Spinner_set_speed(*self.Spinner, v.d)
  *self\speed = v
EndProcedure

; _process. The framework asks Godot "is this overridden?" and routes the
; frame delta here, so a Node-derived class just gets called.
Procedure Spinner_process(*self.Spinner, delta.d)
  *self\angle + *self\speed * delta
  ; Node2D.rotate(float) - the generated wrapper lives in a module named after
  ; the engine class and takes our instance pointer. To emit instead:
  ;   ADD_SIGNAL("spinning", #FLOAT, "angle")   in bind(), then
  ;   emit_signal(*self, "spinning", @*self\angle)
  Node2D::rotate(*self, *self\angle)
EndProcedure

; Declares the class's surface. Runs during RegisterGDClass.
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
