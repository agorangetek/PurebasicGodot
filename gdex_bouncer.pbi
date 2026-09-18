; ===========================================================================
; gdex_bouncer.pbi - GDBouncer, a second Node2D class.
;
; Its job in the framework is to prove the descriptor is really per-class:
; GDExample and GDBouncer are both Node2D extension classes registered from
; the same generic callbacks, with different properties, different signals and
; different _process bodies.
;
; `amplitude` and `speed` drive a bounce; every time the bounce crosses the
; bottom it emits "bounced" with the current position.
; ===========================================================================

Structure GDBouncer
  GDBase.GDObject
  amplitude.d
  speed.d
  phase.d
  direction.d
  tint.GDColor
EndStructure

Procedure GDBouncer_constructor(*self.GDBouncer)
  *self\amplitude = 100.0
  *self\speed     = 2.0
  *self\phase     = 0.0
  *self\direction = 1.0
  *self\tint\r = 1.0
  *self\tint\g = 1.0
  *self\tint\b = 1.0
  *self\tint\a = 1.0
EndProcedure

Procedure GDBouncer_destructor(*self.GDBouncer)
EndProcedure

Procedure.d GDBouncer_get_amplitude(*self.GDBouncer)
  ProcedureReturn *self\amplitude
EndProcedure

Procedure GDBouncer_set_amplitude(*self.GDBouncer, v.d)
  *self\amplitude = v
EndProcedure

Procedure.d GDBouncer_get_speed(*self.GDBouncer)
  ProcedureReturn *self\speed
EndProcedure

Procedure GDBouncer_set_speed(*self.GDBouncer, v.d)
  *self\speed = v
EndProcedure

Procedure.d GDBouncer_get_phase(*self.GDBouncer)
  ProcedureReturn *self\phase
EndProcedure

Procedure GDBouncer_reset(*self.GDBouncer)
  *self\phase = 0.0
  *self\direction = 1.0
EndProcedure

Procedure GDBouncer_process(*self.GDBouncer, delta.d)
  *self\phase + *self\direction * *self\speed * delta
  Define hit.l = #False
  If *self\phase >= *self\amplitude
    *self\phase = *self\amplitude
    *self\direction = -1.0
    hit = #True
  ElseIf *self\phase <= -#PI
    *self\phase = -*self\amplitude
    *self\direction = 1.0
  EndIf

  If hit
    ; Emit "bounced" carrying (phase, 0) - note that the signal value and the
    ; position below are deliberately different vectors.
    Define sigv.GDVector2
    sigv\x = *self\phase
    sigv\y = 0.0
    emit_signal(*self, "bounced", @sigv)
  EndIf

  Define pos.GDVector2
  pos\x = 0.0
  pos\y = *self\phase
  Node2D::set_position(*self, @pos)
EndProcedure

; ---- Godot builtin types across the boundary ------------------------------
;
; `span` is a Vector2 property, and the three methods below cover the three
; Vector2 shapes the framework knows: return only, argument only, and both.
; A PureBasic procedure cannot return a structure, so the result comes back
; through a *out parameter the framework provides.

Procedure GDBouncer_get_span(*self.GDBouncer, *out.GDVector2)
  *out\x = *self\amplitude
  *out\y = *self\speed
EndProcedure

Procedure GDBouncer_set_span(*self.GDBouncer, *v.GDVector2)
  *self\amplitude = *v\x
  *self\speed     = *v\y
EndProcedure

; (Vector2) -> Vector2
Procedure GDBouncer_scaled_span(*self.GDBouncer, *v.GDVector2, *out.GDVector2)
  *out\x = *self\amplitude * *v\x
  *out\y = *self\speed * *v\y
EndProcedure

; ---- the same mechanism, other builtins ----------------------------------
;
; Nothing below is special-cased anywhere in the framework: each one is just a
; Variant type constant plus the structure from gdex_types.pbi.

; Color as a property.
Procedure GDBouncer_get_tint(*self.GDBouncer, *out.GDColor)
  *out\r = *self\tint\r
  *out\g = *self\tint\g
  *out\b = *self\tint\b
  *out\a = *self\tint\a
EndProcedure

Procedure GDBouncer_set_tint(*self.GDBouncer, *in.GDColor)
  *self\tint\r = *in\r
  *self\tint\g = *in\g
  *self\tint\b = *in\b
  *self\tint\a = *in\a
EndProcedure

; () -> Vector3   (3 floats)
Procedure GDBouncer_axes(*self.GDBouncer, *out.GDVector3)
  *out\x = *self\amplitude
  *out\y = *self\speed
  *out\z = *self\phase
EndProcedure

; () -> Rect2     (two Vector2)
Procedure GDBouncer_extents(*self.GDBouncer, *out.GDRect2)
  *out\position\x = 0.0
  *out\position\y = 0.0
  *out\size\x = *self\amplitude
  *out\size\y = *self\speed
EndProcedure

; () -> Transform2D   (three Vector2, nested access)
Procedure GDBouncer_frame(*self.GDBouncer, *out.GDTransform2D)
  *out\x\x = 1.0
  *out\x\y = 0.0
  *out\y\x = 0.0
  *out\y\y = 1.0
  *out\origin\x = 0.0
  *out\origin\y = *self\phase
EndProcedure

; () -> Transform3D   (48 bytes, a struct-of-structs with an array)
Procedure GDBouncer_basis3(*self.GDBouncer, *out.GDTransform3D)
  *out\basis\rows[0]\x = *self\amplitude
  *out\basis\rows[1]\y = *self\speed
  *out\basis\rows[2]\z = 1.0
  *out\origin\x = 0.0
  *out\origin\y = 0.0
  *out\origin\z = *self\phase
EndProcedure

; (Rect2) -> Rect2
Procedure GDBouncer_grow(*self.GDBouncer, *in.GDRect2, *out.GDRect2)
  *out\position\x = *in\position\x
  *out\position\y = *in\position\y
  *out\size\x = *in\size\x * *self\speed
  *out\size\y = *in\size\y * *self\phase
EndProcedure

Procedure GDBouncer_bind()
  ClassDB::bind_method(D_METHOD("get_amplitude"), @GDBouncer_get_amplitude(), #FLOAT)
  ClassDB::bind_method(D_METHOD("set_amplitude", "amplitude"), @GDBouncer_set_amplitude(), #VOID, #FLOAT)
  ClassDB::bind_method(D_METHOD("get_speed"), @GDBouncer_get_speed(), #FLOAT)
  ClassDB::bind_method(D_METHOD("set_speed", "speed"), @GDBouncer_set_speed(), #VOID, #FLOAT)
  ClassDB::bind_method(D_METHOD("get_span"), @GDBouncer_get_span(), #VECTOR2)
  ClassDB::bind_method(D_METHOD("set_span", "span"), @GDBouncer_set_span(), #VOID, #VECTOR2)
  ClassDB::bind_method(D_METHOD("get_phase"), @GDBouncer_get_phase(), #FLOAT)
  ClassDB::bind_method(D_METHOD("reset"), @GDBouncer_reset())
  ClassDB::bind_method(D_METHOD("bounds"), @GDBouncer_get_span(), #VECTOR2)
  ClassDB::bind_method(D_METHOD("apply_bounds", "bounds"), @GDBouncer_set_span(), #VOID, #VECTOR2)
  ClassDB::bind_method(D_METHOD("scaled_span", "v"), @GDBouncer_scaled_span(), #VECTOR2, #VECTOR2)

  ; Other builtins, all through the one generic mechanism.
  ClassDB::bind_method(D_METHOD("get_tint"), @GDBouncer_get_tint(), #COLOR)
  ClassDB::bind_method(D_METHOD("set_tint", "tint"), @GDBouncer_set_tint(), #VOID, #COLOR)
  ClassDB::bind_method(D_METHOD("axes"), @GDBouncer_axes(), #VECTOR3)
  ClassDB::bind_method(D_METHOD("extents"), @GDBouncer_extents(), #RECT2)
  ClassDB::bind_method(D_METHOD("frame"), @GDBouncer_frame(), #TRANSFORM2D)
  ClassDB::bind_method(D_METHOD("basis3"), @GDBouncer_basis3(), #TRANSFORM3D)
  ClassDB::bind_method(D_METHOD("grow", "in"), @GDBouncer_grow(), #RECT2, #RECT2)

  ADD_PROPERTY(PropertyInfo(#FLOAT, "amplitude"), "set_amplitude", "get_amplitude")
  ADD_PROPERTY(PropertyInfo(#FLOAT, "speed"), "set_speed", "get_speed")
  ADD_PROPERTY(PropertyInfo(#VECTOR2, "span"), "set_span", "get_span")
  ADD_PROPERTY(PropertyInfo(#COLOR, "tint"), "set_tint", "get_tint")
  ADD_SIGNAL("bounced", #VECTOR2, "position")
EndProcedure

Global gdbouncer_class.GDClassInfo
gdbouncer_class\instance_size = SizeOf(GDBouncer)
gdbouncer_class\constructor   = @GDBouncer_constructor()
gdbouncer_class\destructor    = @GDBouncer_destructor()
gdbouncer_class\process       = @GDBouncer_process()
gdbouncer_class\bind_func     = @GDBouncer_bind()
