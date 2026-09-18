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

; ---- multi-argument methods ------------------------------------------------
;
; C++ reads a whole signature off the member function pointer. PureBasic has no
; templates and a procedure pointer carries no signature, so a method with more
; than one argument is handed its arguments as an array of pointers to their
; native values: argument i is GDEX_ArgPtr/GDEX_ArgD/GDEX_ArgL(*args, i). The
; trailing constants of bind_method are what tell the framework how to fill
; them, and they are (return, arg0, arg1, ...).
;
; A generic-shape callee always has the shape (*self, *args, *out), and it
; writes its result through *out - which is 0 when the method returns nothing.

; (float, float) -> void
; Two scalars name their parameters, exactly as in C++: this is a typed shape,
; so no Variant crosses the boundary and no *args unpacking is needed.
Procedure GDBouncer_move_by(*self.GDBouncer, dx.d, dy.d)
  *self\phase     + dx
  *self\amplitude + dy
EndProcedure

; (float, float) -> float
Procedure.d GDBouncer_mix(*self.GDBouncer, a.d, b.d)
  ProcedureReturn *self\amplitude * a + *self\speed * b
EndProcedure

; (int, int) -> int - the same block of shapes, a different kind
Procedure.l GDBouncer_steps(*self.GDBouncer, a.l, b.l)
  ProcedureReturn (a * b) + *self\amplitude
EndProcedure

; (float, float, float) -> float
Procedure GDBouncer_blend(*self.GDBouncer, *args, *out)
  Protected a.d = GDEX_ArgD(*args, 0)
  Protected b.d = GDEX_ArgD(*args, 1)
  Protected t.d = GDEX_ArgD(*args, 2)
  PokeD(*out, a + (b - a) * t)
EndProcedure

; (Vector2, float) -> Rect2 - a builtin alongside a scalar
Procedure GDBouncer_grow_by(*self.GDBouncer, *args, *out.GDRect2)
  Protected *v.GDVector2 = GDEX_ArgPtr(*args, 0)
  Protected f.d = GDEX_ArgD(*args, 1)
  *out\position\x = 0.0
  *out\position\y = 0.0
  *out\size\x = *v\x * f
  *out\size\y = *v\y * f
EndProcedure

; ---- Godot String across the boundary -------------------------------------
;
; A String is 8 bytes of handle onto storage Godot owns, so it is read and
; written with the two helpers rather than with PeekS/PokeS. Nothing else about
; it is special: the framework constructs the native value from the Variant,
; hands the callee a pointer to it, and releases it afterwards - which is what
; releases the reference the conversion took.

; (String) -> String
Procedure GDBouncer_label(*self.GDBouncer, *in, *out)
  GDEX_StringNew(*out, "bouncer:" + GDEX_StringText(*in))
EndProcedure

; (String, float) -> String   - a pointer type in a multi-argument signature,
; which is a signature no typed shape covers, so it takes the generic one.
Procedure GDBouncer_tag(*self.GDBouncer, *args, *out)
  Protected *name = GDEX_ArgPtr(*args, 0)
  Protected w.d = GDEX_ArgD(*args, 1)
  GDEX_StringNew(*out, GDEX_StringText(*name) + "/" + StrD(w, 2))
EndProcedure

; (String) -> StringName   - a second pointer type through the same path, to
; show the marshalling is not String-specific: the framework constructs from the
; Variant, and releases with that type's own destructor.
Procedure GDBouncer_sn(*self.GDBouncer, *in, *out)
  g_string_name_new(*out, UTF8(GDEX_StringText(*in)))
EndProcedure

; ---- calling into a builtin type and into @GlobalScope ---------------------
;
; Engine *classes* are reached through ClassDB method binds, which is why they
; need Register_<Class>_Binds(). A builtin type's methods and the @GlobalScope
; functions are not in ClassDB at all: Godot hands them out by type plus hash,
; and they exist at every initialization level, so nothing has to be listed in
; GDEX_ResolveBinds() and nothing has to wait for SCENE.
;
; The call convention is one array of argument pointers in both cases - the
; same shape the generic dispatcher already uses - so a callee's own signature
; is the only thing that differs.

; Vector2.length()   [builtin method, no arguments, float result]
;
; The callee's shape is the framework's, not a free choice: a method with one
; argument and a value result is the (*self, *in, *out) shape, so the result is
; written through *out rather than returned. Declaring it as a value-returning
; two-parameter procedure compiles and silently does nothing useful - the
; framework's third argument is ignored and *out is never written.
Procedure GDBouncer_probe_length(*self.GDBouncer, *v.GDVector2, *out)
  Protected mb.i = GDEX_BuiltinMethodBind(#VECTOR2, "length", 466405837)
  If Not mb
    PokeD(*out, -1.0)
    ProcedureReturn
  EndIf
  Protected f.GDExtensionPtrBuiltInMethod = mb
  Protected r.d
  f(*v, 0, @r, 0)
  PokeD(*out, r)
EndProcedure

; @GlobalScope.deg_to_rad(float) -> float   [utility function, no instance]
Procedure GDBouncer_probe_deg_to_rad(*self.GDBouncer, *deg, *out)
  Protected uf.i = GDEX_UtilityFunctionBind("deg_to_rad", 2140049587)
  If Not uf
    PokeD(*out, -1.0)
    ProcedureReturn
  EndIf
  Protected f.GDExtensionPtrUtilityFunction = uf
  Protected Dim a.i(0)
  a(0) = *deg
  Protected r.d
  f(@r, @a(0), 1)
  PokeD(*out, r)
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

  ; Multi-argument methods. A 2-argument scalar method that fits a typed shape
  ; is dispatched without a Variant round trip; everything else - three or more
  ; arguments, or a builtin anywhere in the list - uses the generic shape.
  ClassDB::bind_method(D_METHOD("move_by", "dx", "dy"), @GDBouncer_move_by(), #VOID, #FLOAT, #FLOAT)
  ClassDB::bind_method(D_METHOD("mix", "a", "b"), @GDBouncer_mix(), #FLOAT, #FLOAT, #FLOAT)
  ClassDB::bind_method(D_METHOD("blend", "a", "b", "t"), @GDBouncer_blend(), #FLOAT, #FLOAT, #FLOAT, #FLOAT)
  ClassDB::bind_method(D_METHOD("grow_by", "size", "factor"), @GDBouncer_grow_by(), #RECT2, #VECTOR2, #FLOAT)
  ClassDB::bind_method(D_METHOD("steps", "a", "b"), @GDBouncer_steps(), #INT, #INT, #INT)

  ; Pointer-typed values. Before this they were rejected by bind_method with
  ; "argument type is not a value type".
  ClassDB::bind_method(D_METHOD("label", "name"), @GDBouncer_label(), #STRING, #STRING)
  ClassDB::bind_method(D_METHOD("tag", "name", "weight"), @GDBouncer_tag(), #STRING, #STRING, #FLOAT)
  ClassDB::bind_method(D_METHOD("sn", "text"), @GDBouncer_sn(), #STRINGNAME, #STRING)

  ; Not engine-class calls: a builtin type's method and a @GlobalScope function.
  ClassDB::bind_method(D_METHOD("probe_length", "v"), @GDBouncer_probe_length(), #FLOAT, #VECTOR2)
  ClassDB::bind_method(D_METHOD("probe_deg_to_rad", "deg"), @GDBouncer_probe_deg_to_rad(), #FLOAT, #FLOAT)

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
