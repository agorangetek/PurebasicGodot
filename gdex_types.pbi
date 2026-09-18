; ===========================================================================
; gdex_types.pbi - the native layout of Godot's plain builtin types.
;
; Sizes are taken from Godot's own extension_api.json, build configuration
; float_64 (single-precision real_t, 64-bit pointers) - which is what an
; official macOS build is:
;
;   Vector2  8   Vector2i  8   Rect2  16   Rect2i 16
;   Vector3 12   Vector3i 12   Vector4 16
;   Plane   16   Quaternion 16  Color 16
;   AABB    24   Basis     36   Transform2D 24
;   Transform3D 48   Projection 64   RID 8
;
; In a double-precision build (precision=double) every real_t-based type
; doubles its float components - Vector2 becomes 16, Transform3D 96, and so
; on. These declarations would have to change to .d, exactly as godot-cpp
; does at build time.
;
; Types NOT here on purpose: String, StringName, NodePath, Object, RID*,
; Dictionary, Array and the Packed*Array family are pointer-sized Godot
; objects with their own constructors and destructors. Passing them across
; needs explicit create/destroy rather than a plain struct copy - see the
; README.
; ===========================================================================

Structure GDVector2 Align #PB_Structure_AlignC
  x.f
  y.f
EndStructure

Structure GDVector2i Align #PB_Structure_AlignC
  x.l
  y.l
EndStructure

Structure GDRect2 Align #PB_Structure_AlignC
  position.GDVector2
  size.GDVector2
EndStructure

Structure GDRect2i Align #PB_Structure_AlignC
  position.GDVector2i
  size.GDVector2i
EndStructure

Structure GDVector3 Align #PB_Structure_AlignC
  x.f
  y.f
  z.f
EndStructure

Structure GDVector3i Align #PB_Structure_AlignC
  x.l
  y.l
  z.l
EndStructure

Structure GDVector4 Align #PB_Structure_AlignC
  x.f
  y.f
  z.f
  w.f
EndStructure

Structure GDColor Align #PB_Structure_AlignC
  r.f
  g.f
  b.f
  a.f
EndStructure

Structure GDPlane Align #PB_Structure_AlignC
  normal.GDVector3
  d.f
EndStructure

Structure GDQuaternion Align #PB_Structure_AlignC
  x.f
  y.f
  z.f
  w.f
EndStructure

Structure GDAABB Align #PB_Structure_AlignC
  position.GDVector3
  size.GDVector3
EndStructure

Structure GDBasis Align #PB_Structure_AlignC
  rows.GDVector3[3]
EndStructure

Structure GDTransform2D Align #PB_Structure_AlignC
  x.GDVector2
  y.GDVector2
  origin.GDVector2
EndStructure

Structure GDTransform3D Align #PB_Structure_AlignC
  basis.GDBasis
  origin.GDVector3
EndStructure

Structure GDProjection Align #PB_Structure_AlignC
  columns.GDVector4[4]
EndStructure

Structure GDRID Align #PB_Structure_AlignC
  id.q
EndStructure
