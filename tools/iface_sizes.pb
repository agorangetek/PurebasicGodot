; Prints PureBasic's SizeOf for every structure gdextension_interface.pbi declares,
; so tools/check-interface.sh can compare them with the C header's sizeof.
IncludeFile "../gdextension_interface.pbi"
If OpenConsole() = 0 : End : EndIf
PrintN("GDExtensionCallError " + Str(SizeOf(GDExtensionCallError)))
PrintN("GDExtensionInstanceBindingCallbacks " + Str(SizeOf(GDExtensionInstanceBindingCallbacks)))
PrintN("GDExtensionPropertyInfo " + Str(SizeOf(GDExtensionPropertyInfo)))
PrintN("GDExtensionMethodInfo " + Str(SizeOf(GDExtensionMethodInfo)))
PrintN("GDExtensionClassCreationInfo " + Str(SizeOf(GDExtensionClassCreationInfo)))
PrintN("GDExtensionClassCreationInfo2 " + Str(SizeOf(GDExtensionClassCreationInfo2)))
PrintN("GDExtensionClassCreationInfo3 " + Str(SizeOf(GDExtensionClassCreationInfo3)))
PrintN("GDExtensionClassCreationInfo4 " + Str(SizeOf(GDExtensionClassCreationInfo4)))
PrintN("GDExtensionClassMethodInfo " + Str(SizeOf(GDExtensionClassMethodInfo)))
PrintN("GDExtensionClassVirtualMethodInfo " + Str(SizeOf(GDExtensionClassVirtualMethodInfo)))
PrintN("GDExtensionCallableCustomInfo " + Str(SizeOf(GDExtensionCallableCustomInfo)))
PrintN("GDExtensionCallableCustomInfo2 " + Str(SizeOf(GDExtensionCallableCustomInfo2)))
PrintN("GDExtensionScriptInstanceInfo " + Str(SizeOf(GDExtensionScriptInstanceInfo)))
PrintN("GDExtensionScriptInstanceInfo2 " + Str(SizeOf(GDExtensionScriptInstanceInfo2)))
PrintN("GDExtensionScriptInstanceInfo3 " + Str(SizeOf(GDExtensionScriptInstanceInfo3)))
PrintN("GDExtensionInitialization " + Str(SizeOf(GDExtensionInitialization)))
PrintN("GDExtensionGodotVersion " + Str(SizeOf(GDExtensionGodotVersion)))
PrintN("GDExtensionGodotVersion2 " + Str(SizeOf(GDExtensionGodotVersion2)))
PrintN("GDExtensionMainLoopCallbacks " + Str(SizeOf(GDExtensionMainLoopCallbacks)))
CloseConsole()
End
