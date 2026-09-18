; ===========================================================================
; gdex_classdb.pbi - ClassDB::bind_method / add_property / add_signal.
;
; The spelling is godot-cpp's and the `::` is real: ClassDB is a PureBasic
; module. All three run from a class's bind_func (its _bind_methods), which the
; framework calls with gdex_current pointing at the descriptor being registered.
;
; A module is a black box - it cannot see main-code procedures, structures or
; globals - so these procedures do no work themselves. The work lives in
; gdex_class.pbi outside any module, and the module holds the ADDRESSES of
; those procedures in globals of its own, which main code writes from outside:
;
;     ClassDB::bind_method_fn = @GDEX_BindMethodImpl()
;
; That direction works because a module's public globals are writable from
; outside via `::`. Each call here is one indirect jump.
;
; The pointers are Integer globals rather than Prototype-typed ones on purpose:
; a module can read an Integer, but a Prototype-typed global's TYPE is not
; visible inside the module, so the name would not resolve at all.
;
; One thing bind_method must say that godot-cpp does not: C++ reads the
; argument and return types off the member function pointer it is handed, and a
; PureBasic procedure pointer carries no signature. So the types are passed
; explicitly, using the same #FLOAT / #VECTOR2 / #VOID constants that
; PropertyInfo and ADD_SIGNAL use. The trailing types are
; (return, arg0, arg1, arg2, arg3), and a method may declare up to four
; arguments - past that the callee could not name them anyway.
;
; The default values below are the literals 0 and -1 rather than #VOID and
; #GDEX_NO_TYPE: PureBasic folds a declared procedure's defaults in the same
; early pass as DeclareModule, before user constants exist, so a constant there
; is "Constant not found". They mean the same thing.
; ===========================================================================

DeclareModule ClassDB
  ; Written from outside, once, by the bottom of this file.
  Global bind_method_fn.i
  Global add_property_fn.i
  Global add_signal_fn.i
  Global bind_vararg_fn.i

  Prototype BindMethodFn(Name.s, A1.s, A2.s, A3.s, A4.s, Proc.i, RetType.l, Arg0.l, Arg1.l, Arg2.l, Arg3.l)
  Prototype AddPropertyFn(PropType.l, PropName.s, SetterName.s, GetterName.s)
  Prototype AddSignalFn(SigName.s, T0.l, N0.s, T1.l, N1.s, T2.l, N2.s, T3.l, N3.s)
  Prototype BindVarargFn(Name.s, A1.s, A2.s, A3.s, A4.s, Proc.i, RetType.l)

  Declare bind_method(Name.s, A1.s = "", A2.s = "", A3.s = "", A4.s = "", Proc.i = 0, RetType.l = 0, Arg0.l = -1, Arg1.l = -1, Arg2.l = -1, Arg3.l = -1)
  Declare add_property(PropType.l, PropName.s, SetterName.s, GetterName.s)
  Declare bind_vararg(Name.s, A1.s = "", A2.s = "", A3.s = "", A4.s = "", Proc.i = 0, RetType.l = 0)
  Declare add_signal(SigName.s, T0.l = 0, N0.s = "", T1.l = 0, N1.s = "", T2.l = 0, N2.s = "", T3.l = 0, N3.s = "")
EndDeclareModule

Module ClassDB
  EnableExplicit

  ; ClassDB::bind_method(D_METHOD("set_amplitude", "amplitude"), @GDExample_set_amplitude(), #VOID, #FLOAT)
  Procedure bind_method(Name.s, A1.s = "", A2.s = "", A3.s = "", A4.s = "", Proc.i = 0, RetType.l = 0, Arg0.l = -1, Arg1.l = -1, Arg2.l = -1, Arg3.l = -1)
    Protected f.BindMethodFn = bind_method_fn
    f(Name, A1, A2, A3, A4, Proc, RetType, Arg0, Arg1, Arg2, Arg3)
  EndProcedure

  ; ClassDB::bind_vararg(D_METHOD("sum"), @GDExample_sum(), #FLOAT)
  Procedure bind_vararg(Name.s, A1.s = "", A2.s = "", A3.s = "", A4.s = "", Proc.i = 0, RetType.l = 0)
    Protected f.BindVarargFn = bind_vararg_fn
    f(Name, A1, A2, A3, A4, Proc, RetType)
  EndProcedure

  ; ADD_PROPERTY(PropertyInfo(#FLOAT, "amplitude"), "set_amplitude", "get_amplitude")
  Procedure add_property(PropType.l, PropName.s, SetterName.s, GetterName.s)
    Protected f.AddPropertyFn = add_property_fn
    f(PropType, PropName, SetterName, GetterName)
  EndProcedure

  ; ADD_SIGNAL("bounced", #VECTOR2, "position")
  Procedure add_signal(SigName.s, T0.l = 0, N0.s = "", T1.l = 0, N1.s = "", T2.l = 0, N2.s = "", T3.l = 0, N3.s = "")
    Protected f.AddSignalFn = add_signal_fn
    f(SigName, T0, N0, T1, N1, T2, N2, T3, N3)
  EndProcedure
EndModule

; ---------------------------------------------------------------------------
; The injection. The implementations are in gdex_class.pbi, which is included
; before this file, and they are what actually touch the framework tables.
; ---------------------------------------------------------------------------
ClassDB::bind_method_fn  = @GDEX_BindMethodImpl()
ClassDB::add_property_fn = @GDEX_AddPropertyImpl()
ClassDB::add_signal_fn   = @GDEX_AddSignalImpl()
ClassDB::bind_vararg_fn  = @GDEX_BindVarargImpl()
