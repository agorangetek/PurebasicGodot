; ===========================================================================
; gdextension_interface.pbi - GENERATED FILE. Do not edit by hand.
;
;   tools/gen_interface.py            regenerate from the header
;   tools/gen_interface.py --check    fail if this file is out of date
;
; Source: gdextension_interface.h, Godot's own header, vendored beside
; this file. The declarations below are derived from it rather than
; transcribed by hand, so they cannot drift from it.
;
; Why they exist at all: PureBasic cannot use the header's types. It
; mangles its own structures to s_<lowercased-name> with f_<field>
; members and generates field access against that, so every structure
; and every function-pointer type the extension touches needs a
; PureBasic declaration. This is those declarations, generated.
; ===========================================================================

Structure GDExtensionCallError Align #PB_Structure_AlignC
  error.l
  argument.l
  expected.l
EndStructure

Structure GDExtensionInstanceBindingCallbacks Align #PB_Structure_AlignC
  *create_callback
  *free_callback
  *reference_callback
EndStructure

Structure GDExtensionPropertyInfo Align #PB_Structure_AlignC
  type.l
  *name
  *class_name
  hint.l
  *hint_string
  usage.l
EndStructure

Structure GDExtensionMethodInfo Align #PB_Structure_AlignC
  *name
  return_value.GDExtensionPropertyInfo
  flags.l
  id.l
  argument_count.l
  *arguments
  default_argument_count.l
  *default_arguments
EndStructure

Structure GDExtensionClassCreationInfo Align #PB_Structure_AlignC
  is_virtual.b
  is_abstract.b
  *set_func
  *get_func
  *get_property_list_func
  *free_property_list_func
  *property_can_revert_func
  *property_get_revert_func
  *notification_func
  *to_string_func
  *reference_func
  *unreference_func
  *create_instance_func
  *free_instance_func
  *get_virtual_func
  *get_rid_func
  *class_userdata
EndStructure

Structure GDExtensionClassCreationInfo2 Align #PB_Structure_AlignC
  is_virtual.b
  is_abstract.b
  is_exposed.b
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
  *get_rid_func
  *class_userdata
EndStructure

Structure GDExtensionClassCreationInfo3 Align #PB_Structure_AlignC
  is_virtual.b
  is_abstract.b
  is_exposed.b
  is_runtime.b
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
  *get_rid_func
  *class_userdata
EndStructure

Structure GDExtensionClassCreationInfo4 Align #PB_Structure_AlignC
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

Structure GDExtensionClassMethodInfo Align #PB_Structure_AlignC
  *name
  *method_userdata
  *call_func
  *ptrcall_func
  method_flags.l
  has_return_value.b
  *return_value_info
  return_value_metadata.l
  argument_count.l
  *arguments_info
  *arguments_metadata
  default_argument_count.l
  *default_arguments
EndStructure

Structure GDExtensionClassVirtualMethodInfo Align #PB_Structure_AlignC
  *name
  method_flags.l
  return_value.GDExtensionPropertyInfo
  return_value_metadata.l
  argument_count.l
  *arguments
  *arguments_metadata
EndStructure

Structure GDExtensionCallableCustomInfo Align #PB_Structure_AlignC
  *callable_userdata
  *token
  object_id.q
  *call_func
  *is_valid_func
  *free_func
  *hash_func
  *equal_func
  *less_than_func
  *to_string_func
EndStructure

Structure GDExtensionCallableCustomInfo2 Align #PB_Structure_AlignC
  *callable_userdata
  *token
  object_id.q
  *call_func
  *is_valid_func
  *free_func
  *hash_func
  *equal_func
  *less_than_func
  *to_string_func
  *get_argument_count_func
EndStructure

Structure GDExtensionScriptInstanceInfo Align #PB_Structure_AlignC
  *set_func
  *get_func
  *get_property_list_func
  *free_property_list_func
  *property_can_revert_func
  *property_get_revert_func
  *get_owner_func
  *get_property_state_func
  *get_method_list_func
  *free_method_list_func
  *get_property_type_func
  *has_method_func
  *call_func
  *notification_func
  *to_string_func
  *refcount_incremented_func
  *refcount_decremented_func
  *get_script_func
  *is_placeholder_func
  *set_fallback_func
  *get_fallback_func
  *get_language_func
  *free_func
EndStructure

Structure GDExtensionScriptInstanceInfo2 Align #PB_Structure_AlignC
  *set_func
  *get_func
  *get_property_list_func
  *free_property_list_func
  *get_class_category_func
  *property_can_revert_func
  *property_get_revert_func
  *get_owner_func
  *get_property_state_func
  *get_method_list_func
  *free_method_list_func
  *get_property_type_func
  *validate_property_func
  *has_method_func
  *call_func
  *notification_func
  *to_string_func
  *refcount_incremented_func
  *refcount_decremented_func
  *get_script_func
  *is_placeholder_func
  *set_fallback_func
  *get_fallback_func
  *get_language_func
  *free_func
EndStructure

Structure GDExtensionScriptInstanceInfo3 Align #PB_Structure_AlignC
  *set_func
  *get_func
  *get_property_list_func
  *free_property_list_func
  *get_class_category_func
  *property_can_revert_func
  *property_get_revert_func
  *get_owner_func
  *get_property_state_func
  *get_method_list_func
  *free_method_list_func
  *get_property_type_func
  *validate_property_func
  *has_method_func
  *get_method_argument_count_func
  *call_func
  *notification_func
  *to_string_func
  *refcount_incremented_func
  *refcount_decremented_func
  *get_script_func
  *is_placeholder_func
  *set_fallback_func
  *get_fallback_func
  *get_language_func
  *free_func
EndStructure

Structure GDExtensionInitialization Align #PB_Structure_AlignC
  minimum_initialization_level.l
  *userdata
  *initialize
  *deinitialize
EndStructure

Structure GDExtensionGodotVersion Align #PB_Structure_AlignC
  major.l
  minor.l
  patch.l
  *string
EndStructure

Structure GDExtensionGodotVersion2 Align #PB_Structure_AlignC
  major.l
  minor.l
  patch.l
  hex.l
  *status
  *build
  *hash
  timestamp.q
  *string
EndStructure

Structure GDExtensionMainLoopCallbacks Align #PB_Structure_AlignC
  *startup_func
  *shutdown_func
  *frame_func
EndStructure

Prototype GDExtensionVariantFromTypeConstructorFunc(*p0, *p1)
Prototype GDExtensionTypeFromVariantConstructorFunc(*p0, *p1)
Prototype GDExtensionVariantGetInternalPtrFunc(*p0)
Prototype GDExtensionPtrOperatorEvaluator(*p_left, *p_right, *r_result)
Prototype GDExtensionPtrBuiltInMethod(*p_base, *p_args, *r_return, p_argument_count.l)
Prototype GDExtensionPtrConstructor(*p_base, *p_args)
Prototype GDExtensionPtrDestructor(*p_base)
Prototype GDExtensionPtrSetter(*p_base, *p_value)
Prototype GDExtensionPtrGetter(*p_base, *r_value)
Prototype GDExtensionPtrIndexedSetter(*p_base, p_index.q, *p_value)
Prototype GDExtensionPtrIndexedGetter(*p_base, p_index.q, *r_value)
Prototype GDExtensionPtrKeyedSetter(*p_base, *p_key, *p_value)
Prototype GDExtensionPtrKeyedGetter(*p_base, *p_key, *r_value)
Prototype GDExtensionPtrKeyedChecker(*p_base, *p_key)
Prototype GDExtensionPtrUtilityFunction(*r_return, *p_args, p_argument_count.l)
Prototype GDExtensionClassConstructor()
Prototype GDExtensionInstanceBindingCreateCallback(*p_token, *p_instance)
Prototype GDExtensionInstanceBindingFreeCallback(*p_token, *p_instance, *p_binding)
Prototype GDExtensionInstanceBindingReferenceCallback(*p_token, *p_binding, p_reference.b)
Prototype GDExtensionClassSet(*p_instance, *p_name, *p_value)
Prototype GDExtensionClassGet(*p_instance, *p_name, *r_ret)
Prototype GDExtensionClassGetRID(*p_instance)
Prototype GDExtensionClassGetPropertyList(*p_instance, *r_count)
Prototype GDExtensionClassFreePropertyList(*p_instance, *p_list)
Prototype GDExtensionClassFreePropertyList2(*p_instance, *p_list, p_count.l)
Prototype GDExtensionClassPropertyCanRevert(*p_instance, *p_name)
Prototype GDExtensionClassPropertyGetRevert(*p_instance, *p_name, *r_ret)
Prototype GDExtensionClassValidateProperty(*p_instance, *p_property)
Prototype GDExtensionClassNotification(*p_instance, p_what.l)
Prototype GDExtensionClassNotification2(*p_instance, p_what.l, p_reversed.b)
Prototype GDExtensionClassToString(*p_instance, *r_is_valid, *p_out)
Prototype GDExtensionClassReference(*p_instance)
Prototype GDExtensionClassUnreference(*p_instance)
Prototype GDExtensionClassCallVirtual(*p_instance, *p_args, *r_ret)
Prototype GDExtensionClassCreateInstance(*p_class_userdata)
Prototype GDExtensionClassCreateInstance2(*p_class_userdata, p_notify_postinitialize.b)
Prototype GDExtensionClassCreateInstance3(*p_class_userdata, p_notify_postinitialize.b)
Prototype GDExtensionClassFreeInstance(*p_class_userdata, *p_instance)
Prototype GDExtensionClassRecreateInstance(*p_class_userdata, *p_object)
Prototype GDExtensionClassGetVirtual(*p_class_userdata, *p_name)
Prototype GDExtensionClassGetVirtual2(*p_class_userdata, *p_name, p_hash.l)
Prototype GDExtensionClassGetVirtualCallData(*p_class_userdata, *p_name)
Prototype GDExtensionClassGetVirtualCallData2(*p_class_userdata, *p_name, p_hash.l)
Prototype GDExtensionClassCallVirtualWithData(*p_instance, *p_name, *p_virtual_call_userdata, *p_args, *r_ret)
Prototype GDExtensionEditorGetClassesUsedCallback(*p_packed_string_array)
Prototype GDExtensionClassMethodCall(*method_userdata, *p_instance, *p_args, p_argument_count.q, *r_return, *r_error)
Prototype GDExtensionClassMethodValidatedCall(*method_userdata, *p_instance, *p_args, *r_return)
Prototype GDExtensionClassMethodPtrCall(*method_userdata, *p_instance, *p_args, *r_ret)
Prototype GDExtensionCallableCustomCall(*callable_userdata, *p_args, p_argument_count.q, *r_return, *r_error)
Prototype GDExtensionCallableCustomIsValid(*callable_userdata)
Prototype GDExtensionCallableCustomFree(*callable_userdata)
Prototype GDExtensionCallableCustomHash(*callable_userdata)
Prototype GDExtensionCallableCustomEqual(*callable_userdata_a, *callable_userdata_b)
Prototype GDExtensionCallableCustomLessThan(*callable_userdata_a, *callable_userdata_b)
Prototype GDExtensionCallableCustomToString(*callable_userdata, *r_is_valid, *r_out)
Prototype GDExtensionCallableCustomGetArgumentCount(*callable_userdata, *r_is_valid)
Prototype GDExtensionScriptInstanceSet(*p_instance, *p_name, *p_value)
Prototype GDExtensionScriptInstanceGet(*p_instance, *p_name, *r_ret)
Prototype GDExtensionScriptInstanceGetPropertyList(*p_instance, *r_count)
Prototype GDExtensionScriptInstanceFreePropertyList(*p_instance, *p_list)
Prototype GDExtensionScriptInstanceFreePropertyList2(*p_instance, *p_list, p_count.l)
Prototype GDExtensionScriptInstanceGetClassCategory(*p_instance, *p_class_category)
Prototype GDExtensionScriptInstanceGetPropertyType(*p_instance, *p_name, *r_is_valid)
Prototype GDExtensionScriptInstanceValidateProperty(*p_instance, *p_property)
Prototype GDExtensionScriptInstancePropertyCanRevert(*p_instance, *p_name)
Prototype GDExtensionScriptInstancePropertyGetRevert(*p_instance, *p_name, *r_ret)
Prototype GDExtensionScriptInstanceGetOwner(*p_instance)
Prototype GDExtensionScriptInstancePropertyStateAdd(*p_name, *p_value, *p_userdata)
Prototype GDExtensionScriptInstanceGetPropertyState(*p_instance, *p_add_func, *p_userdata)
Prototype GDExtensionScriptInstanceGetMethodList(*p_instance, *r_count)
Prototype GDExtensionScriptInstanceFreeMethodList(*p_instance, *p_list)
Prototype GDExtensionScriptInstanceFreeMethodList2(*p_instance, *p_list, p_count.l)
Prototype GDExtensionScriptInstanceHasMethod(*p_instance, *p_name)
Prototype GDExtensionScriptInstanceGetMethodArgumentCount(*p_instance, *p_name, *r_is_valid)
Prototype GDExtensionScriptInstanceCall(*p_self, *p_method, *p_args, p_argument_count.q, *r_return, *r_error)
Prototype GDExtensionScriptInstanceNotification(*p_instance, p_what.l)
Prototype GDExtensionScriptInstanceNotification2(*p_instance, p_what.l, p_reversed.b)
Prototype GDExtensionScriptInstanceToString(*p_instance, *r_is_valid, *r_out)
Prototype GDExtensionScriptInstanceRefCountIncremented(*p_instance)
Prototype GDExtensionScriptInstanceRefCountDecremented(*p_instance)
Prototype GDExtensionScriptInstanceGetScript(*p_instance)
Prototype GDExtensionScriptInstanceIsPlaceholder(*p_instance)
Prototype GDExtensionScriptInstanceGetLanguage(*p_instance)
Prototype GDExtensionScriptInstanceFree(*p_instance)
Prototype GDExtensionWorkerThreadPoolGroupTask(*p0, p1.l)
Prototype GDExtensionWorkerThreadPoolTask(*p0)
Prototype GDExtensionInitializeCallback(*p_userdata, p_level.l)
Prototype GDExtensionDeinitializeCallback(*p_userdata, p_level.l)
Prototype GDExtensionInterfaceFunctionPtr()
Prototype GDExtensionInterfaceGetProcAddress(*p_function_name)
Prototype GDExtensionInitializationFunction(*p_get_proc_address, *p_library, *r_initialization)
Prototype GDExtensionMainLoopStartupCallback()
Prototype GDExtensionMainLoopShutdownCallback()
Prototype GDExtensionMainLoopFrameCallback()
Prototype GDExtensionInterfaceGetGodotVersion(*r_godot_version)
Prototype GDExtensionInterfaceGetGodotVersion2(*r_godot_version)
Prototype GDExtensionInterfaceMemAlloc(p_bytes.q)
Prototype GDExtensionInterfaceMemRealloc(*p_ptr, p_bytes.q)
Prototype GDExtensionInterfaceMemFree(*p_ptr)
Prototype GDExtensionInterfaceMemAlloc2(p_bytes.q, p_pad_align.b)
Prototype GDExtensionInterfaceMemRealloc2(*p_ptr, p_bytes.q, p_pad_align.b)
Prototype GDExtensionInterfaceMemFree2(*p_ptr, p_pad_align.b)
Prototype GDExtensionInterfacePrintError(*p_description, *p_function, *p_file, p_line.l, p_editor_notify.b)
Prototype GDExtensionInterfacePrintErrorWithMessage(*p_description, *p_message, *p_function, *p_file, p_line.l, p_editor_notify.b)
Prototype GDExtensionInterfacePrintWarning(*p_description, *p_function, *p_file, p_line.l, p_editor_notify.b)
Prototype GDExtensionInterfacePrintWarningWithMessage(*p_description, *p_message, *p_function, *p_file, p_line.l, p_editor_notify.b)
Prototype GDExtensionInterfacePrintScriptError(*p_description, *p_function, *p_file, p_line.l, p_editor_notify.b)
Prototype GDExtensionInterfacePrintScriptErrorWithMessage(*p_description, *p_message, *p_function, *p_file, p_line.l, p_editor_notify.b)
Prototype GDExtensionInterfaceGetNativeStructSize(*p_name)
Prototype GDExtensionInterfaceVariantNewCopy(*r_dest, *p_src)
Prototype GDExtensionInterfaceVariantNewNil(*r_dest)
Prototype GDExtensionInterfaceVariantDestroy(*p_self)
Prototype GDExtensionInterfaceVariantCall(*p_self, *p_method, *p_args, p_argument_count.q, *r_return, *r_error)
Prototype GDExtensionInterfaceVariantCallStatic(p_type.l, *p_method, *p_args, p_argument_count.q, *r_return, *r_error)
Prototype GDExtensionInterfaceVariantEvaluate(p_op.l, *p_a, *p_b, *r_return, *r_valid)
Prototype GDExtensionInterfaceVariantSet(*p_self, *p_key, *p_value, *r_valid)
Prototype GDExtensionInterfaceVariantSetNamed(*p_self, *p_key, *p_value, *r_valid)
Prototype GDExtensionInterfaceVariantSetKeyed(*p_self, *p_key, *p_value, *r_valid)
Prototype GDExtensionInterfaceVariantSetIndexed(*p_self, p_index.q, *p_value, *r_valid, *r_oob)
Prototype GDExtensionInterfaceVariantGet(*p_self, *p_key, *r_ret, *r_valid)
Prototype GDExtensionInterfaceVariantGetNamed(*p_self, *p_key, *r_ret, *r_valid)
Prototype GDExtensionInterfaceVariantGetKeyed(*p_self, *p_key, *r_ret, *r_valid)
Prototype GDExtensionInterfaceVariantGetIndexed(*p_self, p_index.q, *r_ret, *r_valid, *r_oob)
Prototype GDExtensionInterfaceVariantIterInit(*p_self, *r_iter, *r_valid)
Prototype GDExtensionInterfaceVariantIterNext(*p_self, *r_iter, *r_valid)
Prototype GDExtensionInterfaceVariantIterGet(*p_self, *r_iter, *r_ret, *r_valid)
Prototype GDExtensionInterfaceVariantHash(*p_self)
Prototype GDExtensionInterfaceVariantRecursiveHash(*p_self, p_recursion_count.q)
Prototype GDExtensionInterfaceVariantHashCompare(*p_self, *p_other)
Prototype GDExtensionInterfaceVariantBooleanize(*p_self)
Prototype GDExtensionInterfaceVariantDuplicate(*p_self, *r_ret, p_deep.b)
Prototype GDExtensionInterfaceVariantStringify(*p_self, *r_ret)
Prototype GDExtensionInterfaceVariantGetType(*p_self)
Prototype GDExtensionInterfaceVariantHasMethod(*p_self, *p_method)
Prototype GDExtensionInterfaceVariantHasMember(p_type.l, *p_member)
Prototype GDExtensionInterfaceVariantHasKey(*p_self, *p_key, *r_valid)
Prototype GDExtensionInterfaceVariantGetObjectInstanceId(*p_self)
Prototype GDExtensionInterfaceVariantGetTypeName(p_type.l, *r_name)
Prototype GDExtensionInterfaceVariantGetTypeByName(*p_type_name)
Prototype GDExtensionInterfaceVariantCanConvert(p_from.l, p_to.l)
Prototype GDExtensionInterfaceVariantCanConvertStrict(p_from.l, p_to.l)
Prototype GDExtensionInterfaceGetVariantFromTypeConstructor(p_type.l)
Prototype GDExtensionInterfaceGetVariantToTypeConstructor(p_type.l)
Prototype GDExtensionInterfaceVariantGetPtrInternalGetter(p_type.l)
Prototype GDExtensionInterfaceVariantGetPtrOperatorEvaluator(p_operator.l, p_type_a.l, p_type_b.l)
Prototype GDExtensionInterfaceVariantGetPtrBuiltinMethod(p_type.l, *p_method, p_hash.q)
Prototype GDExtensionInterfaceVariantGetPtrConstructor(p_type.l, p_constructor.l)
Prototype GDExtensionInterfaceVariantGetPtrDestructor(p_type.l)
Prototype GDExtensionInterfaceVariantConstruct(p_type.l, *r_base, *p_args, p_argument_count.l, *r_error)
Prototype GDExtensionInterfaceVariantGetPtrSetter(p_type.l, *p_member)
Prototype GDExtensionInterfaceVariantGetPtrGetter(p_type.l, *p_member)
Prototype GDExtensionInterfaceVariantGetPtrIndexedSetter(p_type.l)
Prototype GDExtensionInterfaceVariantGetPtrIndexedGetter(p_type.l)
Prototype GDExtensionInterfaceVariantGetPtrKeyedSetter(p_type.l)
Prototype GDExtensionInterfaceVariantGetPtrKeyedGetter(p_type.l)
Prototype GDExtensionInterfaceVariantGetPtrKeyedChecker(p_type.l)
Prototype GDExtensionInterfaceVariantGetConstantValue(p_type.l, *p_constant, *r_ret)
Prototype GDExtensionInterfaceVariantGetPtrUtilityFunction(*p_function, p_hash.q)
Prototype GDExtensionInterfaceStringNewWithLatin1Chars(*r_dest, *p_contents)
Prototype GDExtensionInterfaceStringNewWithUtf8Chars(*r_dest, *p_contents)
Prototype GDExtensionInterfaceStringNewWithUtf16Chars(*r_dest, *p_contents)
Prototype GDExtensionInterfaceStringNewWithUtf32Chars(*r_dest, *p_contents)
Prototype GDExtensionInterfaceStringNewWithWideChars(*r_dest, *p_contents)
Prototype GDExtensionInterfaceStringNewWithLatin1CharsAndLen(*r_dest, *p_contents, p_size.q)
Prototype GDExtensionInterfaceStringNewWithUtf8CharsAndLen(*r_dest, *p_contents, p_size.q)
Prototype GDExtensionInterfaceStringNewWithUtf8CharsAndLen2(*r_dest, *p_contents, p_size.q)
Prototype GDExtensionInterfaceStringNewWithUtf16CharsAndLen(*r_dest, *p_contents, p_char_count.q)
Prototype GDExtensionInterfaceStringNewWithUtf16CharsAndLen2(*r_dest, *p_contents, p_char_count.q, p_default_little_endian.b)
Prototype GDExtensionInterfaceStringNewWithUtf32CharsAndLen(*r_dest, *p_contents, p_char_count.q)
Prototype GDExtensionInterfaceStringNewWithWideCharsAndLen(*r_dest, *p_contents, p_char_count.q)
Prototype GDExtensionInterfaceStringToLatin1Chars(*p_self, *r_text, p_max_write_length.q)
Prototype GDExtensionInterfaceStringToUtf8Chars(*p_self, *r_text, p_max_write_length.q)
Prototype GDExtensionInterfaceStringToUtf16Chars(*p_self, *r_text, p_max_write_length.q)
Prototype GDExtensionInterfaceStringToUtf32Chars(*p_self, *r_text, p_max_write_length.q)
Prototype GDExtensionInterfaceStringToWideChars(*p_self, *r_text, p_max_write_length.q)
Prototype GDExtensionInterfaceStringOperatorIndex(*p_self, p_index.q)
Prototype GDExtensionInterfaceStringOperatorIndexConst(*p_self, p_index.q)
Prototype GDExtensionInterfaceStringOperatorPlusEqString(*p_self, *p_b)
Prototype GDExtensionInterfaceStringOperatorPlusEqChar(*p_self, p_b.l)
Prototype GDExtensionInterfaceStringOperatorPlusEqCstr(*p_self, *p_b)
Prototype GDExtensionInterfaceStringOperatorPlusEqWcstr(*p_self, *p_b)
Prototype GDExtensionInterfaceStringOperatorPlusEqC32str(*p_self, *p_b)
Prototype GDExtensionInterfaceStringResize(*p_self, p_resize.q)
Prototype GDExtensionInterfaceStringNameNewWithLatin1Chars(*r_dest, *p_contents, p_is_static.b)
Prototype GDExtensionInterfaceStringNameNewWithUtf8Chars(*r_dest, *p_contents)
Prototype GDExtensionInterfaceStringNameNewWithUtf8CharsAndLen(*r_dest, *p_contents, p_size.q)
Prototype GDExtensionInterfaceXmlParserOpenBuffer(*p_instance, *p_buffer, p_size.q)
Prototype GDExtensionInterfaceFileAccessStoreBuffer(*p_instance, *p_src, p_length.q)
Prototype GDExtensionInterfaceFileAccessGetBuffer(*p_instance, *p_dst, p_length.q)
Prototype GDExtensionInterfaceImagePtrw(*p_instance)
Prototype GDExtensionInterfaceImagePtr(*p_instance)
Prototype GDExtensionInterfaceWorkerThreadPoolAddNativeGroupTask(*p_instance, *p_func, *p_userdata, p_elements.l, p_tasks.l, p_high_priority.b, *p_description)
Prototype GDExtensionInterfaceWorkerThreadPoolAddNativeTask(*p_instance, *p_func, *p_userdata, p_high_priority.b, *p_description)
Prototype GDExtensionInterfacePackedByteArrayOperatorIndex(*p_self, p_index.q)
Prototype GDExtensionInterfacePackedByteArrayOperatorIndexConst(*p_self, p_index.q)
Prototype GDExtensionInterfacePackedFloat32ArrayOperatorIndex(*p_self, p_index.q)
Prototype GDExtensionInterfacePackedFloat32ArrayOperatorIndexConst(*p_self, p_index.q)
Prototype GDExtensionInterfacePackedFloat64ArrayOperatorIndex(*p_self, p_index.q)
Prototype GDExtensionInterfacePackedFloat64ArrayOperatorIndexConst(*p_self, p_index.q)
Prototype GDExtensionInterfacePackedInt32ArrayOperatorIndex(*p_self, p_index.q)
Prototype GDExtensionInterfacePackedInt32ArrayOperatorIndexConst(*p_self, p_index.q)
Prototype GDExtensionInterfacePackedInt64ArrayOperatorIndex(*p_self, p_index.q)
Prototype GDExtensionInterfacePackedInt64ArrayOperatorIndexConst(*p_self, p_index.q)
Prototype GDExtensionInterfacePackedStringArrayOperatorIndex(*p_self, p_index.q)
Prototype GDExtensionInterfacePackedStringArrayOperatorIndexConst(*p_self, p_index.q)
Prototype GDExtensionInterfacePackedVector2ArrayOperatorIndex(*p_self, p_index.q)
Prototype GDExtensionInterfacePackedVector2ArrayOperatorIndexConst(*p_self, p_index.q)
Prototype GDExtensionInterfacePackedVector3ArrayOperatorIndex(*p_self, p_index.q)
Prototype GDExtensionInterfacePackedVector3ArrayOperatorIndexConst(*p_self, p_index.q)
Prototype GDExtensionInterfacePackedVector4ArrayOperatorIndex(*p_self, p_index.q)
Prototype GDExtensionInterfacePackedVector4ArrayOperatorIndexConst(*p_self, p_index.q)
Prototype GDExtensionInterfacePackedColorArrayOperatorIndex(*p_self, p_index.q)
Prototype GDExtensionInterfacePackedColorArrayOperatorIndexConst(*p_self, p_index.q)
Prototype GDExtensionInterfaceArrayOperatorIndex(*p_self, p_index.q)
Prototype GDExtensionInterfaceArrayOperatorIndexConst(*p_self, p_index.q)
Prototype GDExtensionInterfaceArrayRef(*p_self, *p_from)
Prototype GDExtensionInterfaceArraySetTyped(*p_self, p_type.l, *p_class_name, *p_script)
Prototype GDExtensionInterfaceDictionaryOperatorIndex(*p_self, *p_key)
Prototype GDExtensionInterfaceDictionaryOperatorIndexConst(*p_self, *p_key)
Prototype GDExtensionInterfaceDictionarySetTyped(*p_self, p_key_type.l, *p_key_class_name, *p_key_script, p_value_type.l, *p_value_class_name, *p_value_script)
Prototype GDExtensionInterfaceObjectMethodBindCall(*p_method_bind, *p_instance, *p_args, p_arg_count.q, *r_ret, *r_error)
Prototype GDExtensionInterfaceObjectMethodBindPtrcall(*p_method_bind, *p_instance, *p_args, *r_ret)
Prototype GDExtensionInterfaceObjectDestroy(*p_o)
Prototype GDExtensionInterfaceGlobalGetSingleton(*p_name)
Prototype GDExtensionInterfaceObjectGetInstanceBinding(*p_o, *p_token, *p_callbacks)
Prototype GDExtensionInterfaceObjectSetInstanceBinding(*p_o, *p_token, *p_binding, *p_callbacks)
Prototype GDExtensionInterfaceObjectFreeInstanceBinding(*p_o, *p_token)
Prototype GDExtensionInterfaceObjectSetInstance(*p_o, *p_classname, *p_instance)
Prototype GDExtensionInterfaceObjectGetClassName(*p_object, *p_library, *r_class_name)
Prototype GDExtensionInterfaceObjectCastTo(*p_object, *p_class_tag)
Prototype GDExtensionInterfaceObjectGetInstanceFromId(p_instance_id.q)
Prototype GDExtensionInterfaceObjectGetInstanceId(*p_object)
Prototype GDExtensionInterfaceObjectHasScriptMethod(*p_object, *p_method)
Prototype GDExtensionInterfaceObjectCallScriptMethod(*p_object, *p_method, *p_args, p_argument_count.q, *r_return, *r_error)
Prototype GDExtensionInterfaceRefGetObject(*p_ref)
Prototype GDExtensionInterfaceRefSetObject(*p_ref, *p_object)
Prototype GDExtensionInterfaceScriptInstanceCreate(*p_info, *p_instance_data)
Prototype GDExtensionInterfaceScriptInstanceCreate2(*p_info, *p_instance_data)
Prototype GDExtensionInterfaceScriptInstanceCreate3(*p_info, *p_instance_data)
Prototype GDExtensionInterfacePlaceholderScriptInstanceCreate(*p_language, *p_script, *p_owner)
Prototype GDExtensionInterfacePlaceholderScriptInstanceUpdate(*p_placeholder, *p_properties, *p_values)
Prototype GDExtensionInterfaceObjectGetScriptInstance(*p_object, *p_language)
Prototype GDExtensionInterfaceObjectSetScriptInstance(*p_object, *p_script_instance)
Prototype GDExtensionInterfaceCallableCustomCreate(*r_callable, *p_callable_custom_info)
Prototype GDExtensionInterfaceCallableCustomCreate2(*r_callable, *p_callable_custom_info)
Prototype GDExtensionInterfaceCallableCustomGetUserdata(*p_callable, *p_token)
Prototype GDExtensionInterfaceClassdbConstructObject(*p_classname)
Prototype GDExtensionInterfaceClassdbConstructObject2(*p_classname)
Prototype GDExtensionInterfaceClassdbConstructObject3(*p_classname)
Prototype GDExtensionInterfaceClassdbGetMethodBind(*p_classname, *p_methodname, p_hash.q)
Prototype GDExtensionInterfaceClassdbGetClassTag(*p_classname)
Prototype GDExtensionInterfaceClassdbRegisterExtensionClass(*p_library, *p_class_name, *p_parent_class_name, *p_extension_funcs)
Prototype GDExtensionInterfaceClassdbRegisterExtensionClass2(*p_library, *p_class_name, *p_parent_class_name, *p_extension_funcs)
Prototype GDExtensionInterfaceClassdbRegisterExtensionClass3(*p_library, *p_class_name, *p_parent_class_name, *p_extension_funcs)
Prototype GDExtensionInterfaceClassdbRegisterExtensionClass4(*p_library, *p_class_name, *p_parent_class_name, *p_extension_funcs)
Prototype GDExtensionInterfaceClassdbRegisterExtensionClass5(*p_library, *p_class_name, *p_parent_class_name, *p_extension_funcs)
Prototype GDExtensionInterfaceClassdbRegisterExtensionClass6(*p_library, *p_class_name, *p_parent_class_name, *p_extension_funcs)
Prototype GDExtensionInterfaceClassdbRegisterExtensionClassMethod(*p_library, *p_class_name, *p_method_info)
Prototype GDExtensionInterfaceClassdbRegisterExtensionClassVirtualMethod(*p_library, *p_class_name, *p_method_info)
Prototype GDExtensionInterfaceClassdbRegisterExtensionClassIntegerConstant(*p_library, *p_class_name, *p_enum_name, *p_constant_name, p_constant_value.q, p_is_bitfield.b)
Prototype GDExtensionInterfaceClassdbRegisterExtensionClassProperty(*p_library, *p_class_name, *p_info, *p_setter, *p_getter)
Prototype GDExtensionInterfaceClassdbRegisterExtensionClassPropertyIndexed(*p_library, *p_class_name, *p_info, *p_setter, *p_getter, p_index.q)
Prototype GDExtensionInterfaceClassdbRegisterExtensionClassPropertyGroup(*p_library, *p_class_name, *p_group_name, *p_prefix)
Prototype GDExtensionInterfaceClassdbRegisterExtensionClassPropertySubgroup(*p_library, *p_class_name, *p_subgroup_name, *p_prefix)
Prototype GDExtensionInterfaceClassdbRegisterExtensionClassSignal(*p_library, *p_class_name, *p_signal_name, *p_argument_info, p_argument_count.q)
Prototype GDExtensionInterfaceClassdbUnregisterExtensionClass(*p_library, *p_class_name)
Prototype GDExtensionInterfaceGetLibraryPath(*p_library, *r_path)
Prototype GDExtensionInterfaceEditorAddPlugin(*p_class_name)
Prototype GDExtensionInterfaceEditorRemovePlugin(*p_class_name)
Prototype GDExtensionInterfaceEditorHelpLoadXmlFromUtf8Chars(*p_data)
Prototype GDExtensionInterfaceEditorHelpLoadXmlFromUtf8CharsAndLen(*p_data, p_size.q)
Prototype GDExtensionInterfaceEditorRegisterGetClassesUsedCallback(*p_library, *p_callback)
Prototype GDExtensionInterfaceRegisterMainLoopCallbacks(*p_library, *p_callbacks)
