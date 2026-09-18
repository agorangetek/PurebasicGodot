; ===========================================================================
; gdex_helpers.pbi - the hand-written helper layer, one include.
;
; Include it AFTER gdex_class.pbi (the ClassDB procedures drive the framework
; tables) and BEFORE your own classes (so their bind_func can call it):
;
;     IncludeFile "gdex_defs.pbi"
;     IncludeFile "gdex_api.pbi"
;     IncludeFile "generated/Node2D.pbi"      ; engine modules: Node2D::set_position
;     IncludeFile "generated/Object.pbi"
;     IncludeFile "gdex_class.pbi"
;     IncludeFile "generated/helpers/gdex_helpers.pbi"
;     IncludeFile "myclass.pbi"
;
; It gives a class surface the same spelling godot-cpp has:
;
;   ClassDB::bind_method(D_METHOD("get_amplitude"), @GDExample_get_amplitude(), #FLOAT)
;   ADD_PROPERTY(PropertyInfo(#FLOAT, "amplitude"), "set_amplitude", "get_amplitude")
;   ADD_SIGNAL(MethodInfo("position_changed", PropertyInfo(#VECTOR2, "new_position")))
;   emit_signal(*self, "position_changed", @new_position)
;   Node2D::set_position(*self, @new_position)
;
;   gdex_variant.pbi   any native value <-> Variant, one pair of procedures
;   gdex_signal.pbi    emit_signal, typed from the signal's own declaration
;   gdex_classdb.pbi   ClassDB::bind_method / add_property / add_signal
;   gdex_macros.pbi    D_METHOD, PropertyInfo, MethodInfo, ADD_*, GDREGISTER_CLASS
;
; This folder is the one hand-written thing under generated/. Everything else
; there is generator output. generate-bindings.sh writes these files if they
; are missing and never overwrites them.
; ===========================================================================

IncludeFile "gdex_variant.pbi"
IncludeFile "gdex_classdb.pbi"
IncludeFile "gdex_signal.pbi"
IncludeFile "gdex_macros.pbi"
