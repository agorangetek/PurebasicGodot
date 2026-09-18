;/**************************************************************************/
;/*  gdextension_interface.pb                                               */
;/**************************************************************************/
;/*                         This file is part of:                          */
;/*                             GODOT ENGINE                               */
;/*                        https://godotengine.org                         */
;/**************************************************************************/
;/* Copyright (c) 2014-present Godot Engine contributors (see AUTHORS.md). */
;/* Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.                  */
;/*                                                                        */
;/* Permission is hereby granted, free of charge, to any person obtaining  */
;/* a copy of this software and associated documentation files (the        */
;/* "Software"), to deal in the Software without restriction, including    */
;/* without limitation the rights to use, copy, modify, merge, publish,    */
;/* distribute, sublicense, and/or sell copies of the Software, and to     */
;/* permit persons to whom the Software is furnished to do so, subject to  */
;/* the following conditions:                                              */
;/*                                                                        */
;/* The above copyright notice and this permission notice shall be         */
;/* included in all copies or substantial portions of the Software.        */
;/*                                                                        */
;/* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,        */
;/* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF     */
;/* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. */
;/* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY   */
;/* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,   */
;/* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE      */
;/* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                 */
;/**************************************************************************/

; This is a PureBasic conversion of the Godot GDExtension interface header.
; Together with the `extension_api.json` file, you should be able to generate any binder.

Enumeration GDEXTENSION_VARIANT_TYPE
  #GDEXTENSION_VARIANT_TYPE_NIL = 0
  #GDEXTENSION_VARIANT_TYPE_BOOL = 1
  #GDEXTENSION_VARIANT_TYPE_INT = 2
  #GDEXTENSION_VARIANT_TYPE_FLOAT = 3
  #GDEXTENSION_VARIANT_TYPE_STRING = 4
  #GDEXTENSION_VARIANT_TYPE_VECTOR2 = 5
  #GDEXTENSION_VARIANT_TYPE_VECTOR2I = 6
  #GDEXTENSION_VARIANT_TYPE_RECT2 = 7
  #GDEXTENSION_VARIANT_TYPE_RECT2I = 8
  #GDEXTENSION_VARIANT_TYPE_VECTOR3 = 9
  #GDEXTENSION_VARIANT_TYPE_VECTOR3I = 10
  #GDEXTENSION_VARIANT_TYPE_TRANSFORM2D = 11
  #GDEXTENSION_VARIANT_TYPE_VECTOR4 = 12
  #GDEXTENSION_VARIANT_TYPE_VECTOR4I = 13
  #GDEXTENSION_VARIANT_TYPE_PLANE = 14
  #GDEXTENSION_VARIANT_TYPE_QUATERNION = 15
  #GDEXTENSION_VARIANT_TYPE_AABB = 16
  #GDEXTENSION_VARIANT_TYPE_BASIS = 17
  #GDEXTENSION_VARIANT_TYPE_TRANSFORM3D = 18
  #GDEXTENSION_VARIANT_TYPE_PROJECTION = 19
  #GDEXTENSION_VARIANT_TYPE_COLOR = 20
  #GDEXTENSION_VARIANT_TYPE_STRING_NAME = 21
  #GDEXTENSION_VARIANT_TYPE_NODE_PATH = 22
  #GDEXTENSION_VARIANT_TYPE_RID = 23
  #GDEXTENSION_VARIANT_TYPE_OBJECT = 24
  #GDEXTENSION_VARIANT_TYPE_CALLABLE = 25
  #GDEXTENSION_VARIANT_TYPE_SIGNAL = 26
  #GDEXTENSION_VARIANT_TYPE_DICTIONARY = 27
  #GDEXTENSION_VARIANT_TYPE_ARRAY = 28
  #GDEXTENSION_VARIANT_TYPE_PACKED_BYTE_ARRAY = 29
  #GDEXTENSION_VARIANT_TYPE_PACKED_INT32_ARRAY = 30
  #GDEXTENSION_VARIANT_TYPE_PACKED_INT64_ARRAY = 31
  #GDEXTENSION_VARIANT_TYPE_PACKED_FLOAT32_ARRAY = 32
  #GDEXTENSION_VARIANT_TYPE_PACKED_FLOAT64_ARRAY = 33
  #GDEXTENSION_VARIANT_TYPE_PACKED_STRING_ARRAY = 34
  #GDEXTENSION_VARIANT_TYPE_PACKED_VECTOR2_ARRAY = 35
  #GDEXTENSION_VARIANT_TYPE_PACKED_VECTOR3_ARRAY = 36
  #GDEXTENSION_VARIANT_TYPE_PACKED_COLOR_ARRAY = 37
  #GDEXTENSION_VARIANT_TYPE_PACKED_VECTOR4_ARRAY = 38
  #GDEXTENSION_VARIANT_TYPE_VARIANT_MAX = 39
EndEnumeration

Enumeration GDEXTENSION_VARIANT_OP
  #GDEXTENSION_VARIANT_OP_EQUAL = 0
  #GDEXTENSION_VARIANT_OP_NOT_EQUAL = 1
  #GDEXTENSION_VARIANT_OP_LESS = 2
  #GDEXTENSION_VARIANT_OP_LESS_EQUAL = 3
  #GDEXTENSION_VARIANT_OP_GREATER = 4
  #GDEXTENSION_VARIANT_OP_GREATER_EQUAL = 5
  #GDEXTENSION_VARIANT_OP_ADD = 6
  #GDEXTENSION_VARIANT_OP_SUBTRACT = 7
  #GDEXTENSION_VARIANT_OP_MULTIPLY = 8
  #GDEXTENSION_VARIANT_OP_DIVIDE = 9
  #GDEXTENSION_VARIANT_OP_NEGATE = 10
  #GDEXTENSION_VARIANT_OP_POSITIVE = 11
  #GDEXTENSION_VARIANT_OP_MODULE = 12
  #GDEXTENSION_VARIANT_OP_POWER = 13
  #GDEXTENSION_VARIANT_OP_SHIFT_LEFT = 14
  #GDEXTENSION_VARIANT_OP_SHIFT_RIGHT = 15
  #GDEXTENSION_VARIANT_OP_BIT_AND = 16
  #GDEXTENSION_VARIANT_OP_BIT_OR = 17
  #GDEXTENSION_VARIANT_OP_BIT_XOR = 18
  #GDEXTENSION_VARIANT_OP_BIT_NEGATE = 19
  #GDEXTENSION_VARIANT_OP_AND = 20
  #GDEXTENSION_VARIANT_OP_OR = 21
  #GDEXTENSION_VARIANT_OP_XOR = 22
  #GDEXTENSION_VARIANT_OP_NOT = 23
  #GDEXTENSION_VARIANT_OP_IN = 24
  #GDEXTENSION_VARIANT_OP_MAX = 25
EndEnumeration

Enumeration GDEXTENSION_CALL_ERROR
  #GDEXTENSION_CALL_OK = 0
  #GDEXTENSION_CALL_ERROR_INVALID_METHOD = 1
  ; Expected a different variant type.
  #GDEXTENSION_CALL_ERROR_INVALID_ARGUMENT = 2
  ; Expected lower number of arguments.
  #GDEXTENSION_CALL_ERROR_TOO_MANY_ARGUMENTS = 3
  ; Expected higher number of arguments.
  #GDEXTENSION_CALL_ERROR_TOO_FEW_ARGUMENTS = 4
  #GDEXTENSION_CALL_ERROR_INSTANCE_IS_NULL = 5
  ; Used for const call.
  #GDEXTENSION_CALL_ERROR_METHOD_NOT_CONST = 6
EndEnumeration

Enumeration GDEXTENSION_CLASS_METHOD_FLAGS
  #GDEXTENSION_METHOD_FLAG_NORMAL = 1
  #GDEXTENSION_METHOD_FLAG_EDITOR = 2
  #GDEXTENSION_METHOD_FLAG_CONST = 4
  #GDEXTENSION_METHOD_FLAG_VIRTUAL = 8
  #GDEXTENSION_METHOD_FLAG_VARARG = 16
  #GDEXTENSION_METHOD_FLAG_STATIC = 32
  #GDEXTENSION_METHOD_FLAG_VIRTUAL_REQUIRED = 128
  #GDEXTENSION_METHOD_FLAGS_DEFAULT = 1
EndEnumeration

Enumeration GDEXTENSION_METHOD_ARGUMENT_METADATA
  #GDEXTENSION_METHOD_ARGUMENT_METADATA_NONE = 0
  #GDEXTENSION_METHOD_ARGUMENT_METADATA_INT_IS_INT8 = 1
  #GDEXTENSION_METHOD_ARGUMENT_METADATA_INT_IS_INT16 = 2
  #GDEXTENSION_METHOD_ARGUMENT_METADATA_INT_IS_INT32 = 3
  #GDEXTENSION_METHOD_ARGUMENT_METADATA_INT_IS_INT64 = 4
  #GDEXTENSION_METHOD_ARGUMENT_METADATA_INT_IS_UINT8 = 5
  #GDEXTENSION_METHOD_ARGUMENT_METADATA_INT_IS_UINT16 = 6
  #GDEXTENSION_METHOD_ARGUMENT_METADATA_INT_IS_UINT32 = 7
  #GDEXTENSION_METHOD_ARGUMENT_METADATA_INT_IS_UINT64 = 8
  #GDEXTENSION_METHOD_ARGUMENT_METADATA_REAL_IS_FLOAT = 9
  #GDEXTENSION_METHOD_ARGUMENT_METADATA_REAL_IS_DOUBLE = 10
  #GDEXTENSION_METHOD_ARGUMENT_METADATA_INT_IS_CHAR16 = 11
  #GDEXTENSION_METHOD_ARGUMENT_METADATA_INT_IS_CHAR32 = 12
  #GDEXTENSION_METHOD_ARGUMENT_METADATA_OBJECT_IS_REQUIRED = 13
EndEnumeration

Enumeration GDEXTENSION_INITIALIZATION_LEVEL
  #GDEXTENSION_INITIALIZATION_CORE = 0
  #GDEXTENSION_INITIALIZATION_SERVERS = 1
  #GDEXTENSION_INITIALIZATION_SCENE = 2
  #GDEXTENSION_INITIALIZATION_EDITOR = 3
  #GDEXTENSION_MAX_INITIALIZATION_LEVEL = 4
EndEnumeration

; Type aliases for pointers
; In PureBasic, we use * for pointers
; GDExtensionVariantPtr = *
; GDExtensionConstVariantPtr = * (const not enforced at runtime)
; GDExtensionUninitializedVariantPtr = *
; GDExtensionStringNamePtr = *
; GDExtensionConstStringNamePtr = *
; GDExtensionUninitializedStringNamePtr = *
; GDExtensionStringPtr = *
; GDExtensionConstStringPtr = *
; GDExtensionUninitializedStringPtr = *
; GDExtensionObjectPtr = *
; GDExtensionConstObjectPtr = *
; GDExtensionUninitializedObjectPtr = *
; GDExtensionTypePtr = *
; GDExtensionConstTypePtr = *
; GDExtensionUninitializedTypePtr = *
; GDExtensionMethodBindPtr = *
; GDExtensionInt = q (quad = 64-bit signed integer)
; GDExtensionBool = b or a (byte = 8-bit unsigned)
; GDObjectInstanceID = q (uint64_t)
; GDExtensionRefPtr = *
; GDExtensionConstRefPtr = *
; GDExtensionClassInstancePtr = *
; GDExtensionClassLibraryPtr = *
; GDExtensionScriptInstanceDataPtr = *
; GDExtensionScriptInstancePtr = *
; GDExtensionScriptLanguagePtr = *

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
  type.l  ; GDExtensionVariantType
  *name   ; GDExtensionStringNamePtr
  *class_name ; GDExtensionStringNamePtr
  hint.l  ; Bitfield of PropertyHint
  *hint_string ; GDExtensionStringPtr
  usage.l ; Bitfield of PropertyUsageFlags
EndStructure

Structure GDExtensionMethodInfo Align #PB_Structure_AlignC
  *name ; GDExtensionStringNamePtr
  return_value.GDExtensionPropertyInfo
  flags.l ; Bitfield of GDExtensionClassMethodFlags
  id.l
  argument_count.l
  *arguments ; GDExtensionPropertyInfo*
  default_argument_count.l
  *default_arguments ; GDExtensionVariantPtr*
EndStructure

Structure GDExtensionClassCreationInfo Align #PB_Structure_AlignC
  is_virtual.b ; GDExtensionBool
  is_abstract.b ; GDExtensionBool
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
  is_virtual.b ; GDExtensionBool
  is_abstract.b ; GDExtensionBool
  is_exposed.b ; GDExtensionBool
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
  is_virtual.b ; GDExtensionBool
  is_abstract.b ; GDExtensionBool
  is_exposed.b ; GDExtensionBool
  is_runtime.b ; GDExtensionBool
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
  is_virtual.b ; GDExtensionBool
  is_abstract.b ; GDExtensionBool
  is_exposed.b ; GDExtensionBool
  is_runtime.b ; GDExtensionBool
  *icon_path ; GDExtensionConstStringPtr
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

; GDExtensionClassCreationInfo5 is an alias for GDExtensionClassCreationInfo4
; In PureBasic, we can just use GDExtensionClassCreationInfo4

Structure GDExtensionClassMethodInfo Align #PB_Structure_AlignC
  *name ; GDExtensionStringNamePtr
  *method_userdata
  *call_func
  *ptrcall_func
  method_flags.l ; Bitfield
  has_return_value.b ; GDExtensionBool
  *return_value_info ; GDExtensionPropertyInfo*
  return_value_metadata.l ; GDExtensionClassMethodArgumentMetadata
  argument_count.l
  *arguments_info ; GDExtensionPropertyInfo*
  *arguments_metadata ; GDExtensionClassMethodArgumentMetadata*
  default_argument_count.l
  *default_arguments ; GDExtensionVariantPtr*
EndStructure

Structure GDExtensionClassVirtualMethodInfo Align #PB_Structure_AlignC
  *name ; GDExtensionStringNamePtr
  method_flags.l ; Bitfield
  return_value.GDExtensionPropertyInfo
  return_value_metadata.l ; GDExtensionClassMethodArgumentMetadata
  argument_count.l
  *arguments ; GDExtensionPropertyInfo*
  *arguments_metadata ; GDExtensionClassMethodArgumentMetadata*
EndStructure

Structure GDExtensionCallableCustomInfo Align #PB_Structure_AlignC
  *callable_userdata
  *token
  object_id.q ; GDObjectInstanceID
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
  object_id.q ; GDObjectInstanceID
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
  minimum_initialization_level.l ; GDExtensionInitializationLevel
  *userdata
  *initialize
  *deinitialize
EndStructure

Structure GDExtensionGodotVersion Align #PB_Structure_AlignC
  major.l
  minor.l
  patch.l
  *string ; const char*
EndStructure

Structure GDExtensionGodotVersion2 Align #PB_Structure_AlignC
  major.l
  minor.l
  patch.l
  hex.l ; Full version encoded as hexadecimal
  *status ; const char* (e.g. "stable", "beta", "rc1", "rc2")
  *build ; const char* (e.g. "custom_build")
  *hash_ ; const char* Full Git commit hash (renamed to avoid PureBasic keyword)
  timestamp.q ; Git commit date UNIX timestamp in seconds
  *string ; const char* (e.g. "Godot v3.1.4.stable.official.mono")
EndStructure

Structure GDExtensionMainLoopCallbacks Align #PB_Structure_AlignC
  *startup_func
  *shutdown_func
  *frame_func
EndStructure

;=============================================================================
; Function Pointer Prototypes
;=============================================================================

; Variant/Type conversion functions
Prototype GDExtensionVariantFromTypeConstructorFunc(*r_dest, *p_args)
Prototype GDExtensionTypeFromVariantConstructorFunc(*r_dest, *p_variant)
Prototype GDExtensionVariantGetInternalPtrFunc(*p_variant)

; Operator and method evaluators
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

; Utility function
Prototype GDExtensionPtrUtilityFunction(*r_return, *p_args, p_argument_count.l)

; Class functions
Prototype GDExtensionClassConstructor()
Prototype GDExtensionClassCreateInstance(*p_class_userdata)
Prototype GDExtensionClassCreateInstance2(*p_class_userdata, p_notify_postinitialize.b)
Prototype GDExtensionClassFreeInstance(*p_class_userdata, *p_instance)
Prototype GDExtensionClassRecreateInstance(*p_class_userdata, *p_object)
Prototype GDExtensionClassGetVirtual(*p_class_userdata, *p_name)
Prototype GDExtensionClassGetVirtual2(*p_class_userdata, *p_name, p_hash.l)
Prototype GDExtensionClassGetVirtualCallData(*p_class_userdata, *p_name)
Prototype GDExtensionClassGetVirtualCallData2(*p_class_userdata, *p_name, p_hash.l)
Prototype GDExtensionClassCallVirtual(*p_instance, *p_args, *r_ret)
Prototype GDExtensionClassCallVirtualWithData(*p_instance, *p_name, *p_virtual_call_userdata, *p_args, *r_ret)

; Instance binding callbacks
Prototype GDExtensionInstanceBindingCreateCallback(*p_token, *p_instance)
Prototype GDExtensionInstanceBindingFreeCallback(*p_token, *p_instance, *p_binding)
Prototype GDExtensionInstanceBindingReferenceCallback(*p_token, *p_binding, p_reference.b)

; Class property/get/set functions
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

; Method call functions
Prototype GDExtensionClassMethodCall(*method_userdata, *p_instance, *p_args, p_argument_count.q, *r_return, *r_error)
Prototype GDExtensionClassMethodValidatedCall(*method_userdata, *p_instance, *p_args, *r_return)
Prototype GDExtensionClassMethodPtrCall(*method_userdata, *p_instance, *p_args, *r_ret)

; Callable custom functions
Prototype GDExtensionCallableCustomCall(*callable_userdata, *p_args, p_argument_count.q, *r_return, *r_error)
Prototype GDExtensionCallableCustomIsValid(*callable_userdata)
Prototype GDExtensionCallableCustomFree(*callable_userdata)
Prototype GDExtensionCallableCustomHash(*callable_userdata)
Prototype GDExtensionCallableCustomEqual(*callable_userdata_a, *callable_userdata_b)
Prototype GDExtensionCallableCustomLessThan(*callable_userdata_a, *callable_userdata_b)
Prototype GDExtensionCallableCustomToString(*callable_userdata, *r_is_valid, *r_out)
Prototype GDExtensionCallableCustomGetArgumentCount(*callable_userdata, *r_is_valid)

; Script instance functions
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

; Worker thread pool functions
Prototype GDExtensionWorkerThreadPoolGroupTask(*userdata, p_element.l)
Prototype GDExtensionWorkerThreadPoolTask(*userdata)

; Editor callback
Prototype GDExtensionEditorGetClassesUsedCallback(*p_packed_string_array)

; Main loop callbacks
Prototype GDExtensionMainLoopStartupCallback()
Prototype GDExtensionMainLoopShutdownCallback()
Prototype GDExtensionMainLoopFrameCallback()

;=============================================================================
; Interface Function Pointer Prototypes
;=============================================================================

; Gets the Godot version that the GDExtension was loaded into (deprecated in 4.5)
Prototype GDExtensionInterfaceGetGodotVersion(*r_godot_version)

; Gets the Godot version that the GDExtension was loaded into (since 4.5)
Prototype GDExtensionInterfaceGetGodotVersion2(*r_godot_version)

; Memory allocation (deprecated in 4.6)
Prototype GDExtensionInterfaceMemAlloc(p_bytes.q)

; Memory reallocation (deprecated in 4.6)
Prototype GDExtensionInterfaceMemRealloc(*p_ptr, p_bytes.q)

; Memory free (deprecated in 4.6)
Prototype GDExtensionInterfaceMemFree(*p_ptr)

; Memory allocation (since 4.6)
Prototype GDExtensionInterfaceMemAlloc2(p_bytes.q, p_pad_align.b)

; Memory reallocation (since 4.6)
Prototype GDExtensionInterfaceMemRealloc2(*p_ptr, p_bytes.q, p_pad_align.b)

; Memory free (since 4.6)
Prototype GDExtensionInterfaceMemFree2(*p_ptr, p_pad_align.b)

; Error/warning printing
Prototype GDExtensionInterfacePrintError(*p_description, *p_function, *p_file, p_line.l, p_editor_notify.b)
Prototype GDExtensionInterfacePrintErrorWithMessage(*p_description, *p_message, *p_function, *p_file, p_line.l, p_editor_notify.b)
Prototype GDExtensionInterfacePrintWarning(*p_description, *p_function, *p_file, p_line.l, p_editor_notify.b)
Prototype GDExtensionInterfacePrintWarningWithMessage(*p_description, *p_message, *p_function, *p_file, p_line.l, p_editor_notify.b)
Prototype GDExtensionInterfacePrintScriptError(*p_description, *p_function, *p_file, p_line.l, p_editor_notify.b)
Prototype GDExtensionInterfacePrintScriptErrorWithMessage(*p_description, *p_message, *p_function, *p_file, p_line.l, p_editor_notify.b)

; Get native struct size
Prototype GDExtensionInterfaceGetNativeStructSize(*p_name)

; Variant operations
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
Prototype GDExtensionInterfaceVariantCanConvert(p_from.l, p_to.l)
Prototype GDExtensionInterfaceVariantCanConvertStrict(p_from.l, p_to.l)
Prototype GDExtensionInterfaceGetVariantFromTypeConstructor(p_type.l)
Prototype GDExtensionInterfaceGetVariantToTypeConstructor(p_type.l)
Prototype GDExtensionInterfaceGetVariantGetInternalPtrFunc(p_type.l)
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

; String operations
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

; StringName operations
Prototype GDExtensionInterfaceStringNameNewWithLatin1Chars(*r_dest, *p_contents, p_is_static.b)
Prototype GDExtensionInterfaceStringNameNewWithUtf8Chars(*r_dest, *p_contents)
Prototype GDExtensionInterfaceStringNameNewWithUtf8CharsAndLen(*r_dest, *p_contents, p_size.q)

; XML Parser
Prototype GDExtensionInterfaceXmlParserOpenBuffer(*p_instance, *p_buffer, p_size.q)

; FileAccess
Prototype GDExtensionInterfaceFileAccessStoreBuffer(*p_instance, *p_src, p_length.q)
Prototype GDExtensionInterfaceFileAccessGetBuffer(*p_instance, *p_dst, p_length.q)

; Image
Prototype GDExtensionInterfaceImagePtrw(*p_instance)
Prototype GDExtensionInterfaceImagePtr(*p_instance)

; Worker thread pool
Prototype GDExtensionInterfaceWorkerThreadPoolAddNativeGroupTask(*p_instance, *p_func, *p_userdata, p_elements.l, p_tasks.l, p_high_priority.b, *p_description)
Prototype GDExtensionInterfaceWorkerThreadPoolAddNativeTask(*p_instance, *p_func, *p_userdata, p_high_priority.b, *p_description)

; Packed array operators
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

; Array operations
Prototype GDExtensionInterfaceArrayOperatorIndex(*p_self, p_index.q)
Prototype GDExtensionInterfaceArrayOperatorIndexConst(*p_self, p_index.q)
Prototype GDExtensionInterfaceArrayRef(*p_self, *p_from)
Prototype GDExtensionInterfaceArraySetTyped(*p_self, p_type.l, *p_class_name, *p_script)

; Dictionary operations
Prototype GDExtensionInterfaceDictionaryOperatorIndex(*p_self, *p_key)
Prototype GDExtensionInterfaceDictionaryOperatorIndexConst(*p_self, *p_key)
Prototype GDExtensionInterfaceDictionarySetTyped(*p_self, p_key_type.l, *p_key_class_name, *p_key_script, p_value_type.l, *p_value_class_name, *p_value_script)

; Object operations
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

; Ref operations
Prototype GDExtensionInterfaceRefGetObject(*p_ref)
Prototype GDExtensionInterfaceRefSetObject(*p_ref, *p_object)

; Script instance operations
Prototype GDExtensionInterfaceScriptInstanceCreate(*p_info, *p_instance_data)
Prototype GDExtensionInterfaceScriptInstanceCreate2(*p_info, *p_instance_data)
Prototype GDExtensionInterfaceScriptInstanceCreate3(*p_info, *p_instance_data)
Prototype GDExtensionInterfacePlaceHolderScriptInstanceCreate(*p_language, *p_script, *p_owner)
Prototype GDExtensionInterfacePlaceHolderScriptInstanceUpdate(*p_placeholder, *p_properties, *p_values)
Prototype GDExtensionInterfaceObjectGetScriptInstance(*p_object, *p_language)
Prototype GDExtensionInterfaceObjectSetScriptInstance(*p_object, *p_script_instance)

; Callable custom operations
Prototype GDExtensionInterfaceCallableCustomCreate(*r_callable, *p_callable_custom_info)
Prototype GDExtensionInterfaceCallableCustomCreate2(*r_callable, *p_callable_custom_info)
Prototype GDExtensionInterfaceCallableCustomGetUserData(*p_callable, *p_token)

; ClassDB operations
Prototype GDExtensionInterfaceClassdbConstructObject(*p_classname)
Prototype GDExtensionInterfaceClassdbConstructObject2(*p_classname)
Prototype GDExtensionInterfaceClassdbGetMethodBind(*p_classname, *p_methodname, p_hash.q)
Prototype GDExtensionInterfaceClassdbGetClassTag(*p_classname)
Prototype GDExtensionInterfaceClassdbRegisterExtensionClass(*p_library, *p_class_name, *p_parent_class_name, *p_extension_funcs)
Prototype GDExtensionInterfaceClassdbRegisterExtensionClass2(*p_library, *p_class_name, *p_parent_class_name, *p_extension_funcs)
Prototype GDExtensionInterfaceClassdbRegisterExtensionClass3(*p_library, *p_class_name, *p_parent_class_name, *p_extension_funcs)
Prototype GDExtensionInterfaceClassdbRegisterExtensionClass4(*p_library, *p_class_name, *p_parent_class_name, *p_extension_funcs)
Prototype GDExtensionInterfaceClassdbRegisterExtensionClass5(*p_library, *p_class_name, *p_parent_class_name, *p_extension_funcs)
Prototype GDExtensionInterfaceClassdbRegisterExtensionClassMethod(*p_library, *p_class_name, *p_method_info)
Prototype GDExtensionInterfaceClassdbRegisterExtensionClassVirtualMethod(*p_library, *p_class_name, *p_method_info)
Prototype GDExtensionInterfaceClassdbRegisterExtensionClassIntegerConstant(*p_library, *p_class_name, *p_enum_name, *p_constant_name, p_constant_value.q, p_is_bitfield.b)
Prototype GDExtensionInterfaceClassdbRegisterExtensionClassProperty(*p_library, *p_class_name, *p_info, *p_setter, *p_getter)
Prototype GDExtensionInterfaceClassdbRegisterExtensionClassPropertyIndexed(*p_library, *p_class_name, *p_info, *p_setter, *p_getter, p_index.q)
Prototype GDExtensionInterfaceClassdbRegisterExtensionClassPropertyGroup(*p_library, *p_class_name, *p_group_name, *p_prefix)
Prototype GDExtensionInterfaceClassdbRegisterExtensionClassPropertySubgroup(*p_library, *p_class_name, *p_subgroup_name, *p_prefix)
Prototype GDExtensionInterfaceClassdbRegisterExtensionClassSignal(*p_library, *p_class_name, *p_signal_name, *p_argument_info, p_argument_count.q)
Prototype GDExtensionInterfaceClassdbUnregisterExtensionClass(*p_library, *p_class_name)

; Library and editor operations
Prototype GDExtensionInterfaceGetLibraryPath(*p_library, *r_path)
Prototype GDExtensionInterfaceEditorAddPlugin(*p_class_name)
Prototype GDExtensionInterfaceEditorRemovePlugin(*p_class_name)
Prototype GDExtensionsInterfaceEditorHelpLoadXmlFromUtf8Chars(*p_data)
Prototype GDExtensionsInterfaceEditorHelpLoadXmlFromUtf8CharsAndLen(*p_data, p_size.q)
Prototype GDExtensionInterfaceEditorRegisterGetClassesUsedCallback(*p_library, *p_callback)
Prototype GDExtensionInterfaceRegisterMainLoopCallbacks(*p_library, *p_callbacks)

;=============================================================================
; Entry point function type
;=============================================================================

; GDExtensionInterfaceFunctionPtr is just a generic function pointer
; GDExtensionInterfaceGetProcAddress returns such a pointer
Prototype GDExtensionInterfaceGetProcAddress(*p_function_name)

; The main entry point function that each GDExtension must implement
;Prototype.l GDExtensionInitializationFunction(*p_get_proc_address.G