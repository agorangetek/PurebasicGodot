; ===========================================================================
; gdex_macros.pbi - the spelling of godot-cpp's registration macros.
;
; PureBasic macros substitute whole tokens only - they cannot join two tokens
; into one identifier - so these exist to turn C++'s argument lists into
; PureBasic's flat ones, nothing more:
;
;     D_METHOD("set_amplitude", "amplitude")   ->  "set_amplitude", "amplitude", "", ""
;     PropertyInfo(#FLOAT, "amplitude")        ->  #FLOAT, "amplitude"

; PropertyInfo and MethodInfo do not produce a value - PureBasic has none to
; produce - they only splice the type and name into the enclosing call.
; ===========================================================================

; A method's name followed by up to three argument names.
Macro D_METHOD(Name, A1 = "", A2 = "", A3 = "")
  Name, A1, A2, A3
EndMacro

; A type and a name, spliced into ADD_PROPERTY or ADD_SIGNAL.
Macro PropertyInfo(Type, Name)
  Type, Name
EndMacro

; ADD_PROPERTY(PropertyInfo(#FLOAT, "amplitude"), "set_amplitude", "get_amplitude")
Macro ADD_PROPERTY(Info, Setter, Getter)
  ClassDB::add_property(Info, Setter, Getter)
EndMacro

; ADD_SIGNAL("bounced", #VECTOR2, "position")
; ADD_SIGNAL("plain")
; ADD_SIGNAL("pair", #INT, "a", #FLOAT, "b")
;
; The type/name pairs are written out rather than wrapped in a MethodInfo(...)
; macro. PureBasic expands an inner macro while it is still parsing the outer
; one's arguments, so ADD_SIGNAL(MethodInfo("bounced", PropertyInfo(...))) is
; two levels of nesting and does not survive - the argument count comes out
; wrong however the two macros are written. One level, as ADD_PROPERTY uses
; below, is fine.
Macro ADD_SIGNAL(Name, T0 = 0, N0 = "", T1 = 0, N1 = "", T2 = 0, N2 = "", T3 = 0, N3 = "")
  ClassDB::add_signal(Name, T0, N0, T1, N1, T2, N2, T3, N3)
EndMacro

; GDREGISTER_CLASS(descriptor, "Name", "Parent")
;
; godot-cpp's GDREGISTER_CLASS(GDExample) is a static initialiser and runs when
; the library loads. PureBasic has no static initialisers - a call cannot
; happen at file scope - so this goes in the extension's initialize callback,
; where registration has to happen anyway because the level matters (a scene
; class cannot be registered at CORE).
Macro GDREGISTER_CLASS(Descriptor, Name, Parent)
  RegisterGDClass(@Descriptor, Name, Parent)
EndMacro

; GDREGISTER_SINGLETON(descriptor, "Name", "Parent" [, "SingletonName"])
;
; A singleton is an INSTANCE of a class, so this registers both: the class
; (a type in ClassDB, at the level its parent needs) and then one instance of
; it handed to Engine.register_singleton. One line instead of two, and the
; descriptor is named once - you cannot register a singleton of a class you
; forgot to register.
;
; The 4th argument is only needed when the singleton is named differently from
; the class, as GDTicker is to "GDNativeTicker".
Macro GDREGISTER_SINGLETON(Descriptor, Name, Parent, SingletonName = "")
  GDEX_RegisterSingletonClass(@Descriptor, Name, Parent, SingletonName)
EndMacro

; GDEX_EXTENSION(entry_symbol)
;
; Defines the ProcedureCDLL Godot dlopens and calls, pointed at the framework's
; level handling. The symbol must match entry_symbol in the .gdextension file.
; A PureBasic macro can name a procedure from a whole-token parameter, which is
; why this is one line instead of the fifteen it replaces.
Macro GDEX_EXTENSION(InitSymbol)
  ProcedureCDLL.a InitSymbol(*p_get_proc_address, *p_library, *r_initialization)
    GDExtensionClassLibraryPtr = *p_library
    load_api(*p_get_proc_address)
    Protected *ri.GDExtensionInitialization = *r_initialization
    *ri\minimum_initialization_level = #GDEXTENSION_INITIALIZATION_CORE
    *ri\userdata = 0
    *ri\initialize = @GDEX_Initialize()
    *ri\deinitialize = @GDEX_Deinitialize()
    ProcedureReturn 1
  EndProcedure
EndMacro
