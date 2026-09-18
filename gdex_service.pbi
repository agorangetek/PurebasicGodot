; ===========================================================================
; gdex_service.pbi - GDService, an Object-derived singleton.
;
; This is the last thing the Aug-27 build added, and the only one whose
; behaviour is on the record - the Godot log for the demo says:
;
;     GDService singleton class = GDService | counter = 0.0
;     GDService counter after bump+set: 41.5
;
; so it carries a float `counter`, a `bump()` that advances it, and enough of
; a default that a fresh instance reads 0.0. It is registered at CORE level,
; before the editor scans scripts, which is what makes the name available to
; GDScript as a global.
; ===========================================================================

Structure GDService
  GDBase.GDObject
  counter.d
EndStructure

Procedure GDService_constructor(*self.GDService)
  *self\counter = 0.0
EndProcedure

Procedure GDService_destructor(*self.GDService)
EndProcedure

Procedure.d GDService_get_counter(*self.GDService)
  ProcedureReturn *self\counter
EndProcedure

Procedure GDService_set_counter(*self.GDService, v.d)
  *self\counter = v
EndProcedure

Procedure GDService_bump(*self.GDService)
  *self\counter + 1.0
EndProcedure

Procedure GDService_reset(*self.GDService)
  *self\counter = 0.0
EndProcedure

Procedure GDService_bind()
  ClassDB::bind_method(D_METHOD("get_counter"), @GDService_get_counter(), #FLOAT)
  ClassDB::bind_method(D_METHOD("set_counter", "counter"), @GDService_set_counter(), #VOID, #FLOAT)
  ClassDB::bind_method(D_METHOD("bump"), @GDService_bump())
  ClassDB::bind_method(D_METHOD("reset"), @GDService_reset())
  ADD_PROPERTY(PropertyInfo(#FLOAT, "counter"), "set_counter", "get_counter")
EndProcedure

Global gdservice_class.GDClassInfo
gdservice_class\instance_size = SizeOf(GDService)
gdservice_class\constructor   = @GDService_constructor()
gdservice_class\destructor    = @GDService_destructor()
gdservice_class\bind_func     = @GDService_bind()
