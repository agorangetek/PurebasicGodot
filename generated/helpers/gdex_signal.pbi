; ===========================================================================
; gdex_signal.pbi - emit_signal, spelled as godot-cpp spells it.
;
;     emit_signal(*self, "position_changed", @new_position)
;
; godot-cpp's emit_signal is a variadic template over Object::emit_signal, so
; the C++ compiler packs the Variant array. PureBasic has no variadics, so the
; value pointers are declared up to four and the TYPES come from the signal's
; OWN declaration - ADD_SIGNAL(MethodInfo(...)) already recorded them. That is
; why no type constant appears at an emit site: it would only repeat what the
; class already said.
;
; Object.emit_signal is variadic and cannot be ptrcalled, so the call goes
; through object_method_bind_call with real Variants, and the signal name is
; itself call-argument 0 (the "+ 1" below). godot-cpp does the same in
; Object::emit_signal.
;
; Requires generated/Object.pbi to be included and Register_Object_Binds() to
; have run at SCENE level: Object::gdb_emit_signal is that generated bind.
; ===========================================================================

; The instance's own signal.
Procedure emit_signal(*self, Name.s, *v0 = 0, *v1 = 0, *v2 = 0, *v3 = 0)
  Protected *o.GDObject = *self
  If Not Object::gdb_emit_signal Or Not *o Or Not *o\class_info Or Not *o\object
    ProcedureReturn
  EndIf
  Protected *ci.GDClassInfo = *o\class_info

  ; Find the declaration: that is where the argument types live.
  Protected want.GodotStringName
  GDEX_SNFrom(want, Name)
  Protected found.l = #False
  Protected si.l
  For si = 0 To *ci\signal_count - 1
    If GDEX_StringNameEq(@want, @*ci\signals[si]\name)
      found = #True
      Break
    EndIf
  Next si
  If Not found
    GDEX_Fail("[gdex] emit_signal: this class did not declare a signal named " + Name)
    ProcedureReturn
  EndIf
  Protected *sig.GDSignalEntry = @*ci\signals[si]
  Protected n.l = *sig\arg_count

  Protected Dim given.i(3)
  given(0) = *v0
  given(1) = *v1
  given(2) = *v2
  given(3) = *v3

  Protected j.l
  For j = 0 To n - 1
    If given(j) = 0
      GDEX_Fail("[gdex] emit_signal(" + Name + "): argument " + Str(j + 1) + " was not given")
      ProcedureReturn
    EndIf
  Next j

  ; Object.emit_signal(signal: StringName, ...) - the name is call-argument 0,
  ; so the Variant list is one longer than the signal's own argument count.
  Protected *vsig = GDEX_NewVariant()
  GDEX_VariantFromType(*vsig, #STRINGNAME, @want)
  Protected Dim args.i(n)
  args(0) = *vsig
  For j = 0 To n - 1
    Protected *av = GDEX_NewVariant()
    GDEX_VariantFromType(*av, *sig\args[j]\vtype, given(j))
    args(j + 1) = *av
  Next j

  Protected *ret = GDEX_NewVariant()
  Protected err.GDExtensionCallError
  g_object_method_bind_call(Object::gdb_emit_signal, *o\object, @args(0), n + 1, *ret, @err)

  GDEX_FreeVariant(*vsig)
  For j = 0 To n - 1
    GDEX_FreeVariant(args(j + 1))
  Next j
  GDEX_FreeVariant(*ret)
EndProcedure
