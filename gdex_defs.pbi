; ===========================================================================
; gdex_defs.pbi - constants, framework structures and shared globals.
;
; Included FIRST, before gdex_api.pbi. Nothing here calls Godot; it only
; describes what the framework and the user classes agree on.
;
; The one hard rule: a user class structure must begin with GDObject, because
; every generic callback Godot makes (set/get/notification/virtual) receives
; only the instance pointer - GDObject\class_info is how the framework finds
; the rest of the descriptor.
; ===========================================================================

IncludeFile "gdex_types.pbi"

; ---- GDExtensionInitializationLevel ---------------------------------------
#GDEXTENSION_INITIALIZATION_CORE    = 0
#GDEXTENSION_INITIALIZATION_SERVERS = 1
#GDEXTENSION_INITIALIZATION_SCENE   = 2
#GDEXTENSION_INITIALIZATION_EDITOR  = 3

; ---- GDExtensionVariantType (the full enumeration) -----------------------
#GDEXTENSION_VARIANT_TYPE_NIL          = 0
#GDEXTENSION_VARIANT_TYPE_BOOL         = 1
#GDEXTENSION_VARIANT_TYPE_INT          = 2
#GDEXTENSION_VARIANT_TYPE_FLOAT        = 3
#GDEXTENSION_VARIANT_TYPE_STRING       = 4
#GDEXTENSION_VARIANT_TYPE_VECTOR2      = 5
#GDEXTENSION_VARIANT_TYPE_VECTOR2I     = 6
#GDEXTENSION_VARIANT_TYPE_RECT2        = 7
#GDEXTENSION_VARIANT_TYPE_RECT2I       = 8
#GDEXTENSION_VARIANT_TYPE_VECTOR3      = 9
#GDEXTENSION_VARIANT_TYPE_VECTOR3I     = 10
#GDEXTENSION_VARIANT_TYPE_TRANSFORM2D  = 11
#GDEXTENSION_VARIANT_TYPE_VECTOR4      = 12
#GDEXTENSION_VARIANT_TYPE_VECTOR4I     = 13
#GDEXTENSION_VARIANT_TYPE_PLANE        = 14
#GDEXTENSION_VARIANT_TYPE_QUATERNION   = 15
#GDEXTENSION_VARIANT_TYPE_AABB         = 16
#GDEXTENSION_VARIANT_TYPE_BASIS        = 17
#GDEXTENSION_VARIANT_TYPE_TRANSFORM3D  = 18
#GDEXTENSION_VARIANT_TYPE_PROJECTION   = 19
#GDEXTENSION_VARIANT_TYPE_COLOR        = 20
#GDEXTENSION_VARIANT_TYPE_STRING_NAME  = 21
#GDEXTENSION_VARIANT_TYPE_NODE_PATH    = 22
#GDEXTENSION_VARIANT_TYPE_RID          = 23
#GDEXTENSION_VARIANT_TYPE_OBJECT       = 24
#GDEXTENSION_VARIANT_TYPE_CALLABLE     = 25
#GDEXTENSION_VARIANT_TYPE_SIGNAL       = 26
#GDEXTENSION_VARIANT_TYPE_DICTIONARY   = 27
#GDEXTENSION_VARIANT_TYPE_ARRAY        = 28

; ---- Short aliases for the Variant types -----------------------------------
; godot-cpp writes PropertyInfo(Variant::FLOAT, ...) and lets the compiler
; resolve Variant::FLOAT. PureBasic has no constants inside a module and no
; enum scoping, so the same idea is spelled #FLOAT. These are the types a
; class surface normally mentions; anything else uses the long
; #GDEXTENSION_VARIANT_TYPE_* name.
;
; #VOID is the "no return value" type - C++'s void, Godot's NIL.
#VOID         = #GDEXTENSION_VARIANT_TYPE_NIL
#BOOL         = #GDEXTENSION_VARIANT_TYPE_BOOL
#INT          = #GDEXTENSION_VARIANT_TYPE_INT
#FLOAT        = #GDEXTENSION_VARIANT_TYPE_FLOAT
#STRING       = #GDEXTENSION_VARIANT_TYPE_STRING
#VECTOR2      = #GDEXTENSION_VARIANT_TYPE_VECTOR2
#VECTOR2I     = #GDEXTENSION_VARIANT_TYPE_VECTOR2I
#RECT2        = #GDEXTENSION_VARIANT_TYPE_RECT2
#RECT2I       = #GDEXTENSION_VARIANT_TYPE_RECT2I
#VECTOR3      = #GDEXTENSION_VARIANT_TYPE_VECTOR3
#VECTOR3I     = #GDEXTENSION_VARIANT_TYPE_VECTOR3I
#TRANSFORM2D  = #GDEXTENSION_VARIANT_TYPE_TRANSFORM2D
#VECTOR4      = #GDEXTENSION_VARIANT_TYPE_VECTOR4
#VECTOR4I     = #GDEXTENSION_VARIANT_TYPE_VECTOR4I
#PLANE        = #GDEXTENSION_VARIANT_TYPE_PLANE
#QUATERNION   = #GDEXTENSION_VARIANT_TYPE_QUATERNION
#AABB         = #GDEXTENSION_VARIANT_TYPE_AABB
#BASIS        = #GDEXTENSION_VARIANT_TYPE_BASIS
#TRANSFORM3D  = #GDEXTENSION_VARIANT_TYPE_TRANSFORM3D
#PROJECTION   = #GDEXTENSION_VARIANT_TYPE_PROJECTION
#COLOR        = #GDEXTENSION_VARIANT_TYPE_COLOR
#STRINGNAME   = #GDEXTENSION_VARIANT_TYPE_STRING_NAME
#NODEPATH     = #GDEXTENSION_VARIANT_TYPE_NODE_PATH
#RID          = #GDEXTENSION_VARIANT_TYPE_RID
#OBJECT       = #GDEXTENSION_VARIANT_TYPE_OBJECT
#CALLABLE     = #GDEXTENSION_VARIANT_TYPE_CALLABLE
#SIGNAL       = #GDEXTENSION_VARIANT_TYPE_SIGNAL
#DICTIONARY   = #GDEXTENSION_VARIANT_TYPE_DICTIONARY
#ARRAY        = #GDEXTENSION_VARIANT_TYPE_ARRAY

; ---- GDExtensionVariantOperator (only EQUAL is used) ---------------------
#GDEXTENSION_VARIANT_OP_EQUAL = 0

; ---- GDExtensionClassMethodFlags -----------------------------------------
#GDEXTENSION_METHOD_FLAG_NORMAL = 1
#GDEXTENSION_METHOD_FLAG_CONST  = 4

; ---- GDExtensionClassMethodArgumentMetadata ------------------------------
#GDEXTENSION_METHOD_ARGUMENT_METADATA_NONE          = 0
#GDEXTENSION_METHOD_ARGUMENT_METADATA_INT_IS_INT32  = 3
#GDEXTENSION_METHOD_ARGUMENT_METADATA_REAL_IS_FLOAT = 9
#GDEXTENSION_METHOD_ARGUMENT_METADATA_REAL_IS_DOUBLE = 10

; ---- PropertyUsageFlags ---------------------------------------------------
#PROPERTY_USAGE_STORAGE   = 2
#PROPERTY_USAGE_EDITOR    = 4
#PROPERTY_USAGE_DEFAULT   = 6
#PROPERTY_USAGE_READ_ONLY = 268435456 ; 1 << 28

; Godot's Variant is 24 bytes and opaque. Nothing here looks inside one; code
; only ever hands its address to the interface.
#GDEX_VARIANT_SIZE = 24

; ---- Object / Node notifications -----------------------------------------
#NOTIFICATION_POSTINITIALIZE = 0
#NOTIFICATION_READY          = 13
#NOTIFICATION_PROCESS        = 17

; ---- Method shapes the generic dispatcher understands --------------------
#GDEX_SHAPE_VOID_0  = 0 ; Procedure(*self)
#GDEX_SHAPE_VOID_1F = 1 ; Procedure(*self, v.d)
#GDEX_SHAPE_F64_0   = 2 ; Procedure.d(*self)
#GDEX_SHAPE_F64_1F  = 3 ; Procedure.d(*self, v.d)
#GDEX_SHAPE_VOID_1I = 4 ; Procedure(*self, v.l)
#GDEX_SHAPE_I64_0   = 5 ; Procedure.i(*self)

; ---- Godot builtin types ------------------------------------------------
;
; One generic mechanism covers every plain builtin. The entry carries the
; Variant type and the native size, so nothing is special-cased per type:
; Vector2, Vector3, Color, Rect2, Transform2D, Basis, Projection, ...
;
; A PureBasic procedure cannot return a structure, so a result comes back
; through a caller-provided out parameter:
;     Procedure Foo_get_span(*self.Foo, *out.GDVector2)
;     Procedure Foo_set_span(*self.Foo, *in.GDVector2)
#GDEX_SHAPE_BUILTIN_RET     = 6 ; Procedure(*self, *out)
#GDEX_SHAPE_BUILTIN_ARG     = 7 ; Procedure(*self, *in)
#GDEX_SHAPE_BUILTIN_ARG_RET = 8 ; Procedure(*self, *in, *out)

#GDEX_MAX_PROPS       = 32
#GDEX_MAX_METHODS     = 64
#GDEX_MAX_CLASSES     = 8
#GDEX_MAX_SINGLETONS  = 8
#GDEX_MAX_SIGNALS     = 8
#GDEX_MAX_SIGNAL_ARGS = 4
#GDEX_NO_TYPE         = -1 ; "this argument was not supplied"

; A Godot StringName is one pointer of storage. It is interned by Godot, so
; two StringNames holding the same text share their data pointer, which is
; what GDEX_StringNameEq relies on.
Structure GodotStringName Align #PB_Structure_AlignC
  data.i
EndStructure

; First field of every user class.
Structure GDObject Align #PB_Structure_AlignC
  object.i     ; the Godot Object* this instance is bound to
  class_info.i ; GDClassInfo* - set by the framework at creation
EndStructure

; One registered property. `name` is the Godot StringName the framework is
; handed in set/get; `getter`/`setter` are the user's procedures, and they are
; ALSO registered as the `get_<name>` / `set_<name>` methods the property
; points at, which is how Godot resolves `obj.name` in GDScript.
Structure GDPropEntry Align #PB_Structure_AlignC
  name.GodotStringName
  getter_sn.GodotStringName
  setter_sn.GodotStringName
  ptype.l   ; GDExtensionVariantType
  psize.l   ; native size of that type, 0 for the float/int fast paths
  getter.i
  setter.i
EndStructure

; One registered method. `func` is the user's procedure; `shape` says how to
; call it; `userdata` is what Godot hands back to the generic dispatcher.
Structure GDMethodEntry Align #PB_Structure_AlignC
  name.GodotStringName
  func.i
  shape.l
  arg_meta.l
  ; Only used by the generic builtin shapes.
  arg_type.l
  arg_size.l
  ret_type.l
  ret_size.l
EndStructure

; One declared signal argument: its name and its Variant type, both taken from
; ADD_SIGNAL(MethodInfo("bounced", PropertyInfo(#VECTOR2, "position"))).
Structure GDSignalArg Align #PB_Structure_AlignC
  name.GodotStringName
  vtype.l
  vtype_size.l
EndStructure

; One declared signal. A class may declare several, as in godot-cpp.
Structure GDSignalEntry Align #PB_Structure_AlignC
  name.GodotStringName
  arg_count.l
  args.GDSignalArg[#GDEX_MAX_SIGNAL_ARGS]
EndStructure

; The per-class descriptor. A user class fills the first block itself and the
; framework fills everything from `class_name` down during registration, so a
; user file only ever names the fields above the line.
Structure GDClassInfo Align #PB_Structure_AlignC
  ; ---- written by the user class ----
  instance_size.i
  constructor.i
  destructor.i
  process.i
  bind_func.i
  ; Optional, and only needed if the class has PureBasic-managed members
  ; (List, Map, dynamic array). They must be a MATCHING pair:
  ;   AllocateStructure(T)                    -> FreeStructure(*p)
  ;   AllocateMemory(SizeOf(T))+Initialize... -> ClearStructure+FreeMemory
  ; Mixing them crashes at free time. See GDEX_Instantiate.
  alloc_func.i
  free_func.i
  ; Signals are NOT declared here. They are declared in bind_func with
  ; ADD_SIGNAL(MethodInfo(...)), exactly as in godot-cpp's _bind_methods, and
  ; land in the table below.
  ; ---- written by RegisterGDClass ----
  registered.l
  class_name.GodotStringName
  parent_name.GodotStringName
  signal_count.l
  signals.GDSignalEntry[#GDEX_MAX_SIGNALS]
  is_node.l
  index.l
  prop_count.l
  props.GDPropEntry[#GDEX_MAX_PROPS]
  method_count.l
  methods.GDMethodEntry[#GDEX_MAX_METHODS]
EndStructure

; Set by gdexample_library_init before anything is registered.
Global GDExtensionClassLibraryPtr.i = 0

; Registration bookkeeping.
Global gdex_class_count.l = 0
Global Dim gdex_classes.i(#GDEX_MAX_CLASSES)
Global Dim gdex_class_level.l(#GDEX_MAX_CLASSES)

; ---- automatic initialization-level handling ------------------------------
; gdex_level is what the framework thinks the current level is. It defaults to
; SCENE, which means "assume every parent already exists" - an extension that
; drives the levels itself, without GDEX_Initialize, keeps working exactly as
; before. GDEX_Initialize lowers it to CORE, and then a class whose parent is
; not Object is QUEUED instead of being registered too early.
Global gdex_level.l = #GDEXTENSION_INITIALIZATION_SCENE
Global gdex_declared.l = #False
Global gdex_binds_resolved.l = #False
Global gdex_pending_class_count.l = 0
Global Dim gdex_pending_ci.i(#GDEX_MAX_CLASSES)
Global Dim gdex_pending_name.s(#GDEX_MAX_CLASSES)
Global Dim gdex_pending_parent.s(#GDEX_MAX_CLASSES)

; Singletons, so the framework can tear down at the level it created them.
Global gdex_pending_singleton_count.l = 0
Global Dim gdex_pending_singleton_ci.i(#GDEX_MAX_SINGLETONS)
Global Dim gdex_pending_singleton_name.s(#GDEX_MAX_SINGLETONS)
Global gdex_singleton_count.l = 0
Global Dim gdex_singleton_name.s(#GDEX_MAX_SINGLETONS)
Global Dim gdex_singleton_obj.i(#GDEX_MAX_SINGLETONS)
Global Dim gdex_singleton_level.l(#GDEX_MAX_SINGLETONS)
; Address of the GDClassInfo currently being registered, so the
; ClassDB_bind_method / ADD_PROPERTY / ADD_SIGNAL calls made from a class's
; bind_func land on the right one.
Global gdex_current.i = 0

; Godot's PropertyInfo constructor dereferences name, class_name and
; hint_string unconditionally, so an absent one must be a valid EMPTY Godot
; object rather than a null pointer. godot-cpp does the same thing.
Global gdex_empty_sn.GodotStringName        ; empty StringName
Global gdex_empty_string.i = 0              ; empty Godot String (8 bytes)

Global gdex_sn_process.GodotStringName

; Call the per-class `process` at NOTIFICATION_PROCESS instead of through
; Godot's virtual-method mechanism. 0 = use the virtual (verified working on
; 4.8.dev6 with get_virtual_call_data_func / call_virtual_with_data_func);
; flip to 1 if `_process` ever stops firing.
Global gdex_process_via_notification.l = 0

; Registration trace, printed through Godot's print_error. Set to 1 to see
; every class, method and property as it is registered.
Global gdex_trace.l = 0
