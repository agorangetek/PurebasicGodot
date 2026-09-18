; ===========================================================================
; gdex_probe.pbi - GDSignalProbe / GDSignalPing: signals of every type.
;
; These exist to show the signal path is type-generic rather than
; Vector2-shaped. Each emitter is the same call:
;
;     emit_signal(*self, "vector2_value", @v)
;
; and the ARGUMENT TYPE comes from the ADD_SIGNAL declaration in bind_methods,
; so no type constant appears at an emit site. float, int, bool, Vector2,
; Vector3 and Color all go through one mechanism, and the "pair" signal shows
; more than one argument.
;
; A class may now declare as many signals as it likes - the old descriptor had
; room for exactly one - which is what makes one class able to probe six types.
; GDSignalPing covers the zero-argument case.
; ===========================================================================

Structure GDSignalProbe
  GDBase.GDObject
EndStructure

Procedure GDSignalProbe_constructor(*self.GDSignalProbe)
EndProcedure

Procedure GDSignalProbe_destructor(*self.GDSignalProbe)
EndProcedure

; No argument at all.
Procedure GDSignalProbe_emit_none(*self.GDSignalProbe)
  emit_signal(*self, "none")
EndProcedure

Procedure GDSignalProbe_emit_float(*self.GDSignalProbe)
  Protected v.d = 1.5
  emit_signal(*self, "float_value", @v)
EndProcedure

Procedure GDSignalProbe_emit_int(*self.GDSignalProbe)
  Protected v.i = 42
  emit_signal(*self, "int_value", @v)
EndProcedure

; Godot's bool is ONE byte wide, so the storage is .a (unsigned byte).
Procedure GDSignalProbe_emit_bool(*self.GDSignalProbe)
  Protected v.a = 1
  emit_signal(*self, "bool_value", @v)
EndProcedure

Procedure GDSignalProbe_emit_vector2(*self.GDSignalProbe)
  Protected v.GDVector2
  v\x = 1.5
  v\y = 2.5
  emit_signal(*self, "vector2_value", @v)
EndProcedure

Procedure GDSignalProbe_emit_vector3(*self.GDSignalProbe)
  Protected v.GDVector3
  v\x = 1.0
  v\y = 2.0
  v\z = 3.0
  emit_signal(*self, "vector3_value", @v)
EndProcedure

Procedure GDSignalProbe_emit_color(*self.GDSignalProbe)
  Protected v.GDColor
  v\r = 0.2
  v\g = 0.4
  v\b = 0.6
  v\a = 1.0
  emit_signal(*self, "color_value", @v)
EndProcedure

; Two arguments of two different types.
Procedure GDSignalProbe_emit_pair(*self.GDSignalProbe)
  Protected i.i = 7
  Protected f.d = 2.25
  emit_signal(*self, "pair", @i, @f)
EndProcedure

Procedure GDSignalProbe_bind()
  ClassDB::bind_method(D_METHOD("emit_none"), @GDSignalProbe_emit_none())
  ClassDB::bind_method(D_METHOD("emit_float"), @GDSignalProbe_emit_float())
  ClassDB::bind_method(D_METHOD("emit_int"), @GDSignalProbe_emit_int())
  ClassDB::bind_method(D_METHOD("emit_bool"), @GDSignalProbe_emit_bool())
  ClassDB::bind_method(D_METHOD("emit_vector2"), @GDSignalProbe_emit_vector2())
  ClassDB::bind_method(D_METHOD("emit_vector3"), @GDSignalProbe_emit_vector3())
  ClassDB::bind_method(D_METHOD("emit_color"), @GDSignalProbe_emit_color())
  ClassDB::bind_method(D_METHOD("emit_pair"), @GDSignalProbe_emit_pair())

  ADD_SIGNAL("none")
  ADD_SIGNAL("float_value", #FLOAT, "v")
  ADD_SIGNAL("int_value", #INT, "v")
  ADD_SIGNAL("bool_value", #BOOL, "v")
  ADD_SIGNAL("vector2_value", #VECTOR2, "v")
  ADD_SIGNAL("vector3_value", #VECTOR3, "v")
  ADD_SIGNAL("color_value", #COLOR, "v")
  ADD_SIGNAL("pair", #INT, "a", #FLOAT, "b")
EndProcedure

Global gdsignalprobe_class.GDClassInfo
gdsignalprobe_class\instance_size = SizeOf(GDSignalProbe)
gdsignalprobe_class\constructor   = @GDSignalProbe_constructor()
gdsignalprobe_class\destructor    = @GDSignalProbe_destructor()
gdsignalprobe_class\bind_func     = @GDSignalProbe_bind()

; ---------------------------------------------------------------------------
; GDSignalPing - a signal with no argument at all.
; ---------------------------------------------------------------------------

Structure GDSignalPing
  GDBase.GDObject
  pings.l
EndStructure

Procedure GDSignalPing_constructor(*self.GDSignalPing)
  *self\pings = 0
EndProcedure

Procedure GDSignalPing_destructor(*self.GDSignalPing)
EndProcedure

Procedure.l GDSignalPing_get_pings(*self.GDSignalPing)
  ProcedureReturn *self\pings
EndProcedure

Procedure GDSignalPing_ping(*self.GDSignalPing)
  *self\pings + 1
  emit_signal(*self, "pinged")
EndProcedure

Procedure GDSignalPing_bind()
  ClassDB::bind_method(D_METHOD("pings"), @GDSignalPing_get_pings(), #INT)
  ClassDB::bind_method(D_METHOD("ping"), @GDSignalPing_ping())
  ADD_SIGNAL("pinged")
EndProcedure

Global gdsignalping_class.GDClassInfo
gdsignalping_class\instance_size = SizeOf(GDSignalPing)
gdsignalping_class\constructor   = @GDSignalPing_constructor()
gdsignalping_class\destructor    = @GDSignalPing_destructor()
gdsignalping_class\bind_func     = @GDSignalPing_bind()
