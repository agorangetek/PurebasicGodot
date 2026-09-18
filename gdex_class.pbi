; ===========================================================================
; gdex_class.pbi - the framework itself.
;
; Included after the generated/*.pbi files, so the bind globals they declare
; already exist. It supplies:
;
;   RegisterGDClass(descriptor, "Name", "Parent")
;       registers one class with Godot, wiring every generic callback below
;       and replaying whatever the class's bind_func declared.
;
;   ClassDB::bind_method / ADD_PROPERTY / ADD_SIGNAL   (generated/helpers/)
;       what a user class calls from its bind_func - godot-cpp's surface.
;
;   GD_RegisterSingleton / GD_UnregisterSingleton
;       Engine.register_singleton over an instance the framework made.
;
; HOW AN INSTANCE IS LAID OUT
;
;   instance -> [ GDObject { object, class_info } ][ the user's own fields ]
;
; GDObject is first because every generic callback Godot makes hands back only
; the instance pointer; class_info is how the callbacks get from there to the
; descriptor. This mirrors godot-cpp, which constructs the native object with
; classdb_construct_object(<parent>) and then binds its own instance with
; object_set_instance(<object>, <extension class>, <instance>).
; ===========================================================================

; ---- the callback signatures the framework fills in -----------------------

Prototype.i GDEXAlloc()
Prototype GDEXFree(*instance)
Prototype GDEXCtor(*self)
Prototype GDEXDtor(*self)
Prototype GDEXBind()
Prototype GDEXProcess(*self, delta.d)

Prototype GDEXVoid0(*self)
Prototype GDEXVoid1F(*self, v.d)
Prototype GDEXVoid1I(*self, v.l)
Prototype.d GDEXF64_0(*self)
Prototype.i GDEXI64_0(*self)
Prototype.d GDEXFloatGetter(*self)
Prototype GDEXFloatSetter(*self, v.d)
Prototype.i GDEXIntGetter(*self)
Prototype GDEXIntSetter(*self, v.l)
; The three generic builtin prototypes. *in and *out point at a buffer whose
; size and Variant type come from the entry, so one prototype serves every
; builtin type.
Prototype GDEXBuiltinOut(*self, *out)
Prototype GDEXBuiltinIn(*self, *in)
Prototype GDEXBuiltinInOut(*self, *in, *out)

; ===========================================================================
; THE FRAMEWORK'S OWN BINDS
;
; The framework needs four engine methods:
;
;   Node.set_process, Node.get_process_delta_time   the notification-based
;                                                   _process path
;   Engine.register_singleton, Engine.unregister_singleton
;                                                   GD_RegisterSingleton
;
; It resolves them itself instead of importing them from generated/, which is
; what makes gdex_class.pbi depend on NO generated file: a project includes
; only the class files it actually uses.
;
; Resolving them here is also a correctness matter, not just tidiness. These
; files do not EnableExplicit, so a name that is merely *missing* does not
; fail the build - PureBasic silently invents a local for it, and the call
; quietly does nothing. Self-resolving removes the possibility.
;
; They are resolved LAZILY, at first use, and deliberately not all at once:
;
;   Engine is a core class, and GD_RegisterSingleton is called as early as
;   CORE. Node is not - it belongs to the scene half of ClassDB, so asking for
;   its method binds at CORE returns null and Godot logs
;   `Parameter "mb" is null`. Resolving on first use puts each lookup after
;   the level that actually owns the class.
;
; The hashes are literal so that tools/gen_binds --check verifies them on
; every build, exactly like the generated files.
; ===========================================================================

Global gdex_node_set_process_bind.i = 0
Global gdex_node_get_delta_bind.i = 0
Global gdex_node_binds_done.l = #False
Global gdex_engine_obj.i = 0
Global gdex_engine_register_bind.i = 0
Global gdex_engine_unregister_bind.i = 0
Global gdex_engine_binds_done.l = #False

; Node.set_process / Node.get_process_delta_time. Used only by the
; notification-based _process path, which runs at runtime, never at CORE.
Procedure GDEX_EnsureNodeBinds()
  If gdex_node_binds_done Or Not g_classdb_get_method_bind
    ProcedureReturn
  EndIf
  Protected nodeSn.GodotStringName
  Protected setSn.GodotStringName
  Protected deltaSn.GodotStringName
  GDEX_SNFrom(nodeSn, "Node")
  GDEX_SNFrom(setSn, "set_process")
  GDEX_SNFrom(deltaSn, "get_process_delta_time")
  gdex_node_set_process_bind = _pGetMethodBind(@nodeSn, @setSn, 2586408642)
  gdex_node_get_delta_bind = _pGetMethodBind(@nodeSn, @deltaSn, 1740695150)
  gdex_node_binds_done = #True
EndProcedure

; Engine.register_singleton / unregister_singleton, and the Engine singleton
; object itself, which the caller does not have to supply.
Procedure GDEX_EnsureEngineBinds()
  If gdex_engine_binds_done Or Not g_classdb_get_method_bind
    ProcedureReturn
  EndIf
  Protected engineSn.GodotStringName
  Protected regSn.GodotStringName
  Protected unregSn.GodotStringName
  GDEX_SNFrom(engineSn, "Engine")
  GDEX_SNFrom(regSn, "register_singleton")
  GDEX_SNFrom(unregSn, "unregister_singleton")
  gdex_engine_obj = g_global_get_singleton(@engineSn)
  gdex_engine_register_bind = _pGetMethodBind(@engineSn, @regSn, 965313290)
  gdex_engine_unregister_bind = _pGetMethodBind(@engineSn, @unregSn, 3304788590)
  gdex_engine_binds_done = #True
EndProcedure

; Node.set_process(true) - only used when gdex_process_via_notification is on.
Procedure GDEX_EnableProcessing(*object)
  GDEX_EnsureNodeBinds()
  If Not gdex_node_set_process_bind Or Not *object
    ProcedureReturn
  EndIf
  Protected on.l = #True
  Protected Dim ap.i(0)
  ap(0) = @on
  g_object_method_bind_ptrcall(gdex_node_set_process_bind, *object, @ap(0), #Null)
EndProcedure

; Node.get_process_delta_time()
Procedure.d GDEX_ProcessDelta(*object)
  GDEX_EnsureNodeBinds()
  If Not gdex_node_get_delta_bind Or Not *object
    ProcedureReturn 0.0
  EndIf
  Protected out.d
  g_object_method_bind_ptrcall(gdex_node_get_delta_bind, *object, #Null, @out)
  ProcedureReturn out
EndProcedure

; ===========================================================================
; INSTANCE LIFECYCLE
; ===========================================================================

; Build the Godot object, allocate and bind our instance data, run the user's
; constructor. Returns the Object* (0 on failure) - which is what
; GDExtensionClassCreateInstance3 must return on Godot 4.4+.
Procedure.i GDEX_Instantiate(*ci.GDClassInfo)
  If Not *ci Or Not g_classdb_construct_object3
    ProcedureReturn 0
  EndIf

  ; Construct the nearest NATIVE ancestor. Constructing our own extension
  ; class name here would re-enter this function.
  Protected obj = g_classdb_construct_object3(@*ci\parent_name)
  If Not obj
    ProcedureReturn 0
  EndIf

  If *ci\instance_size <= 0
    ProcedureReturn obj
  EndIf

  ; Instance storage. A class with PureBasic-managed members (List, Map,
  ; dynamic array) supplies alloc_func/free_func, because those members need
  ; InitializeStructure, which raw AllocateMemory does not do - touching a
  ; List in a raw block segfaults. Everything else uses plain memory, which
  ; FillMemory is enough for.
  Protected *inst
  If *ci\alloc_func
    Protected af.GDEXAlloc = *ci\alloc_func
    *inst = af()
  Else
    *inst = AllocateMemory(*ci\instance_size)
    If *inst
      FillMemory(*inst, *ci\instance_size, 0)
    EndIf
  EndIf
  If Not *inst
    ProcedureReturn obj
  EndIf

  Protected *o.GDObject = *inst
  *o\object = obj
  *o\class_info = *ci

  If *ci\constructor
    Protected ctor.GDEXCtor = *ci\constructor
    ctor(*inst)
  EndIf

  g_object_set_instance(obj, @*ci\class_name, *inst)
  g_object_set_instance_binding(obj, GDExtensionClassLibraryPtr, *inst, @gdex_binding_callbacks)

  If gdex_process_via_notification And *ci\is_node
    GDEX_EnableProcessing(obj)
  EndIf

  ProcedureReturn obj
EndProcedure

Procedure.i GDEX_CreateInstance(*class_userdata, notify_postinitialize.a)
  ProcedureReturn GDEX_Instantiate(*class_userdata)
EndProcedure

ProcedureC GDEX_FreeInstance(*class_userdata, *instance)
  If Not *instance
    ProcedureReturn
  EndIf
  Protected *ci.GDClassInfo = *class_userdata
  If *ci And *ci\destructor
    Protected dtor.GDEXDtor = *ci\destructor
    dtor(*instance)
  EndIf
  ; Free the same way it was allocated: FreeStructure undoes
  ; AllocateStructure, ClearStructure+FreeMemory undoes the plain path.
  If *ci And *ci\free_func
    Protected ff.GDEXFree = *ci\free_func
    ff(*instance)
  Else
    FreeMemory(*instance)
  EndIf
EndProcedure

; ===========================================================================
; PROPERTY GET / SET
;
; These are the class-wide GDExtensionClassSet / GDExtensionClassGet callbacks.
; They are what `obj.set("amplitude", v)` and `obj.get("amplitude")` reach.
; The property syntax `obj.amplitude` goes through the set_/get_ methods bound
; alongside the property, so both routes work.
; ===========================================================================

; Native <-> Variant for any builtin, using the constructor Godot hands out
; for that Variant type. One pair of procedures covers every type.
Procedure GDEX_WrapVariant(*dest, vtype.l, *src)
  Protected ctor.GDExtensionVariantFromTypeConstructorFunc
  ctor = g_get_variant_from_type(vtype)
  If ctor
    ctor(*dest, *src)
  EndIf
EndProcedure

Procedure GDEX_UnwrapVariant(*dest, vtype.l, *variant)
  Protected ctor.GDExtensionTypeFromVariantConstructorFunc
  ctor = g_get_variant_to_type(vtype)
  If ctor
    ctor(*dest, *variant)
  EndIf
EndProcedure

ProcedureC GDEX_Set(*instance, *name, *value)
  Protected *o.GDObject = *instance
  If Not *o\class_info
    ProcedureReturn #False
  EndIf
  Protected *ci.GDClassInfo = *o\class_info
  Protected i
  For i = 0 To *ci\prop_count - 1
    If GDEX_StringNameEq(*name, @*ci\props[i]\name)
      If *ci\props[i]\ptype = #GDEXTENSION_VARIANT_TYPE_FLOAT
        Protected v.d
        g_to_float(@v, *value)
        If *ci\props[i]\setter
          Protected sf.GDEXFloatSetter = *ci\props[i]\setter
          sf(*instance, v)
        EndIf
      ElseIf *ci\props[i]\ptype = #GDEXTENSION_VARIANT_TYPE_INT
        Protected iv.l
        g_to_int(@iv, *value)
        If *ci\props[i]\setter
          Protected si.GDEXIntSetter = *ci\props[i]\setter
          si(*instance, iv)
        EndIf
      Else
        ; Every other builtin: unwrap the Variant into a buffer of the
        ; property's native size and let the setter read it.
        Protected ssz.l = *ci\props[i]\psize
        If ssz > 0
          Protected *sbuf = AllocateMemory(ssz)
          If *sbuf
            GDEX_UnwrapVariant(*sbuf, *ci\props[i]\ptype, *value)
            If *ci\props[i]\setter
              Protected gsb.GDEXBuiltinIn = *ci\props[i]\setter
              gsb(*instance, *sbuf)
            EndIf
            FreeMemory(*sbuf)
          EndIf
        EndIf
      EndIf
      ProcedureReturn #True
    EndIf
  Next
  ProcedureReturn #False
EndProcedure

ProcedureC GDEX_Get(*instance, *name, *r_ret)
  Protected *o.GDObject = *instance
  If Not *o\class_info
    ProcedureReturn #False
  EndIf
  Protected *ci.GDClassInfo = *o\class_info
  Protected i
  For i = 0 To *ci\prop_count - 1
    If GDEX_StringNameEq(*name, @*ci\props[i]\name)
      If *ci\props[i]\ptype = #GDEXTENSION_VARIANT_TYPE_FLOAT
        Protected v.d
        If *ci\props[i]\getter
          Protected gf.GDEXFloatGetter = *ci\props[i]\getter
          v = gf(*instance)
        EndIf
        g_from_float(*r_ret, @v)
      ElseIf *ci\props[i]\ptype = #GDEXTENSION_VARIANT_TYPE_INT
        Protected iv.l
        If *ci\props[i]\getter
          Protected gi.GDEXIntGetter = *ci\props[i]\getter
          iv = gi(*instance)
        EndIf
        g_from_int(*r_ret, @iv)
      Else
        Protected gsz.l = *ci\props[i]\psize
        If gsz > 0
          Protected *gbuf = AllocateMemory(gsz)
          If *gbuf
            FillMemory(*gbuf, gsz, 0)
            If *ci\props[i]\getter
              Protected ggb.GDEXBuiltinOut = *ci\props[i]\getter
              ggb(*instance, *gbuf)
            EndIf
            GDEX_WrapVariant(*r_ret, *ci\props[i]\ptype, *gbuf)
            FreeMemory(*gbuf)
          EndIf
        EndIf
      EndIf
      ProcedureReturn #True
    EndIf
  Next
  ProcedureReturn #False
EndProcedure

; Godot calls this to render the object in the editor/debugger. Not providing
; class-specific text is fine; refuse politely.
ProcedureC GDEX_ToString(*instance, *r_is_valid, *p_out)
  PokeA(*r_is_valid, #False)
EndProcedure

; ===========================================================================
; NOTIFICATION AND THE _process VIRTUAL
;
; Two routes to the same per-class `process` pointer:
;   * get_virtual_call_data_func / call_virtual_with_data_func - Godot asks
;     "is _process overridden?" and calls back with whatever userdata we
;     returned (the descriptor), plus the delta as a raw double.
;   * notification_func at NOTIFICATION_PROCESS - used only when
;     gdex_process_via_notification is set to 1.
; ===========================================================================

ProcedureC GDEX_Notification(*instance, what.l, reversed.a)
  Protected *o.GDObject = *instance
  If Not *o\class_info
    ProcedureReturn
  EndIf
  If what = #NOTIFICATION_PROCESS And gdex_process_via_notification
    Protected *ci.GDClassInfo = *o\class_info
    If *ci\process
      Protected p.GDEXProcess = *ci\process
      p(*instance, GDEX_ProcessDelta(*o\object))
    EndIf
  EndIf
EndProcedure

; Returning non-null tells Godot the virtual IS overridden, and hands back the
; value it will pass to call_virtual_with_data_func.
Procedure.i GDEX_GetVirtualCallData(*class_userdata, *name, hash.l)
  Protected *ci.GDClassInfo = *class_userdata
  If Not *ci
    ProcedureReturn 0
  EndIf
  If *ci\process And GDEX_StringNameEq(*name, @gdex_sn_process)
    ProcedureReturn *class_userdata
  EndIf
  ProcedureReturn 0
EndProcedure

ProcedureC GDEX_CallVirtualWithData(*instance, *name, *vdata, *args, *r_ret)
  If Not *vdata Or Not *args
    ProcedureReturn
  EndIf
  Protected *ci.GDClassInfo = *vdata
  If Not *ci\process
    ProcedureReturn
  EndIf
  ; p_args is an array of pointers to the raw argument values, so _process's
  ; single double arrives as *args[0] -> double.
  Protected delta.d = PeekD(PeekI(*args))
  Protected p.GDEXProcess = *ci\process
  p(*instance, delta)
EndProcedure

; ===========================================================================
; METHOD DISPATCH
;
; Every method of every class shares these two procedures. Which user
; procedure to run comes from method_userdata, which is the GDMethodEntry the
; framework registered.
; ===========================================================================

Procedure.d GDEX_ArgDouble(*args, index.l)
  Protected *var = PeekI(*args + index * SizeOf(Integer))
  Protected v.d
  g_to_float(@v, *var)
  ProcedureReturn v
EndProcedure

; The Variant type and the metadata for each shape, in one place so the
; dispatchers and the registration cannot drift apart.
Procedure.l GDEX_MethodArgType(*m.GDMethodEntry)
  Select *m\shape
    Case #GDEX_SHAPE_VOID_1F  : ProcedureReturn #GDEXTENSION_VARIANT_TYPE_FLOAT
    Case #GDEX_SHAPE_VOID_1I  : ProcedureReturn #GDEXTENSION_VARIANT_TYPE_INT
    Case #GDEX_SHAPE_BUILTIN_ARG, #GDEX_SHAPE_BUILTIN_ARG_RET : ProcedureReturn *m\arg_type
  EndSelect
  ProcedureReturn #GDEXTENSION_VARIANT_TYPE_NIL
EndProcedure

Procedure.l GDEX_MethodRetType(*m.GDMethodEntry)
  Select *m\shape
    Case #GDEX_SHAPE_F64_0 : ProcedureReturn #GDEXTENSION_VARIANT_TYPE_FLOAT
    Case #GDEX_SHAPE_I64_0 : ProcedureReturn #GDEXTENSION_VARIANT_TYPE_INT
    Case #GDEX_SHAPE_BUILTIN_RET, #GDEX_SHAPE_BUILTIN_ARG_RET : ProcedureReturn *m\ret_type
  EndSelect
  ProcedureReturn #GDEXTENSION_VARIANT_TYPE_NIL
EndProcedure

Procedure.l GDEX_TypeMeta(vtype.l)
  Select vtype
    Case #GDEXTENSION_VARIANT_TYPE_FLOAT : ProcedureReturn #GDEXTENSION_METHOD_ARGUMENT_METADATA_REAL_IS_DOUBLE
    Case #GDEXTENSION_VARIANT_TYPE_INT   : ProcedureReturn #GDEXTENSION_METHOD_ARGUMENT_METADATA_INT_IS_INT32
  EndSelect
  ProcedureReturn #GDEXTENSION_METHOD_ARGUMENT_METADATA_NONE
EndProcedure

Procedure GDEX_ArgBuiltin(*args, vtype.l, *out)
  Protected *var = PeekI(*args)
  GDEX_UnwrapVariant(*out, vtype, *var)
EndProcedure

ProcedureC GDEX_MethodCall(*method_userdata, *instance, *args, arg_count.q, *r_ret, *r_error)
  Protected *m.GDMethodEntry = *method_userdata
  Select *m\shape
    Case #GDEX_SHAPE_VOID_0
      Protected f0.GDEXVoid0 = *m\func
      f0(*instance)
      g_variant_new_nil(*r_ret)
    Case #GDEX_SHAPE_VOID_1F
      Protected f1.GDEXVoid1F = *m\func
      f1(*instance, GDEX_ArgDouble(*args, 0))
      g_variant_new_nil(*r_ret)
    Case #GDEX_SHAPE_VOID_1I
      Protected *var = PeekI(*args)
      Protected iv.l
      g_to_int(@iv, *var)
      Protected f4.GDEXVoid1I = *m\func
      f4(*instance, iv)
      g_variant_new_nil(*r_ret)
    Case #GDEX_SHAPE_F64_0
      Protected f2.GDEXF64_0 = *m\func
      Protected r2.d = f2(*instance)
      g_from_float(*r_ret, @r2)
    Case #GDEX_SHAPE_I64_0
      Protected f5.GDEXI64_0 = *m\func
      Protected r5.i = f5(*instance)
      g_from_int(*r_ret, @r5)
    Case #GDEX_SHAPE_BUILTIN_RET
      ; Hand the user a zeroed buffer, then wrap whatever they wrote.
      Protected *rb = AllocateMemory(*m\ret_size)
      If *rb
        FillMemory(*rb, *m\ret_size, 0)
        Protected f6.GDEXBuiltinOut = *m\func
        f6(*instance, *rb)
        GDEX_WrapVariant(*r_ret, *m\ret_type, *rb)
        FreeMemory(*rb)
      Else
        g_variant_new_nil(*r_ret)
      EndIf
    Case #GDEX_SHAPE_BUILTIN_ARG
      Protected *ab = AllocateMemory(*m\arg_size)
      If *ab
        GDEX_ArgBuiltin(*args, *m\arg_type, *ab)
        Protected f7.GDEXBuiltinIn = *m\func
        f7(*instance, *ab)
        FreeMemory(*ab)
      EndIf
      g_variant_new_nil(*r_ret)
    Case #GDEX_SHAPE_BUILTIN_ARG_RET
      Protected *ain = AllocateMemory(*m\arg_size)
      Protected *aout = AllocateMemory(*m\ret_size)
      If *ain And *aout
        GDEX_ArgBuiltin(*args, *m\arg_type, *ain)
        FillMemory(*aout, *m\ret_size, 0)
        Protected f8.GDEXBuiltinInOut = *m\func
        f8(*instance, *ain, *aout)
        GDEX_WrapVariant(*r_ret, *m\ret_type, *aout)
      Else
        g_variant_new_nil(*r_ret)
      EndIf
      If *ain
        FreeMemory(*ain)
      EndIf
      If *aout
        FreeMemory(*aout)
      EndIf
  EndSelect
EndProcedure

ProcedureC GDEX_MethodPtrCall(*method_userdata, *instance, *args, *r_ret)
  Protected *m.GDMethodEntry = *method_userdata
  Select *m\shape
    Case #GDEX_SHAPE_VOID_0
      Protected f0.GDEXVoid0 = *m\func
      f0(*instance)
    Case #GDEX_SHAPE_VOID_1F
      Protected f1.GDEXVoid1F = *m\func
      f1(*instance, PeekD(PeekI(*args)))
    Case #GDEX_SHAPE_VOID_1I
      Protected f4.GDEXVoid1I = *m\func
      f4(*instance, PeekL(PeekI(*args)))
    Case #GDEX_SHAPE_F64_0
      Protected f2.GDEXF64_0 = *m\func
      Protected r2.d = f2(*instance)
      If *r_ret
        PokeD(*r_ret, r2)
      EndIf
    Case #GDEX_SHAPE_I64_0
      Protected f5.GDEXI64_0 = *m\func
      Protected r5.i = f5(*instance)
      If *r_ret
        PokeI(*r_ret, r5)
      EndIf
    Case #GDEX_SHAPE_BUILTIN_RET
      ; Godot already allocated the native return slot; use it directly.
      Protected f6.GDEXBuiltinOut = *m\func
      f6(*instance, *r_ret)
    Case #GDEX_SHAPE_BUILTIN_ARG
      ; args[0] is a pointer to the native value, not a Variant.
      Protected f7.GDEXBuiltinIn = *m\func
      f7(*instance, PeekI(*args))
    Case #GDEX_SHAPE_BUILTIN_ARG_RET
      Protected f8.GDEXBuiltinInOut = *m\func
      f8(*instance, PeekI(*args), *r_ret)
  EndSelect
EndProcedure

; ===========================================================================
; WHAT A bind_func DECLARES
; ===========================================================================

Procedure GDEX_AddMethodEntry(method_name.s, func.i, shape.l, arg_meta.l)
  Protected *ci.GDClassInfo = gdex_current
  If Not *ci
    ProcedureReturn
  EndIf
  Protected i = *ci\method_count
  If i >= #GDEX_MAX_METHODS
    GDEX_Fail("[gdex] too many methods on one class; raise #GDEX_MAX_METHODS")
    ProcedureReturn
  EndIf
  GDEX_SNFrom(*ci\methods[i]\name, method_name)
  *ci\methods[i]\func = func
  *ci\methods[i]\shape = shape
  *ci\methods[i]\arg_meta = arg_meta
  *ci\method_count = i + 1
EndProcedure

; The generic builtin form. arity: 0 = return only, 1 = argument only,
; 2 = argument and return. Sizes come from gdex_types.pbi.
Procedure GDEX_AddBuiltinMethod(method_name.s, func.i, arity.l, arg_type.l, arg_size.l, ret_type.l, ret_size.l)
  Protected *ci.GDClassInfo = gdex_current
  If Not *ci
    ProcedureReturn
  EndIf
  Protected before.l = *ci\method_count

  Select arity
    Case 0 : GDEX_AddMethodEntry(method_name, func, #GDEX_SHAPE_BUILTIN_RET, 0)
    Case 1 : GDEX_AddMethodEntry(method_name, func, #GDEX_SHAPE_BUILTIN_ARG, 0)
    Default: GDEX_AddMethodEntry(method_name, func, #GDEX_SHAPE_BUILTIN_ARG_RET, 0)
  EndSelect

  ; Only fill in the type/size if the entry was really appended. Without this
  ; check a full table silently rewrites the PREVIOUS method's signature -
  ; which is exactly how "frame() returns Transform2D" once became "Rect2".
  If *ci\method_count <> before + 1
    ProcedureReturn
  EndIf

  Protected i = before
  *ci\methods[i]\arg_type = arg_type
  *ci\methods[i]\arg_size = arg_size
  *ci\methods[i]\ret_type = ret_type
  *ci\methods[i]\ret_size = ret_size
EndProcedure

Procedure GDEX_AddProp(prop_name.s, ptype.l, psize.l, getter.i, setter.i)
  Protected *ci.GDClassInfo = gdex_current
  If Not *ci
    ProcedureReturn
  EndIf
  Protected i = *ci\prop_count
  If i >= #GDEX_MAX_PROPS
    GDEX_Fail("[gdex] too many properties on one class; raise #GDEX_MAX_PROPS")
    ProcedureReturn
  EndIf

  ; The property itself, plus the pair of methods Godot resolves it through.
  Protected getter_name.s = "get_" + prop_name
  Protected setter_name.s = "set_" + prop_name

  GDEX_SNFrom(*ci\props[i]\name, prop_name)
  GDEX_SNFrom(*ci\props[i]\getter_sn, getter_name)
  GDEX_SNFrom(*ci\props[i]\setter_sn, setter_name)
  *ci\props[i]\ptype = ptype
  *ci\props[i]\psize = psize
  *ci\props[i]\getter = getter
  *ci\props[i]\setter = setter
  *ci\prop_count = i + 1

  If ptype = #GDEXTENSION_VARIANT_TYPE_FLOAT
    GDEX_AddMethodEntry(getter_name, getter, #GDEX_SHAPE_F64_0, 0)
    GDEX_AddMethodEntry(setter_name, setter, #GDEX_SHAPE_VOID_1F, #GDEXTENSION_METHOD_ARGUMENT_METADATA_REAL_IS_DOUBLE)
  ElseIf ptype = #GDEXTENSION_VARIANT_TYPE_INT
    GDEX_AddMethodEntry(getter_name, getter, #GDEX_SHAPE_I64_0, 0)
    GDEX_AddMethodEntry(setter_name, setter, #GDEX_SHAPE_VOID_1I, #GDEXTENSION_METHOD_ARGUMENT_METADATA_INT_IS_INT32)
  Else
    ; Any other builtin goes through the generic pair.
    GDEX_AddBuiltinMethod(getter_name, getter, 0, 0, 0, ptype, psize)
    GDEX_AddBuiltinMethod(setter_name, setter, 1, ptype, psize, 0, 0)
  EndIf
EndProcedure

; ===========================================================================
; REGISTRATION
; ===========================================================================

Procedure GDEX_RegisterMethod(*ci.GDClassInfo, i.l)
  Protected *m.GDMethodEntry = @*ci\methods[i]
  Protected info.GDExtensionClassMethodInfo
  Protected retinfo.GDExtensionPropertyInfo
  Protected arginfo.GDExtensionPropertyInfo
  Protected argmeta.l

  info\name = @*m\name
  info\method_userdata = *m
  info\call_func = @GDEX_MethodCall()
  info\ptrcall_func = @GDEX_MethodPtrCall()
  info\method_flags = #GDEXTENSION_METHOD_FLAG_NORMAL
  info\has_return_value = #False
  info\return_value_info = #Null
  info\return_value_metadata = #GDEXTENSION_METHOD_ARGUMENT_METADATA_NONE
  info\argument_count = 0
  info\arguments_info = #Null
  info\arguments_metadata = #Null
  info\default_argument_count = 0
  info\default_arguments = #Null

  ; Everything below is derived from the shape, so a new shape only has to be
  ; added to GDEX_ShapeArgType / GDEX_ShapeRetType and the two dispatchers.
  Protected atype.l = GDEX_MethodArgType(*m)
  If atype <> #GDEXTENSION_VARIANT_TYPE_NIL
    arginfo\type = atype
    arginfo\name = @gdex_empty_sn
    arginfo\class_name = @gdex_empty_sn
    arginfo\hint = 0
    arginfo\hint_string = @gdex_empty_string
    arginfo\usage = #PROPERTY_USAGE_DEFAULT
    argmeta = GDEX_TypeMeta(atype)
    info\argument_count = 1
    info\arguments_info = @arginfo
    info\arguments_metadata = @argmeta
  EndIf

  Protected rtype.l = GDEX_MethodRetType(*m)
  If rtype <> #GDEXTENSION_VARIANT_TYPE_NIL
    retinfo\type = rtype
    retinfo\name = @gdex_empty_sn
    retinfo\class_name = @gdex_empty_sn
    retinfo\hint = 0
    retinfo\hint_string = @gdex_empty_string
    retinfo\usage = #PROPERTY_USAGE_DEFAULT
    info\has_return_value = #True
    info\return_value_info = @retinfo
    info\return_value_metadata = GDEX_TypeMeta(rtype)
  EndIf

  g_classdb_register_method(GDExtensionClassLibraryPtr, @*ci\class_name, @info)
EndProcedure

Procedure GDEX_RegisterProperty(*ci.GDClassInfo, i.l)
  Protected info.GDExtensionPropertyInfo
  info\type = *ci\props[i]\ptype
  info\name = @*ci\props[i]\name
  info\class_name = @gdex_empty_sn
  info\hint = 0
  info\hint_string = @gdex_empty_string
  info\usage = #PROPERTY_USAGE_DEFAULT
  g_classdb_register_property(GDExtensionClassLibraryPtr, @*ci\class_name, @info, @*ci\props[i]\setter_sn, @*ci\props[i]\getter_sn)
EndProcedure

; The one entry point a user class needs.
Procedure RegisterGDClass(*ci.GDClassInfo, gd_name.s, gd_parent.s)
  If Not *ci Or Not g_classdb_register_class6
    ProcedureReturn
  EndIf

  ; A class can only be registered once the parent it names exists in ClassDB.
  ; Object is there from CORE; everything else - Node, Node2D, Sprite2D, ... -
  ; only from SCENE. Rather than make every extension split its registration
  ; across levels by hand and get it right, whatever is not ready is queued
  ; here and registered when the level arrives. See GDEX_Initialize.
  If gd_parent <> "Object" And gdex_level < #GDEXTENSION_INITIALIZATION_SCENE
    If gdex_pending_class_count >= #GDEX_MAX_CLASSES
      GDEX_Fail("[gdex] too many classes; raise #GDEX_MAX_CLASSES")
      ProcedureReturn
    EndIf
    gdex_pending_ci(gdex_pending_class_count) = *ci
    gdex_pending_name(gdex_pending_class_count) = gd_name
    gdex_pending_parent(gdex_pending_class_count) = gd_parent
    gdex_pending_class_count = gdex_pending_class_count + 1
    ProcedureReturn
  EndIf

  GDEX_Trace("[gdex] RegisterGDClass " + gd_name + " : " + gd_parent)
  If gdex_class_count >= #GDEX_MAX_CLASSES
    GDEX_Fail("[gdex] too many classes; raise #GDEX_MAX_CLASSES")
    ProcedureReturn
  EndIf

  *ci\index = gdex_class_count
  GDEX_SNFrom(*ci\class_name, gd_name)
  GDEX_SNFrom(*ci\parent_name, gd_parent)
  *ci\is_node = Bool(gd_parent <> "Object")

  ; Let the class declare its properties and methods.
  gdex_current = *ci
  If *ci\bind_func
    Protected bf.GDEXBind = *ci\bind_func
    bf()
  EndIf
  gdex_current = 0

  ; The descriptor shared by every callback.
  Protected info.GDExtensionClassCreationInfo6
  info\is_virtual = #False
  info\is_abstract = #False
  info\is_exposed = #True
  info\is_runtime = #False
  info\icon_path = #Null
  info\set_func = @GDEX_Set()
  info\get_func = @GDEX_Get()
  info\get_property_list_func = #Null
  info\free_property_list_func = #Null
  info\property_can_revert_func = #Null
  info\property_get_revert_func = #Null
  info\validate_property_func = #Null
  info\notification_func = @GDEX_Notification()
  info\to_string_func = @GDEX_ToString()
  info\reference_func = #Null
  info\unreference_func = #Null
  info\create_instance_func = @GDEX_CreateInstance()
  info\free_instance_func = @GDEX_FreeInstance()
  info\recreate_instance_func = #Null
  info\get_virtual_func = #Null
  info\get_virtual_call_data_func = @GDEX_GetVirtualCallData()
  info\call_virtual_with_data_func = @GDEX_CallVirtualWithData()
  info\class_userdata = *ci

  GDEX_Trace("[gdex]   class6(" + gd_name + ")")
  g_classdb_register_class6(GDExtensionClassLibraryPtr, @*ci\class_name, @*ci\parent_name, @info)
  GDEX_Trace("[gdex]   class6 ok")

  ; Signal, then the methods (so the property's setter/getter names resolve),
  ; then the properties.
  ; Every signal the class declared in bind_func with ADD_SIGNAL(MethodInfo(...)).
  Protected si.l, ai.l, *sig.GDSignalEntry
  For si = 0 To *ci\signal_count - 1
    *sig = @*ci\signals[si]
    If *sig\arg_count <= 0
      g_classdb_register_signal(GDExtensionClassLibraryPtr, @*ci\class_name, @*sig\name, #Null, 0)
    Else
      Protected Dim arginfo.GDExtensionPropertyInfo(*sig\arg_count - 1)
      For ai = 0 To *sig\arg_count - 1
        arginfo(ai)\type = *sig\args[ai]\vtype
        arginfo(ai)\name = @*sig\args[ai]\name
        arginfo(ai)\class_name = @gdex_empty_sn
        arginfo(ai)\hint = 0
        arginfo(ai)\hint_string = @gdex_empty_string
        arginfo(ai)\usage = #PROPERTY_USAGE_DEFAULT
      Next ai
      g_classdb_register_signal(GDExtensionClassLibraryPtr, @*ci\class_name, @*sig\name, @arginfo(0), *sig\arg_count)
    EndIf
  Next si

  Protected i
  For i = 0 To *ci\method_count - 1
    GDEX_RegisterMethod(*ci, i)
  Next
  For i = 0 To *ci\prop_count - 1
    GDEX_RegisterProperty(*ci, i)
  Next

  *ci\registered = #True
  gdex_class_level(*ci\index) = gdex_level

  gdex_classes(gdex_class_count) = *ci
  gdex_class_count + 1
  GDEX_Trace("[gdex]   done " + gd_name)
EndProcedure

; ===========================================================================
; SINGLETONS
;
; Engine.register_singleton, over an instance the framework made the same way
; create_instance_func makes one. Returns the Object* so the caller can hand
; it back to GD_UnregisterSingleton at deinit.
; ===========================================================================

Procedure.i GD_RegisterSingleton(singleton_name.s, *ci.GDClassInfo)
  GDEX_EnsureEngineBinds()
  Protected obj = GDEX_Instantiate(*ci)
  If Not obj Or Not gdex_engine_register_bind Or Not gdex_engine_obj
    ProcedureReturn obj
  EndIf
  Protected sn.GodotStringName
  GDEX_SNFrom(sn, singleton_name)
  Protected Dim args.i(2)
  args(0) = @sn
  args(1) = @obj
  g_object_method_bind_ptrcall(gdex_engine_register_bind, gdex_engine_obj, @args(0), #Null)
  ProcedureReturn obj
EndProcedure

Procedure GD_UnregisterSingleton(singleton_name.s, obj.i)
  GDEX_EnsureEngineBinds()
  If Not gdex_engine_unregister_bind Or Not gdex_engine_obj
    ProcedureReturn
  EndIf
  Protected sn.GodotStringName
  GDEX_SNFrom(sn, singleton_name)
  Protected Dim args.i(1)
  args(0) = @sn
  g_object_method_bind_ptrcall(gdex_engine_unregister_bind, gdex_engine_obj, @args(0), #Null)
EndProcedure

; Unregister every class this library registered, newest first.
;
; GDEX_Deinitialize does not use this - it unregisters level by level, via
; GDEX_UnregisterClassesAt, because Godot tears the levels down in reverse and
; a CORE class must go at CORE. This blunt version remains for an extension
; that drives the levels itself.
Procedure GDEX_UnregisterAllClasses()
  If Not g_classdb_unregister_class
    ProcedureReturn
  EndIf
  Protected i
  For i = gdex_class_count - 1 To 0 Step -1
    Protected *ci.GDClassInfo = gdex_classes(i)
    If *ci
      g_classdb_unregister_class(GDExtensionClassLibraryPtr, @*ci\class_name)
    EndIf
  Next
  gdex_class_count = 0
EndProcedure

; ===========================================================================
; WHAT A USER CLASS CALLS FROM ITS bind_func
;
; The surface is deliberately godot-cpp's, and lives in generated/helpers/:
;
;     ClassDB::bind_method(D_METHOD("set_speed", "speed"), @Foo_set_speed(), #VOID, #FLOAT)
;     ADD_PROPERTY(PropertyInfo(#FLOAT, "speed"), "set_speed", "get_speed")
;     ADD_SIGNAL(MethodInfo("bounced", PropertyInfo(#VECTOR2, "position")))
;
; Those call the three procedures directly below, which are what actually
; touch the tables. Nothing per-shape lives here any more: the shape is
; derived from the Variant types the call site passes.
; ===========================================================================

; Native size of a Variant type, for the generic builtin shape. Both the
; property path and ClassDB::bind_method need it, and both used to get it from
; a per-shape macro spelling out SizeOf(...).
Procedure.l GDEX_VariantTypeSize(vtype.l)
  Select vtype
    Case #GDEXTENSION_VARIANT_TYPE_BOOL       : ProcedureReturn 1
    Case #GDEXTENSION_VARIANT_TYPE_INT        : ProcedureReturn 8
    Case #GDEXTENSION_VARIANT_TYPE_FLOAT      : ProcedureReturn 8
    Case #VECTOR2                             : ProcedureReturn SizeOf(GDVector2)
    Case #VECTOR2I                            : ProcedureReturn SizeOf(GDVector2i)
    Case #RECT2                               : ProcedureReturn SizeOf(GDRect2)
    Case #RECT2I                              : ProcedureReturn SizeOf(GDRect2i)
    Case #VECTOR3                             : ProcedureReturn SizeOf(GDVector3)
    Case #VECTOR3I                            : ProcedureReturn SizeOf(GDVector3i)
    Case #VECTOR4                             : ProcedureReturn SizeOf(GDVector4)
    Case #COLOR                               : ProcedureReturn SizeOf(GDColor)
    Case #PLANE                               : ProcedureReturn SizeOf(GDPlane)
    Case #QUATERNION                          : ProcedureReturn SizeOf(GDQuaternion)
    Case #AABB                                : ProcedureReturn SizeOf(GDAABB)
    Case #BASIS                               : ProcedureReturn SizeOf(GDBasis)
    Case #TRANSFORM2D                         : ProcedureReturn SizeOf(GDTransform2D)
    Case #TRANSFORM3D                         : ProcedureReturn SizeOf(GDTransform3D)
    Case #PROJECTION                          : ProcedureReturn SizeOf(GDProjection)
    Case #RID                                 : ProcedureReturn SizeOf(GDRID)
  EndSelect
  ProcedureReturn 0
EndProcedure

; Index of a method already bound on the class being registered, or -1.
; ADD_PROPERTY needs it: godot-cpp's ADD_PROPERTY names its setter and getter
; as strings and resolves them against the methods _bind_methods bound first,
; and so does this.
Procedure.l GDEX_FindMethod(method_name.s)
  Protected *ci.GDClassInfo = gdex_current
  If Not *ci
    ProcedureReturn -1
  EndIf
  Protected want.GodotStringName
  GDEX_SNFrom(want, method_name)
  Protected i
  For i = 0 To *ci\method_count - 1
    If GDEX_StringNameEq(@want, @*ci\methods[i]\name)
      ProcedureReturn i
    EndIf
  Next i
  ProcedureReturn -1
EndProcedure

; The ADD_PROPERTY path: the accessors are already bound, so look them up by
; name and only append the property itself. GDEX_AddProp above is the other
; path, where the property creates its own get_/set_ methods.
Procedure GDEX_AddProperty(prop_name.s, ptype.l, setter_name.s, getter_name.s)
  Protected *ci.GDClassInfo = gdex_current
  If Not *ci
    ProcedureReturn
  EndIf
  Protected si = GDEX_FindMethod(setter_name)
  Protected gi = GDEX_FindMethod(getter_name)
  If si < 0
    GDEX_Fail("[gdex] ADD_PROPERTY " + prop_name + ": no method named " + setter_name + " - bind it first")
    ProcedureReturn
  EndIf
  If gi < 0
    GDEX_Fail("[gdex] ADD_PROPERTY " + prop_name + ": no method named " + getter_name + " - bind it first")
    ProcedureReturn
  EndIf
  Protected i = *ci\prop_count
  If i >= #GDEX_MAX_PROPS
    GDEX_Fail("[gdex] too many properties on one class; raise #GDEX_MAX_PROPS")
    ProcedureReturn
  EndIf

  GDEX_SNFrom(*ci\props[i]\name, prop_name)
  GDEX_SNFrom(*ci\props[i]\setter_sn, setter_name)
  GDEX_SNFrom(*ci\props[i]\getter_sn, getter_name)
  *ci\props[i]\ptype = ptype
  *ci\props[i]\psize = GDEX_VariantTypeSize(ptype)
  *ci\props[i]\setter = *ci\methods[si]\func
  *ci\props[i]\getter = *ci\methods[gi]\func
  *ci\prop_count = i + 1
EndProcedure

; ===========================================================================
; THE IMPLEMENTATIONS BEHIND ClassDB::
;
; generated/helpers/gdex_classdb.pbi spells these ClassDB::bind_method,
; ClassDB::add_property and ClassDB::add_signal. It has to be a module to get
; the :: spelling, and a PureBasic module can see global VARIABLES and
; CONSTANTS but not structures or procedures - so the module cannot touch a
; GDClassInfo itself, nor call anything here.
;
; The bridge is a prototype-typed global: the implementations live out here
; where structures are visible, and the module calls them through a function
; pointer it can read as a global and cast to a module-local Prototype. One
; indirect call, and the C++ spelling stays.
; ===========================================================================

; ClassDB::bind_method - pick the dispatch shape from the Variant types.
Procedure GDEX_BindMethodImpl(Name.s, A1.s, A2.s, A3.s, Proc.i, RetType.l, Arg0.l, Arg1.l)
  Protected *ci.GDClassInfo = gdex_current
  If Not *ci
    ProcedureReturn
  EndIf
  If Not Proc
    GDEX_Fail("[gdex] bind_method " + Name + ": no procedure given")
    ProcedureReturn
  EndIf
  If Arg1 <> #GDEX_NO_TYPE
    GDEX_Fail("[gdex] bind_method " + Name + ": a method takes at most one argument")
    ProcedureReturn
  EndIf

  Protected argc.l = 0
  If Arg0 <> #GDEX_NO_TYPE
    argc = 1
  EndIf

  ; A type the framework cannot marshal has size 0; say so rather than
  ; registering a method that would read nothing.
  If argc = 1 And GDEX_VariantTypeSize(Arg0) = 0
    GDEX_Fail("[gdex] bind_method " + Name + ": argument type is not a value type")
    ProcedureReturn
  EndIf
  If RetType <> #VOID And GDEX_VariantTypeSize(RetType) = 0
    GDEX_Fail("[gdex] bind_method " + Name + ": return type is not a value type")
    ProcedureReturn
  EndIf

  If argc = 0
    ; The three shapes worth special-casing: they avoid a Variant round trip.
    If RetType = #VOID
      GDEX_AddMethodEntry(Name, Proc, #GDEX_SHAPE_VOID_0, 0)
    ElseIf RetType = #FLOAT
      GDEX_AddMethodEntry(Name, Proc, #GDEX_SHAPE_F64_0, 0)
    ElseIf RetType = #INT
      GDEX_AddMethodEntry(Name, Proc, #GDEX_SHAPE_I64_0, 0)
    Else
      GDEX_AddBuiltinMethod(Name, Proc, 0, 0, 0, RetType, GDEX_VariantTypeSize(RetType))
    EndIf
  Else
    If Arg0 = #FLOAT And RetType = #VOID
      GDEX_AddMethodEntry(Name, Proc, #GDEX_SHAPE_VOID_1F, #GDEXTENSION_METHOD_ARGUMENT_METADATA_REAL_IS_DOUBLE)
    ElseIf Arg0 = #INT And RetType = #VOID
      GDEX_AddMethodEntry(Name, Proc, #GDEX_SHAPE_VOID_1I, 0)
    ElseIf RetType = #VOID
      GDEX_AddBuiltinMethod(Name, Proc, 1, Arg0, GDEX_VariantTypeSize(Arg0), 0, 0)
    Else
      GDEX_AddBuiltinMethod(Name, Proc, 2, Arg0, GDEX_VariantTypeSize(Arg0), RetType, GDEX_VariantTypeSize(RetType))
    EndIf
  EndIf
EndProcedure

; ClassDB::add_property - the accessors are named and must already be bound.
Procedure GDEX_AddPropertyImpl(PropType.l, PropName.s, SetterName.s, GetterName.s)
  If PropType <> #VOID And GDEX_VariantTypeSize(PropType) = 0
    GDEX_Fail("[gdex] ADD_PROPERTY " + PropName + ": not a value type")
    ProcedureReturn
  EndIf
  GDEX_AddProperty(PropName, PropType, SetterName, GetterName)
EndProcedure

; ClassDB::add_signal - up to four typed arguments, an argument counting as
; supplied when its name is non-empty.
Procedure GDEX_AddSignalImpl(SigName.s, T0.l, N0.s, T1.l, N1.s, T2.l, N2.s, T3.l, N3.s)
  Protected *ci.GDClassInfo = gdex_current
  If Not *ci
    ProcedureReturn
  EndIf
  If SigName = ""
    GDEX_Fail("[gdex] ADD_SIGNAL: empty signal name")
    ProcedureReturn
  EndIf
  If *ci\signal_count >= #GDEX_MAX_SIGNALS
    GDEX_Fail("[gdex] too many signals on one class; raise #GDEX_MAX_SIGNALS")
    ProcedureReturn
  EndIf

  Protected i = *ci\signal_count
  GDEX_SNFrom(*ci\signals[i]\name, SigName)
  *ci\signals[i]\arg_count = 0

  Protected Dim atype.l(3)
  Protected Dim aname.s(3)
  atype(0) = T0 : aname(0) = N0
  atype(1) = T1 : aname(1) = N1
  atype(2) = T2 : aname(2) = N2
  atype(3) = T3 : aname(3) = N3

  Protected j
  For j = 0 To 3
    If aname(j) <> ""
      If atype(j) = #VOID Or GDEX_VariantTypeSize(atype(j)) = 0
        GDEX_Fail("[gdex] ADD_SIGNAL " + SigName + ": argument " + aname(j) + " is not a value type")
        ProcedureReturn
      EndIf
      Protected k = *ci\signals[i]\arg_count
      GDEX_SNFrom(*ci\signals[i]\args[k]\name, aname(j))
      *ci\signals[i]\args[k]\vtype = atype(j)
      *ci\signals[i]\args[k]\vtype_size = GDEX_VariantTypeSize(atype(j))
      *ci\signals[i]\arg_count = k + 1
    EndIf
  Next j

  *ci\signal_count = i + 1
EndProcedure

; The prototypes use only scalar and string types, because the module that
; calls through them can see neither structures nor the types out here.
Prototype GDEXBindMethodFn(Name.s, A1.s, A2.s, A3.s, Proc.i, RetType.l, Arg0.l, Arg1.l)
Prototype GDEXAddPropertyFn(PropType.l, PropName.s, SetterName.s, GetterName.s)
Prototype GDEXAddSignalFn(SigName.s, T0.l, N0.s, T1.l, N1.s, T2.l, N2.s, T3.l, N3.s)

Global gdex_bind_method.GDEXBindMethodFn = @GDEX_BindMethodImpl()
Global gdex_add_property.GDEXAddPropertyFn = @GDEX_AddPropertyImpl()
Global gdex_add_signal.GDEXAddSignalFn = @GDEX_AddSignalImpl()

; ===========================================================================
; THE INITIALIZATION LADDER, OWNED BY THE FRAMEWORK
;
; Godot calls the extension once per level, lowest first, and a class can only
; be registered once the parent it names exists - Object from CORE, Node and
; everything under it from SCENE. That split used to be the extension author's
; problem: an initialize callback with an If per level and a RegisterGDClass
; call placed in whichever branch was correct.
;
; Instead the extension lists its classes once, in GDEX_RegisterClasses(), and this
; registers each at the level it needs. GDEX_EXTENSION() points Godot at these
; two procedures, so the callback itself disappears too.
; ===========================================================================

; The extension supplies these two. GDEX_RegisterClasses runs once, at the
; lowest level; GDEX_ResolveBinds runs once, when SCENE arrives. They are
; separate because resolving a MethodBind for a scene class at CORE returns
; null (Godot: `Parameter "mb" is null`), which is exactly the trap the old
; hand-written level ladder existed to avoid.
Declare GDEX_RegisterClasses()
Declare GDEX_ResolveBinds()

Procedure GDEX_RegisterSingleton(*ci.GDClassInfo, singleton_name.s)
  If Not *ci
    ProcedureReturn 0
  EndIf

  ; The class may not be registered yet - a Node-derived singleton is still
  ; queued at CORE - so defer the singleton too and let the flush order it
  ; after the class it needs.
  If Not *ci\registered
    If gdex_pending_singleton_count < #GDEX_MAX_SINGLETONS
      gdex_pending_singleton_ci(gdex_pending_singleton_count) = *ci
      gdex_pending_singleton_name(gdex_pending_singleton_count) = singleton_name
      gdex_pending_singleton_count = gdex_pending_singleton_count + 1
    Else
      GDEX_Fail("[gdex] too many singletons; raise #GDEX_MAX_SINGLETONS")
    EndIf
    ProcedureReturn 0
  EndIf

  Protected obj.i = GD_RegisterSingleton(singleton_name, *ci)
  If obj And gdex_singleton_count < #GDEX_MAX_SINGLETONS
    gdex_singleton_name(gdex_singleton_count) = singleton_name
    gdex_singleton_obj(gdex_singleton_count) = obj
    gdex_singleton_level(gdex_singleton_count) = gdex_level
    gdex_singleton_count = gdex_singleton_count + 1
  EndIf
  ProcedureReturn obj
EndProcedure

; GDREGISTER_SINGLETON ends up here. A singleton is an instance of a class, so
; the class is registered first and the instance straight after - in that
; order, because GDEX_RegisterSingleton instantiates the class, and Godot
; cannot instantiate a class that is not in ClassDB yet. A 4th argument that is
; empty means "the singleton is named after the class", which is the usual
; case and cannot be expressed as a macro default: PureBasic macro defaults
; are literal text, so one cannot name an earlier parameter.
Procedure GDEX_RegisterSingletonClass(*ci.GDClassInfo, class_name.s, parent.s, singleton_name.s)
  If singleton_name = ""
    singleton_name = class_name
  EndIf
  RegisterGDClass(*ci, class_name, parent)
  ProcedureReturn GDEX_RegisterSingleton(*ci, singleton_name)
EndProcedure

; Register everything that was waiting, in dependency order: classes first,
; then the singletons that needed those classes.
Procedure GDEX_FlushPending()
  Protected n.l = gdex_pending_class_count
  Protected i.l
  gdex_pending_class_count = 0
  For i = 0 To n - 1
    RegisterGDClass(gdex_pending_ci(i), gdex_pending_name(i), gdex_pending_parent(i))
  Next i

  Protected m.l = gdex_pending_singleton_count
  gdex_pending_singleton_count = 0
  For i = 0 To m - 1
    GDEX_RegisterSingleton(gdex_pending_singleton_ci(i), gdex_pending_singleton_name(i))
  Next i
EndProcedure

Procedure GDEX_UnregisterSingletonsAt(level.l)
  Protected i.l, j.l
  For i = gdex_singleton_count - 1 To 0 Step -1
    If gdex_singleton_level(i) = level
      GD_UnregisterSingleton(gdex_singleton_name(i), gdex_singleton_obj(i))
      For j = i To gdex_singleton_count - 2
        gdex_singleton_name(j) = gdex_singleton_name(j + 1)
        gdex_singleton_obj(j) = gdex_singleton_obj(j + 1)
        gdex_singleton_level(j) = gdex_singleton_level(j + 1)
      Next j
      gdex_singleton_count = gdex_singleton_count - 1
    EndIf
  Next i
EndProcedure

; Only the classes this level registered. Godot tears the levels down in
; reverse, so a CORE class goes at CORE and a SCENE class at SCENE.
Procedure GDEX_UnregisterClassesAt(level.l)
  Protected i.l
  For i = gdex_class_count - 1 To 0 Step -1
    If gdex_class_level(i) = level And gdex_classes(i)
      Protected *ci.GDClassInfo = gdex_classes(i)
      If g_classdb_unregister_class
        g_classdb_unregister_class(GDExtensionClassLibraryPtr, @*ci\class_name)
      EndIf
      *ci\registered = #False
      gdex_classes(i) = 0
    EndIf
  Next i
EndProcedure

Procedure GDEX_Initialize(*p_userdata, p_level)
  gdex_level = p_level

  ; The Engine singleton is the framework's own dependency, so it resolves it
  ; rather than asking every extension to remember.
  If p_level = #GDEXTENSION_INITIALIZATION_CORE
    GDEX_EnsureEngineBinds()
  EndIf

  If Not gdex_declared
    gdex_declared = #True
    GDEX_RegisterClasses()
  EndIf

  ; A scene class's MethodBind does not exist until SCENE, so the extension's
  ; bind resolution waits for it.
  If p_level = #GDEXTENSION_INITIALIZATION_SCENE And Not gdex_binds_resolved
    gdex_binds_resolved = #True
    GDEX_ResolveBinds()
  EndIf

  GDEX_FlushPending()
EndProcedure

Procedure GDEX_Deinitialize(*p_userdata, p_level)
  GDEX_UnregisterSingletonsAt(p_level)
  GDEX_UnregisterClassesAt(p_level)
EndProcedure
