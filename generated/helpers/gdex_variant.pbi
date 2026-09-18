; ===========================================================================
; gdex_variant.pbi - native value <-> Variant, for EVERY type.
;
; Godot hands out one constructor per Variant type:
;
;   get_variant_from_type_constructor(type)  -> (VariantPtr dest, TypePtr src)
;   get_variant_to_type_constructor(type)    -> (TypePtr dest, VariantPtr src)
;
; so a single pair of procedures covers every builtin - float, int, bool,
; Vector2, Vector3, Color, Transform3D, Basis, RID, String, Object, Array,
; Dictionary, ... There is deliberately nothing per-type here.
;
; `src` is a pointer to the native value, and the type constant says how to
; read it. For the pointer-sized types (String, StringName, Object, Array,
; Dictionary) that means a pointer to the Godot object itself, which the caller
; owns and must destroy - this layer constructs Variants, not Godot objects.
; ===========================================================================

; Native value -> Variant.
Procedure GDEX_VariantFromType(*dest, vtype.l, *src)
  Protected ctor.GDExtensionVariantFromTypeConstructorFunc
  ctor = g_get_variant_from_type(vtype)
  If ctor
    ctor(*dest, *src)
  EndIf
EndProcedure

; Variant -> native value.
Procedure GDEX_TypeFromVariant(*dest, vtype.l, *variant)
  Protected ctor.GDExtensionTypeFromVariantConstructorFunc
  ctor = g_get_variant_to_type(vtype)
  If ctor
    ctor(*dest, *variant)
  EndIf
EndProcedure

; Scratch storage for one Variant: 24 opaque bytes, nothing more.
Procedure.i GDEX_NewVariant()
  ProcedureReturn AllocateMemory(#GDEX_VARIANT_SIZE)
EndProcedure

; Release one that GDEX_NewVariant made.
Procedure GDEX_FreeVariant(*v)
  If *v
    g_variant_destroy(*v)
    FreeMemory(*v)
  EndIf
EndProcedure
