; ===========================================================================
; gdex_ticker.pbi - GDTicker, a Node that counts frames.
;
; Registered at SCENE and also installed as the "GDNativeTicker" singleton, so
; the recovered gdexample.pb's InitializeModule/DeinitializeModule calls have
; something to register. Its `counter` is the value the Godot log printed:
;
;     Native singleton GDNativeTicker class = GDTicker | counter = 0.0
; ===========================================================================

Structure GDTicker
  GDBase.GDObject
  counter.d
  ; A PureBasic-managed member. This is the whole reason alloc_func and
  ; free_func exist: a List needs InitializeStructure, which raw
  ; AllocateMemory does not do. Without the AllocateStructure pair below,
  ; the first AddElement() on this list segfaults.
  List marks.l()
EndStructure

; The matching pair. AllocateStructure must be undone by FreeStructure -
; plain FreeMemory on that block crashes.
Procedure.i GDTicker_alloc()
  ProcedureReturn AllocateStructure(GDTicker)
EndProcedure

Procedure GDTicker_free(*p.GDTicker)
  FreeStructure(*p)
EndProcedure

Procedure GDTicker_constructor(*self.GDTicker)
  *self\counter = 0.0
  AddElement(*self\marks())
  *self\marks() = 0
EndProcedure

Procedure GDTicker_destructor(*self.GDTicker)
EndProcedure

Procedure.d GDTicker_get_counter(*self.GDTicker)
  ProcedureReturn *self\counter
EndProcedure

Procedure GDTicker_set_counter(*self.GDTicker, v.d)
  *self\counter = v
EndProcedure

Procedure GDTicker_bump(*self.GDTicker)
  *self\counter + 1.0
  ; Touch the PB-managed member so it is exercised, not just allocated.
  AddElement(*self\marks())
  *self\marks() = Round(*self\counter, #PB_Round_Nearest)
EndProcedure

Procedure.i GDTicker_get_mark_count(*self.GDTicker)
  ProcedureReturn ListSize(*self\marks())
EndProcedure

; Prints into Godot's log - the only output channel a dylib has. Proves the
; List is still intact at call time, from PureBasic.
Procedure GDTicker_announce(*self.GDTicker)
  Protected msg.s = "[GDTicker] counter=" + StrD(*self\counter, 2)
  msg + " marks=" + Str(ListSize(*self\marks()))
  msg + " last=" + Str(*self\marks())
  GDEX_Report(msg)
EndProcedure

Procedure GDTicker_reset(*self.GDTicker)
  *self\counter = 0.0
EndProcedure

; _process: advance the counter by the frame delta.
Procedure GDTicker_process(*self.GDTicker, delta.d)
  *self\counter + delta
EndProcedure

Procedure GDTicker_bind()
  ClassDB::bind_method(D_METHOD("get_counter"), @GDTicker_get_counter(), #FLOAT)
  ClassDB::bind_method(D_METHOD("set_counter", "counter"), @GDTicker_set_counter(), #VOID, #FLOAT)
  ClassDB::bind_method(D_METHOD("bump"), @GDTicker_bump())
  ClassDB::bind_method(D_METHOD("reset"), @GDTicker_reset())
  ClassDB::bind_method(D_METHOD("mark_count"), @GDTicker_get_mark_count(), #INT)
  ClassDB::bind_method(D_METHOD("announce"), @GDTicker_announce())
  ADD_PROPERTY(PropertyInfo(#FLOAT, "counter"), "set_counter", "get_counter")
EndProcedure

Global gdticker_class.GDClassInfo
gdticker_class\instance_size = SizeOf(GDTicker)
gdticker_class\constructor   = @GDTicker_constructor()
gdticker_class\destructor    = @GDTicker_destructor()
gdticker_class\process       = @GDTicker_process()
gdticker_class\bind_func     = @GDTicker_bind()
gdticker_class\alloc_func    = @GDTicker_alloc()
gdticker_class\free_func     = @GDTicker_free()
