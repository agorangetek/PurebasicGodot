; ===========================================================================
; gdex_api.pbi - everything the framework needs to talk to Godot.
;
;   * gdextension_interface.pbi is the recovered PureBasic transcription of
;     Godot's GDExtensionInterface: every Prototype and every C struct.
;   * below it are the few declarations that transcription was missing, the
;     typed globals holding the resolved function pointers, and load_api().
;
; Nothing here is registered with Godot yet; gdex_class.pbi does that.
; ===========================================================================

IncludeFile "gdextension_interface.pbi"

; ---------------------------------------------------------------------------
; DECLARATIONS THE RECOVERED TRANSCRIPTION WAS MISSING
;
; GDExtensionClassCreationInfo6 is what `classdb_register_extension_class6`
; takes on Godot 4.5+. It is field-for-field GDExtensionClassCreationInfo4
; (declared above) but with the newer callback typedefs, which are ABI
; identical - so the layout is the same 22 fields.
; ---------------------------------------------------------------------------
Structure GDExtensionClassCreationInfo6 Align #PB_Structure_AlignC
  is_virtual.b
  is_abstract.b
  is_exposed.b
  is_runtime.b
  *icon_path
  *set_func
  *get_func
  *get_property_list_func
  *free_property_list_func
  *property_can_revert_func
  *property_get_revert_func
  *validate_property_func
  *notification_func
  *to_string_func
  *reference_func
  *unreference_func
  *create_instance_func
  *free_instance_func
  *recreate_instance_func
  *get_virtual_func
  *get_virtual_call_data_func
  *call_virtual_with_data_func
  *class_userdata
EndStructure

PrototypeC.i GDExtensionInterfaceClassdbConstructObject3(classname)
PrototypeC GDExtensionInterfaceClassdbRegisterExtensionClass6(library, class_name, parent_class_name, extension_funcs)

; ---------------------------------------------------------------------------
; RESOLVED FUNCTION POINTERS
;
; A Prototype in PureBasic is a type; a call only happens through a variable
; of that type. These globals are those variables. An untyped Prototype
; returns a 64-bit value, which is why the pointer-returning ones below can
; be assigned straight to `.i`.
; ---------------------------------------------------------------------------
Global g_get_godot_version2.GDExtensionInterfaceGetGodotVersion2
Global g_mem_alloc2.GDExtensionInterfaceMemAlloc2
Global g_mem_free2.GDExtensionInterfaceMemFree2
Global g_print_error.GDExtensionInterfacePrintError
Global g_print_warning.GDExtensionInterfacePrintWarning

Global g_variant_new_nil.GDExtensionInterfaceVariantNewNil
Global g_variant_destroy.GDExtensionInterfaceVariantDestroy
Global g_variant_get_type.GDExtensionInterfaceVariantGetType
Global g_get_variant_from_type.GDExtensionInterfaceGetVariantFromTypeConstructor
Global g_get_variant_to_type.GDExtensionInterfaceGetVariantToTypeConstructor
Global g_get_operator_evaluator.GDExtensionInterfaceVariantGetPtrOperatorEvaluator

; Cached Variant<->native constructors, resolved in load_api.
Global g_from_float.GDExtensionVariantFromTypeConstructorFunc
Global g_to_float.GDExtensionTypeFromVariantConstructorFunc
Global g_from_vector2.GDExtensionVariantFromTypeConstructorFunc
Global g_to_vector2.GDExtensionTypeFromVariantConstructorFunc
Global g_from_string_name.GDExtensionVariantFromTypeConstructorFunc
Global g_from_int.GDExtensionVariantFromTypeConstructorFunc
Global g_to_int.GDExtensionTypeFromVariantConstructorFunc

Global g_string_name_new.GDExtensionInterfaceStringNameNewWithUtf8Chars
Global g_variant_get_ptr_destructor.GDExtensionInterfaceVariantGetPtrDestructor
Global g_variant_get_ptr_builtin_method.GDExtensionInterfaceVariantGetPtrBuiltinMethod
Global g_variant_get_ptr_utility_function.GDExtensionInterfaceVariantGetPtrUtilityFunction
Global g_string_new.GDExtensionInterfaceStringNewWithUtf8Chars
Global g_string_to_utf8.GDExtensionInterfaceStringToUtf8Chars

Global g_object_method_bind_call.GDExtensionInterfaceObjectMethodBindCall
Global g_object_method_bind_ptrcall.GDExtensionInterfaceObjectMethodBindPtrcall
; The SAME address as an Integer. A generated class module calls the ptrcall
; through this: a module cannot see a Prototype-typed global (its type is not
; visible inside the module), but it can read an Integer and cast it to a
; Prototype it declares for itself. See tools/gen_binds.pb.
Global g_ptr_object_method_bind_ptrcall.i = 0
Global g_object_set_instance.GDExtensionInterfaceObjectSetInstance
Global g_object_set_instance_binding.GDExtensionInterfaceObjectSetInstanceBinding
Global g_object_destroy.GDExtensionInterfaceObjectDestroy
Global g_global_get_singleton.GDExtensionInterfaceGlobalGetSingleton

Global g_classdb_construct_object3.GDExtensionInterfaceClassdbConstructObject3
Global g_classdb_get_method_bind.GDExtensionInterfaceClassdbGetMethodBind
Global g_classdb_register_class6.GDExtensionInterfaceClassdbRegisterExtensionClass6
Global g_classdb_register_method.GDExtensionInterfaceClassdbRegisterExtensionClassMethod
Global g_classdb_register_property.GDExtensionInterfaceClassdbRegisterExtensionClassProperty
Global g_classdb_register_signal.GDExtensionInterfaceClassdbRegisterExtensionClassSignal
Global g_classdb_unregister_class.GDExtensionInterfaceClassdbUnregisterExtensionClass

; The three callbacks object_set_instance_binding() wants. They mirror what
; godot-cpp installs for engine classes: no binding object, nothing to free,
; and a reference callback that just says "handled".
ProcedureC GDEX_BindingCreate(*token, *instance)
  ProcedureReturn 0
EndProcedure

ProcedureC GDEX_BindingFree(*token, *instance, *binding)
EndProcedure

ProcedureC.a GDEX_BindingReference(*token, *instance, reference.a)
  ProcedureReturn #True
EndProcedure

Global gdex_binding_callbacks.GDExtensionInstanceBindingCallbacks

; ---------------------------------------------------------------------------
; Small helpers over the raw interface.
; ---------------------------------------------------------------------------

; Always reported, unlike GDEX_Trace. Also usable from a class's own methods
; to print into Godot's log - the only output channel a dylib has.
Procedure GDEX_Report(msg.s)
  If g_print_error
    Protected fn.s = "gdex"
    Protected fl.s = "gdex.pb"
    g_print_error(UTF8(msg), UTF8(fn), UTF8(fl), 0, #False)
  EndIf
EndProcedure

Procedure GDEX_Fail(msg.s)
  GDEX_Report(msg)
EndProcedure

Procedure GDEX_Trace(msg.s)
  If gdex_trace And g_print_error
    Protected fn.s = "gdex"
    Protected fl.s = "gdex.pb"
    g_print_error(UTF8(msg), UTF8(fn), UTF8(fl), 0, #False)
  EndIf
EndProcedure

; ===========================================================================
; UNRESOLVED-BIND REPORTING
;
; A generated wrapper cannot resolve its own engine bind - Register_<Class>_Binds()
; does that, from main code - so a wrapper whose bind was never resolved used to
; return silently: a call that did nothing and said nothing. This is what it
; calls instead when that happens.
;
; It lives here, in gdex_api.pbi, for a reason: the generated class files are
; included AFTER this file, and each of them takes this procedure's address at
; top level, which is the only place that runs without anyone having to call
; anything. That is what makes the report survive the very mistake it reports -
; forgetting Register_<Class>_Binds() means the injection inside it never ran.
;
; Reported once per class::method, because a wrapper can sit in _process and
; would otherwise print a line every frame.
; ===========================================================================

#GDEX_MAX_REPORTS = 64

Global gdex_report_count.l = 0
Global Dim gdex_reported_key.s(#GDEX_MAX_REPORTS - 1)

Procedure GDEX_ReportUnresolved(class_name.s, method_name.s)
  Protected key.s = class_name + "::" + method_name
  Protected i.l
  For i = 0 To gdex_report_count - 1
    If gdex_reported_key(i) = key
      ProcedureReturn
    EndIf
  Next i
  If gdex_report_count < #GDEX_MAX_REPORTS
    gdex_reported_key(gdex_report_count) = key
    gdex_report_count = gdex_report_count + 1
  EndIf
  GDEX_Fail("[gdex] " + key + ": no method bind was resolved, so this call did nothing." + Chr(10) +
            "       Either Register_" + class_name + "_Binds() is missing from GDEX_ResolveBinds()," + Chr(10) +
            "       or this engine build has no such method - pb_gdext_wizard --check tells them apart.")
EndProcedure

; Defined below with the other StringName helpers; the resolvers under it need
; it, and PureBasic wants a procedure declared before it is called.
Declare GDEX_SNFrom(*sn.GodotStringName, text.s)

; ---- Builtin-type methods and @GlobalScope functions ----------------------
;
; Godot hands these out by type plus hash rather than through ClassDB, so there
; is no class to register and no bind to list in GDEX_ResolveBinds(). Unlike a
; scene class's MethodBind they exist at every initialization level, which is
; why they need no registration step at all - the pointer is looked up on first
; use and the callee caches it.
;
; Both take a StringName for the member name in the interface's own terms, so
; the caller passes text and this builds the StringName.

Procedure.i GDEX_BuiltinMethodBind(vtype.l, method_name.s, hash.q)
  If Not g_variant_get_ptr_builtin_method
    ProcedureReturn 0
  EndIf
  Protected sn.GodotStringName
  GDEX_SNFrom(sn, method_name)
  ProcedureReturn g_variant_get_ptr_builtin_method(vtype, @sn, hash)
EndProcedure

Procedure.i GDEX_UtilityFunctionBind(function_name.s, hash.q)
  If Not g_variant_get_ptr_utility_function
    ProcedureReturn 0
  EndIf
  ; A StringName, NOT a C string, even though the recovered transcription's
  ; parameter name (*p_function) suggests otherwise. Checked against the 4.7
  ; header, which the transcription simply does not record the type of. Passing
  ; a UTF-8 buffer here segfaults inside Godot, which dereferences it as one.
  Protected sn.GodotStringName
  GDEX_SNFrom(sn, function_name)
  ProcedureReturn g_variant_get_ptr_utility_function(@sn, hash)
EndProcedure

; ---- Godot String, from PureBasic text and back ---------------------------
;
; A native String is 8 bytes of handle onto Godot's own storage, so it cannot be
; read or written with PeekS/PokeS the way a plain builtin can. Building one is
; one call; reading one is a two-call dance, because string_to_utf8_chars
; reports the byte length without a terminator first and then fills a buffer of
; your choosing.

Procedure GDEX_StringNew(*dest, text.s)
  If *dest And g_string_new
    g_string_new(*dest, UTF8(text))
  EndIf
EndProcedure

Procedure.s GDEX_StringText(*src)
  If Not *src Or Not g_string_to_utf8
    ProcedureReturn ""
  EndIf
  Protected n.q = g_string_to_utf8(*src, 0, 0)
  If n <= 0
    ProcedureReturn ""
  EndIf
  Protected *buf = AllocateMemory(n + 1)
  If Not *buf
    ProcedureReturn ""
  EndIf
  g_string_to_utf8(*src, *buf, n)
  PokeB(*buf + n, 0)
  Protected out.s = PeekS(*buf, -1, #PB_UTF8)
  FreeMemory(*buf)
  ProcedureReturn out
EndProcedure

; Godot interns StringNames, so the same text always shares its data pointer.
; That is what makes this comparison valid - Godot exposes no
; string_name_operator_equal to GDExtensions.
Procedure.i GDEX_StringNameEq(*a.GodotStringName, *b.GodotStringName)
  ProcedureReturn Bool(*a\data = *b\data)
EndProcedure

; Fill a StringName from a PureBasic string. Nothing frees these: the
; GDExtension interface has no string_name_destroy, so framework StringNames
; are created once at registration and deliberately kept alive.
Procedure GDEX_SNFrom(*sn.GodotStringName, text.s)
  g_string_name_new(*sn, UTF8(text))
EndProcedure

Procedure.i _pGetMethodBind(*class_name.GodotStringName, *method.GodotStringName, hash.q)
  ProcedureReturn g_classdb_get_method_bind(*class_name, *method, hash)
EndProcedure

Procedure.i _pGlobalGetSingleton(*name.GodotStringName)
  GDEX_Trace("[gdex] GlobalGetSingleton")
  ProcedureReturn g_global_get_singleton(*name)
EndProcedure

; ---------------------------------------------------------------------------
; load_api - resolve every function pointer. Called once, from the library
; entry point, before any class is registered.
; ---------------------------------------------------------------------------
Procedure load_api(*p_get_proc_address)
  GDEX_Trace("[gdex] load_api start")

  Protected get_proc.GDExtensionInterfaceGetProcAddress = *p_get_proc_address
  Protected name.s

  ; A convenience: the interface wants a C string, and @pbstring gives one.
  Macro RESOLVE(Target, ApiName)
    name = ApiName
    Target = get_proc(UTF8(name))
  EndMacro

  RESOLVE(g_get_godot_version2,             "get_godot_version2")
  RESOLVE(g_mem_alloc2,                     "mem_alloc2")
  RESOLVE(g_mem_free2,                      "mem_free2")
  RESOLVE(g_print_error,                    "print_error")
  RESOLVE(g_print_warning,                  "print_warning")

  RESOLVE(g_variant_new_nil,                "variant_new_nil")
  RESOLVE(g_variant_destroy,                "variant_destroy")
  RESOLVE(g_variant_get_type,               "variant_get_type")
  RESOLVE(g_get_variant_from_type,          "get_variant_from_type_constructor")
  RESOLVE(g_get_variant_to_type,            "get_variant_to_type_constructor")
  RESOLVE(g_get_operator_evaluator,         "variant_get_ptr_operator_evaluator")

  RESOLVE(g_string_name_new,                "string_name_new_with_utf8_chars")
  RESOLVE(g_variant_get_ptr_destructor,     "variant_get_ptr_destructor")
  RESOLVE(g_variant_get_ptr_builtin_method, "variant_get_ptr_builtin_method")
  RESOLVE(g_variant_get_ptr_utility_function, "variant_get_ptr_utility_function")
  RESOLVE(g_string_new,                     "string_new_with_utf8_chars")
  RESOLVE(g_string_to_utf8,                 "string_to_utf8_chars")

  RESOLVE(g_object_method_bind_call,        "object_method_bind_call")
  RESOLVE(g_object_method_bind_ptrcall,     "object_method_bind_ptrcall")
  g_ptr_object_method_bind_ptrcall = g_object_method_bind_ptrcall
  RESOLVE(g_object_set_instance,            "object_set_instance")
  RESOLVE(g_object_set_instance_binding,    "object_set_instance_binding")
  RESOLVE(g_object_destroy,                 "object_destroy")
  RESOLVE(g_global_get_singleton,           "global_get_singleton")

  RESOLVE(g_classdb_construct_object3,      "classdb_construct_object3")
  RESOLVE(g_classdb_get_method_bind,        "classdb_get_method_bind")
  RESOLVE(g_classdb_register_class6,        "classdb_register_extension_class6")
  RESOLVE(g_classdb_register_method,        "classdb_register_extension_class_method")
  RESOLVE(g_classdb_register_property,      "classdb_register_extension_class_property")
  RESOLVE(g_classdb_register_signal,         "classdb_register_extension_class_signal")
  RESOLVE(g_classdb_unregister_class,        "classdb_unregister_extension_class")

  g_from_float       = g_get_variant_from_type(#GDEXTENSION_VARIANT_TYPE_FLOAT)
  g_to_float         = g_get_variant_to_type(#GDEXTENSION_VARIANT_TYPE_FLOAT)
  g_from_int         = g_get_variant_from_type(#GDEXTENSION_VARIANT_TYPE_INT)
  g_to_int           = g_get_variant_to_type(#GDEXTENSION_VARIANT_TYPE_INT)
  g_from_vector2     = g_get_variant_from_type(#GDEXTENSION_VARIANT_TYPE_VECTOR2)
  g_to_vector2       = g_get_variant_to_type(#GDEXTENSION_VARIANT_TYPE_VECTOR2)
  g_from_string_name = g_get_variant_from_type(#GDEXTENSION_VARIANT_TYPE_STRING_NAME)

  GDEX_Trace("[gdex] load_api resolved")

  ; The binding callbacks are installed once, here, so every class shares them.
  gdex_binding_callbacks\create_callback    = @GDEX_BindingCreate()
  gdex_binding_callbacks\free_callback      = @GDEX_BindingFree()
  gdex_binding_callbacks\reference_callback = @GDEX_BindingReference()

  If Not g_classdb_register_class6 Or Not g_classdb_construct_object3
    Debug "[gdex] FATAL: the GDExtension interface did not resolve"
  EndIf

  ; The one StringName the virtual-method dispatch needs by name, made here
  ; because it must exist before any class is registered.
  name = "_process"
  g_string_name_new(@gdex_sn_process, UTF8(name))

  ; The empty StringName / String every absent PropertyInfo field points at.
  name = ""
  g_string_name_new(@gdex_empty_sn, UTF8(name))
  g_string_new(@gdex_empty_string, UTF8(name))
  GDEX_Trace("[gdex] load_api end")
EndProcedure
