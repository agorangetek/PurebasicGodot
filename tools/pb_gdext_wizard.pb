; ===========================================================================
; tools/gen_binds.pb - generate PureBasic method-bind plumbing for Godot
; engine classes, from Godot's own extension_api.json.
;
;     extension_api.json  ->  generated/<Class>.pbi
;
; Written in PureBasic so the whole project is one toolchain: pbcompiler
; builds the extension AND the generator that writes part of it.
;
; Godot publishes everything needed in extension_api.json: for every class,
; every method, its `hash` and its fully typed argument/return list.
;
; WHY THE OUTPUT IS SMALL
; godot-cpp generates a typed C++ wrapper per method because C++ needs one
; callable symbol per signature. PureBasic does not: a bind is resolved at
; runtime and invoked through object_method_bind_ptrcall() with an array of
; argument pointers. So the generated code is mostly *data* - a bind global
; per method - plus a typed wrapper for the signatures we can express.
;
; USAGE
;     ./gen_binds --classes Node Node2D --out generated/Node2D.pbi
;     ./gen_binds --check generated/*.pbi
;     ./gen_binds --stats
;
; TWO PURBASIC RULES THIS FILE ITSELF OBEYS, both learned the hard way:
;   * structures are passed BY POINTER only (`Procedure Foo(v.Vec)` is a
;     syntax error) - hence *mi.MethodInfo everywhere below;
;   * there is no line continuation, so long expressions are built up over
;     several statements instead of wrapping.
; ===========================================================================

EnableExplicit

#OUT_EQUALS = 73

; ---------------------------------------------------------------------------
; TYPE MAP - Godot type -> PureBasic type. Scalars go by value, structures by
; pointer. A type absent here gets a bind but no typed wrapper.
; ---------------------------------------------------------------------------

Structure TypeMap
  godot.s
  pb.s
EndStructure

Global Dim gTypeMap.TypeMap(19)

Procedure InitTypeMap()

  gTypeMap(0)\godot = "float"        : gTypeMap(0)\pb = "d"
  gTypeMap(1)\godot = "int"          : gTypeMap(1)\pb = "i"
  gTypeMap(2)\godot = "bool"         : gTypeMap(2)\pb = "l"
  ; RID is a single uint64 handle - 8 bytes in every build config - so it
  ; travels as a scalar. A struct would mean a by-value structure
  ; parameter, which PureBasic rejects outright.
  gTypeMap(3)\godot = "RID"          : gTypeMap(3)\pb = "i"
  gTypeMap(4)\godot = "Vector2"      : gTypeMap(4)\pb = "GDVector2"
  gTypeMap(5)\godot = "Vector2i"     : gTypeMap(5)\pb = "GDVector2i"
  gTypeMap(6)\godot = "Rect2"        : gTypeMap(6)\pb = "GDRect2"
  gTypeMap(7)\godot = "Rect2i"       : gTypeMap(7)\pb = "GDRect2i"
  gTypeMap(8)\godot = "Vector3"      : gTypeMap(8)\pb = "GDVector3"
  gTypeMap(9)\godot = "Vector3i"     : gTypeMap(9)\pb = "GDVector3i"
  gTypeMap(10)\godot = "Vector4"     : gTypeMap(10)\pb = "GDVector4"
  gTypeMap(11)\godot = "Color"       : gTypeMap(11)\pb = "GDColor"
  gTypeMap(12)\godot = "Plane"       : gTypeMap(12)\pb = "GDPlane"
  gTypeMap(13)\godot = "Quaternion"  : gTypeMap(13)\pb = "GDQuaternion"
  gTypeMap(14)\godot = "AABB"        : gTypeMap(14)\pb = "GDAABB"
  gTypeMap(15)\godot = "Basis"       : gTypeMap(15)\pb = "GDBasis"
  gTypeMap(16)\godot = "Transform2D" : gTypeMap(16)\pb = "GDTransform2D"
  gTypeMap(17)\godot = "Transform3D" : gTypeMap(17)\pb = "GDTransform3D"
  gTypeMap(18)\godot = "Projection"  : gTypeMap(18)\pb = "GDProjection"
  gTypeMap(19)\godot = ""            : gTypeMap(19)\pb = ""
EndProcedure

Procedure.s PbTypeOf(gtype.s)
  If gtype = ""
    ProcedureReturn ""
  EndIf
  If Left(gtype, 6) = "enum::"
    ProcedureReturn "i"
  EndIf
  Protected i
  For i = 0 To 19
    If gTypeMap(i)\godot = gtype
      ProcedureReturn gTypeMap(i)\pb
    EndIf
  Next
  ProcedureReturn ""
EndProcedure

Procedure.l IsStructPb(pb.s)
  Select pb
    Case "GDVector2", "GDVector2i", "GDRect2", "GDRect2i"
      ProcedureReturn #True
    Case "GDVector3", "GDVector3i", "GDVector4", "GDColor"
      ProcedureReturn #True
    Case "GDPlane", "GDQuaternion", "GDAABB", "GDBasis"
      ProcedureReturn #True
    Case "GDTransform2D", "GDTransform3D", "GDProjection"
      ProcedureReturn #True
  EndSelect
  ProcedureReturn #False
EndProcedure

; Literal byte sizes, because a wrapper lives inside its class module and the
; module cannot see the main-scope GD* structure declarations - so SizeOf()
; cannot be used there. These are the only types a wrapper can return, and the
; numbers are Godot's own for the float_64 / 64-bit-pointer configuration.
Procedure.i StructSize(pb.s)
  Select pb
    Case "GDVector2", "GDVector2i"
      ProcedureReturn 8
    Case "GDRect2", "GDRect2i", "GDVector4", "GDColor"
      ProcedureReturn 16
    Case "GDPlane", "GDQuaternion"
      ProcedureReturn 16
    Case "GDVector3", "GDVector3i"
      ProcedureReturn 12
    Case "GDAABB"
      ProcedureReturn 24
    Case "GDBasis"
      ProcedureReturn 36
    Case "GDTransform2D"
      ProcedureReturn 24
    Case "GDTransform3D"
      ProcedureReturn 48
    Case "GDProjection"
      ProcedureReturn 64
  EndSelect
  ProcedureReturn 0
EndProcedure

; Inside its own class module a wrapper carries the bare Godot method name, so
; names that are PureBasic keywords take a leading underscore. All 7539 unique
; wrappable method names were measured against the compiler (a Declare plus a
; Procedure inside a DeclareModule); these four are the only ones that collide.
; Parameter names are prefixed p_ and so never need this treatment - they
; cannot appear at a call site anyway.
Procedure.s WrapperName(mn.s)
  Select mn
    Case "debug", "next", "read", "select"
      ProcedureReturn "_" + mn
  EndSelect
  ProcedureReturn mn
EndProcedure

; ---------------------------------------------------------------------------
; SMALL UTILITIES
; ---------------------------------------------------------------------------

Procedure.s Ident(s.s)
  Protected r.s = ""
  Protected i, ch
  For i = 1 To Len(s)
    ch = Asc(Mid(s, i, 1))
    If (ch >= 'a' And ch <= 'z') Or (ch >= 'A' And ch <= 'Z') Or (ch >= '0' And ch <= '9') Or ch = '_'
      r + Chr(ch)
    Else
      r + "_"
    EndIf
  Next
  ProcedureReturn r
EndProcedure

Procedure Add(List Lines.s(), s.s)
  If ListSize(Lines()) = 0
    AddElement(Lines())
  Else
    LastElement(Lines())
    AddElement(Lines())
  EndIf
  Lines() = s
EndProcedure

Procedure.l Has(List l.s(), v.s)
  Protected n = ListSize(l()), i
  For i = 0 To n - 1
    SelectElement(l(), i)
    If l() = v
      ProcedureReturn #True
    EndIf
  Next
  ProcedureReturn #False
EndProcedure

Procedure.s BaseName(path.s)
  Protected i = Len(path)
  While i > 0
    If Mid(path, i, 1) = "/"
      Break
    EndIf
    i - 1
  Wend
  ProcedureReturn Mid(path, i + 1)
EndProcedure

; ---------------------------------------------------------------------------
; JSON ACCESS. A missing member reads back as 0, which is #PB_JSON_Null, so
; every accessor guards - an unguarded JSONArraySize(0) segfaults.
; ---------------------------------------------------------------------------

Global gJson.s
Global gRoot
Global gClasses
Global NewMap gClassIdx.i()
Global NewMap gHash.i()
Global gClassCount.l = 0
Global gMethodCount.l = 0

Procedure.s JGStr(v, key.s)
  Protected m = GetJSONMember(v, key)
  If m = 0 Or JSONType(m) <> #PB_JSON_String
    ProcedureReturn ""
  EndIf
  ProcedureReturn GetJSONString(m)
EndProcedure

Procedure.q JGInt(v, key.s, def.q = 0)
  Protected m = GetJSONMember(v, key)
  If m = 0 Or JSONType(m) <> #PB_JSON_Number
    ProcedureReturn def
  EndIf
  ProcedureReturn GetJSONInteger(m)
EndProcedure

Procedure JGArr(v, key.s)
  Protected m = GetJSONMember(v, key)
  If m = 0 Or JSONType(m) <> #PB_JSON_Array
    ProcedureReturn 0
  EndIf
  ProcedureReturn m
EndProcedure

Procedure.l JGBool(v, key.s)
  Protected m = GetJSONMember(v, key)
  If m = 0
    ProcedureReturn #False
  EndIf
  ProcedureReturn GetJSONBoolean(m)
EndProcedure

; A type is either a string ("Vector2") or an object ({"class_name": "Node"}).
Procedure.s JTypeOf(entry)
  Protected t = GetJSONMember(entry, "type")
  If t = 0
    ProcedureReturn ""
  EndIf
  If JSONType(t) = #PB_JSON_String
    ProcedureReturn GetJSONString(t)
  EndIf
  If JSONType(t) = #PB_JSON_Object
    ProcedureReturn JGStr(t, "class_name")
  EndIf
  ProcedureReturn ""
EndProcedure

Procedure.s ReadWhole(path.s)
  Protected f = ReadFile(#PB_Any, path)
  If Not f
    ProcedureReturn ""
  EndIf
  Protected size.q = Lof(f)
  Protected *buf = AllocateMemory(size + 1)
  If Not *buf
    CloseFile(f)
    ProcedureReturn ""
  EndIf
  ReadData(f, *buf, size)
  CloseFile(f)
  PokeB(*buf + size, 0)
  Protected s.s = PeekS(*buf, size, #PB_UTF8)
  FreeMemory(*buf)
  ProcedureReturn s
EndProcedure

Procedure.l FileExists(path.s)
  ProcedureReturn Bool(FileSize(path) >= 0)
EndProcedure

; Write only when the bytes differ. Regenerating a library of a thousand
; files should not touch the timestamps of the ones that did not change.
Procedure.l WriteIfChanged(path.s, text.s)
  If ReadWhole(path) = text
    ProcedureReturn #False
  EndIf
  Protected f = CreateFile(#PB_Any, path)
  If Not f
    PrintN("cannot write " + path)
    End 1
  EndIf
  WriteString(f, text, #PB_UTF8)
  CloseFile(f)
  ProcedureReturn #True
EndProcedure

Procedure.s JoinLines(List Lines.s())
  Protected text.s = ""
  Protected i
  For i = 0 To ListSize(Lines()) - 1
    If i > 0
      text + #LF$
    EndIf
    SelectElement(Lines(), i)
    text + Lines()
  Next
  ProcedureReturn text
EndProcedure

Procedure LoadApi(path.s)
  gJson = ReadWhole(path)
  If gJson = ""
    PrintN("cannot open " + path)
    End 1
  EndIf

  If ParseJSON(0, gJson) = 0
    PrintN("cannot parse " + path)
    End 1
  EndIf
  gRoot = JSONValue(0)
  gClasses = JGArr(gRoot, "classes")

  Protected n = JSONArraySize(gClasses)
  Protected i, c, methods, j, m
  For i = 0 To n - 1
    c = GetJSONElement(gClasses, i)
    If JSONType(c) <> #PB_JSON_Object
      Continue
    EndIf
    Protected nm.s = JGStr(c, "name")
    If nm = ""
      Continue
    EndIf
    gClassIdx(nm) = i
    gClassCount + 1

    methods = JGArr(c, "methods")
    If methods
      Protected mc = JSONArraySize(methods)
      gMethodCount + mc
      For j = 0 To mc - 1
        m = GetJSONElement(methods, j)
        gHash(nm + "." + JGStr(m, "name")) = JGInt(m, "hash", -1)
      Next
    EndIf
  Next
EndProcedure

Procedure.s ClassInherits(name.s)
  If Not FindMapElement(gClassIdx(), name)
    ProcedureReturn ""
  EndIf
  ProcedureReturn JGStr(GetJSONElement(gClasses, gClassIdx()), "inherits")
EndProcedure

; ---------------------------------------------------------------------------
; A METHOD, flattened out of the JSON so the emitters can share it.
; Fixed-size arrays on purpose: a structure holding a dynamic Array cannot sit
; inside a Dim'd array without each element being initialised by hand.
; ---------------------------------------------------------------------------

Structure MethodInfo
  name.s
  hash.q
  isConst.l
  isStatic.l
  isVararg.l
  argName.s[16]
  argGodot.s[16]
  argPb.s[16]
  argCount.l
  retGodot.s
  retPb.s
  wrappable.l
  skipWhy.s
EndStructure

Procedure ReadMethod(m, *mi.MethodInfo)
  *mi\name = JGStr(m, "name")
  *mi\hash = JGInt(m, "hash", -1)
  *mi\isConst = JGBool(m, "is_const")
  *mi\isStatic = JGBool(m, "is_static")
  *mi\isVararg = JGBool(m, "is_vararg")
  *mi\argCount = 0
  *mi\retGodot = ""
  *mi\retPb = ""
  *mi\skipWhy = ""

  Protected args = JGArr(m, "arguments")
  If args
    Protected n = JSONArraySize(args)
    Protected i, a, an.s
    For i = 0 To n - 1
      If i > 15
        Break
      EndIf
      a = GetJSONElement(args, i)
      an = JGStr(a, "name")
      If an = ""
        an = "arg" + Str(i)
      EndIf
      *mi\argName[i] = Ident(an)
      *mi\argGodot[i] = JTypeOf(a)
      *mi\argPb[i] = PbTypeOf(*mi\argGodot[i])
      *mi\argCount + 1
    Next
  EndIf

  Protected rv = GetJSONMember(m, "return_value")
  If rv And JSONType(rv) = #PB_JSON_Object
    *mi\retGodot = JTypeOf(rv)
    *mi\retPb = PbTypeOf(*mi\retGodot)
  EndIf

  ; Decidable without Godot, so decided once, here.
  *mi\wrappable = #True
  Protected why.s = ""
  If *mi\isVararg
    *mi\wrappable = #False
    why = "vararg"
  Else
    ; The FIRST cause only, exactly as the reference implementation reports
    ; it: argument problems hide a return problem rather than joining it.
    Protected i2, badArgs.s = "", badCount.l = 0
    For i2 = 0 To *mi\argCount - 1
      If *mi\argPb[i2] = ""
        If badCount > 0
          badArgs + ", "
        EndIf
        badArgs + *mi\argGodot[i2]
        badCount + 1
      EndIf
    Next
    If badCount > 0
      *mi\wrappable = #False
      why = "argument type(s) " + badArgs
    ElseIf *mi\retGodot <> "" And *mi\retPb = ""
      *mi\wrappable = #False
      why = "return type " + *mi\retGodot
    EndIf
  EndIf
  *mi\skipWhy = Trim(why)
EndProcedure

; ---------------------------------------------------------------------------
; EMISSION
; ---------------------------------------------------------------------------

; The return-type suffix of the Procedure/Declare line. A structure result has
; no suffix: it comes back through an untyped *out parameter instead.
Procedure.s WrapperRet(*mi.MethodInfo)
  If *mi\retPb = "d"
    ProcedureReturn ".d"
  ElseIf *mi\retPb = "i"
    ProcedureReturn ".i"
  ElseIf *mi\retPb = "l"
    ProcedureReturn ".l"
  EndIf
  ProcedureReturn ""
EndProcedure

; The wrapper's parameter list, shared by its Declare and its Procedure so the
; two can never drift apart. *self is untyped - the Godot object is the first
; field of the instance and is read with PeekI(*self). A structure argument is
; an untyped pointer (the type name is not visible inside the module); a scalar
; keeps its type; a structure result arrives through an untyped *out.
Procedure.s WrapperParams(*mi.MethodInfo)
  Protected p.s = "*self"
  Protected i
  For i = 0 To *mi\argCount - 1
    If IsStructPb(*mi\argPb[i])
      p + ", *p_" + *mi\argName[i]
    Else
      p + ", p_" + *mi\argName[i] + "." + *mi\argPb[i]
    EndIf
  Next
  If IsStructPb(*mi\retPb)
    p + ", *out"
  EndIf
  ProcedureReturn p
EndProcedure

Procedure EmitWrapper(List Lines.s(), cls.s, *mi.MethodInfo)
  Protected mn.s = Ident(*mi\name)
  Protected proc.s = WrapperName(mn)
  Protected desc.s, i

  ; Types only, with the Godot method name: the generated parameter name is a
  ; module-side detail (p_<name>), and this comment is now the only place a
  ; wrapper's argument types are written down.
  For i = 0 To *mi\argCount - 1
    If i > 0
      desc + ", "
    EndIf
    desc + *mi\argGodot[i]
  Next

  Protected head.s = "  ; " + cls + "." + *mi\name + "(" + desc + ")"
  If *mi\retGodot <> ""
    head + " -> " + *mi\retGodot
  EndIf
  Protected flags.s = ""
  If *mi\isConst
    flags + "const "
  EndIf
  If *mi\isStatic
    flags + "static "
  EndIf
  head + "   [" + flags + "hash " + Str(*mi\hash) + "]"
  Add(Lines(), head)

  ; Signature. Structures go by pointer; a structure result arrives through a
  ; caller-provided *out because PureBasic cannot return one by value.
  ;
  ; Parameter names are PREFIXED, and that is not cosmetic: Godot has arguments
  ; called step, data, next, default, debug, with, string, array, object,
  ; constant, align, ... - around thirty of them are PureBasic keywords and
  ; cannot be used as a variable name at all. Parameter names never appear at a
  ; call site, so prefixing costs nothing and removes the whole class of
  ; collision rather than chasing a keyword list.
  Protected structRet.l = IsStructPb(*mi\retPb)
  Add(Lines(), "  Procedure" + WrapperRet(*mi) + " " + proc + "(" + WrapperParams(*mi) + ")")

  Protected bind.s = "gdb_" + mn
  If structRet
    Add(Lines(), "    FillMemory(*out, " + Str(StructSize(*mi\retPb)) + ", 0)")
  EndIf
  ; ptr_ptrcall is the module's own copy of the interface address, and report_fn
  ; the framework's unresolved-bind reporter; PeekI(*self) is the Godot object
  ; pointer, because GDObject\object is the first field of every instance.
  ;
  ; The two conditions are kept apart on purpose. A null instance is an ordinary
  ; runtime condition and stays silent. A missing bind is a SETUP mistake - the
  ; class was included but Register_<Class>_Binds() was never called, so every
  ; wrapper in this module is dead - and that is worth saying out loud, once.
  Protected retLine.s
  If structRet Or *mi\retPb = ""
    retLine = "      ProcedureReturn"
  ElseIf *mi\retPb = "d"
    retLine = "      ProcedureReturn 0.0"
  Else
    retLine = "      ProcedureReturn 0"
  EndIf

  Add(Lines(), "    If Not " + bind + " Or Not ptr_ptrcall")
  Add(Lines(), "      Protected rf.LocalReportFn = report_fn")
  Add(Lines(), "      If rf")
  Add(Lines(), "        rf(" + Chr(34) + cls + Chr(34) + ", " + Chr(34) + *mi\name + Chr(34) + ")")
  Add(Lines(), "      EndIf")
  Add(Lines(), retLine)
  Add(Lines(), "    EndIf")
  Add(Lines(), "    If Not *self Or Not PeekI(*self)")
  Add(Lines(), retLine)
  Add(Lines(), "    EndIf")
  Add(Lines(), "    Protected pc.LocalPtrcallFn = ptr_ptrcall")

  If *mi\argCount > 0
    Add(Lines(), "    Protected Dim ap.i(" + Str(*mi\argCount - 1) + ")")
    For i = 0 To *mi\argCount - 1
      If IsStructPb(*mi\argPb[i])
        Add(Lines(), "    ap(" + Str(i) + ") = *p_" + *mi\argName[i])
      Else
        Add(Lines(), "    ap(" + Str(i) + ") = @p_" + *mi\argName[i])
      EndIf
    Next
  EndIf

  ; #Null is main-code only: a module cannot see the constant, so a null
  ; argument array / return pointer is the literal 0 here.
  Protected retptr.s = "0"
  If structRet
    retptr = "*out"
  ElseIf *mi\retPb = "d"
    Add(Lines(), "    Protected rv.d")
    retptr = "@rv"
  ElseIf *mi\retPb = "i"
    Add(Lines(), "    Protected rvi.i")
    retptr = "@rvi"
  ElseIf *mi\retPb = "l"
    Add(Lines(), "    Protected rvi.l")
    retptr = "@rvi"
  EndIf

  Protected argv.s = "0"
  If *mi\argCount > 0
    argv = "@ap(0)"
  EndIf
  Add(Lines(), "    pc(" + bind + ", PeekI(*self), " + argv + ", " + retptr + ")")

  If *mi\retPb = "d"
    Add(Lines(), "    ProcedureReturn rv")
  ElseIf *mi\retPb = "i" Or *mi\retPb = "l"
    Add(Lines(), "    ProcedureReturn rvi")
  EndIf
  Add(Lines(), "  EndProcedure")
  Add(Lines(), "")
EndProcedure

Procedure EmitClass(List Lines.s(), cls.s, List ancestors.s())
  Protected c = GetJSONElement(gClasses, gClassIdx(cls))
  Protected prefix.s = Ident(cls)
  Protected methods = JGArr(c, "methods")
  Protected total.l = 0, n.l = 0, i, j, m

  Protected Dim mis.MethodInfo(0)
  If methods
    total = JSONArraySize(methods)
    If total > 0
      Dim mis.MethodInfo(total)
      For i = 0 To total - 1
        m = GetJSONElement(methods, i)
        ; Virtual methods are engine callbacks to implement, not to call.
        If JGBool(m, "is_virtual")
          Continue
        EndIf
        ReadMethod(m, @mis(n))
        n + 1
      Next
    EndIf
  EndIf

  Protected callable.l = 0, skipped.l = 0
  For i = 0 To n - 1
    If mis(i)\wrappable
      callable + 1
    Else
      skipped + 1
    EndIf
  Next

  Protected dashes.s = ""
  For i = 1 To 66 - Len(cls)
    dashes + "-"
  Next
  Add(Lines(), "; ---- " + cls + " " + dashes)
  Add(Lines(), "; " + Str(n) + " methods: " + Str(callable) + " callable, " + Str(skipped) + " bind-only.")
  For i = 0 To n - 1
    If Not mis(i)\wrappable
      Add(Lines(), ";   bind-only: " + mis(i)\name + " (" + mis(i)\skipWhy + ")")
    EndIf
  Next
  Add(Lines(), "")

  ; The class OWNS its state. The bind globals and the typed wrappers live in a
  ; module named after the class; Register_<Class>_Binds() stays in main code
  ; and injects into it from outside, because a module cannot see main-code
  ; globals, structures or procedures at all. The module must be declared
  ; before the Register procedure that assigns into it.
  Add(Lines(), "DeclareModule " + prefix)
  Add(Lines(), "  Prototype LocalPtrcallFn(*mb, *inst, *args, *ret)")
  Add(Lines(), "  Prototype LocalReportFn(class_name.s, method_name.s)")
  Add(Lines(), "  Global ptr_ptrcall.i")
  Add(Lines(), "  Global report_fn.i")
  For i = 0 To n - 1
    Add(Lines(), "  Global gdb_" + Ident(mis(i)\name) + ".i")
  Next
  For i = 0 To n - 1
    If mis(i)\wrappable
      Add(Lines(), "  Declare" + WrapperRet(@mis(i)) + " " + WrapperName(Ident(mis(i)\name)) + "(" + WrapperParams(@mis(i)) + ")")
    EndIf
  Next
  Add(Lines(), "EndDeclareModule")
  Add(Lines(), "")
  Add(Lines(), "Module " + prefix)
  ; A module is a black box and does NOT inherit EnableExplicit from main code,
  ; so without this an undeclared name inside a wrapper silently becomes a
  ; module-local: the wrapper compiles and then does nothing.
  Add(Lines(), "  EnableExplicit")
  Add(Lines(), "")
  For i = 0 To n - 1
    If mis(i)\wrappable
      EmitWrapper(Lines(), cls, @mis(i))
    EndIf
  Next
  Add(Lines(), "EndModule")
  Add(Lines(), "")

  Add(Lines(), "Global gdsn_" + prefix + ".GodotStringName")
  For i = 0 To n - 1
    Add(Lines(), "Global gdsn_" + prefix + "_" + Ident(mis(i)\name) + ".GodotStringName")
  Next
  Add(Lines(), "")

  ; Injected at TOP LEVEL, deliberately not inside Register_<Class>_Binds(). This
  ; statement runs no matter what the extension does, which is the point: when
  ; the resolver was never called, the injection inside it never ran either, and
  ; the wrappers would have no way left to report it. A module's globals are
  ; writable from main scope with ::, so one line per class is enough.
  Add(Lines(), prefix + "::report_fn = @GDEX_ReportUnresolved()")
  Add(Lines(), "")

  Add(Lines(), "Procedure Register_" + prefix + "_Binds()")
  For i = 0 To ListSize(ancestors()) - 1
    SelectElement(ancestors(), i)
    Add(Lines(), "  Register_" + Ident(ancestors()) + "_Binds()")
  Next
  Add(Lines(), "  GDEX_SNFrom(gdsn_" + prefix + ", " + Chr(34) + cls + Chr(34) + ")")
  For i = 0 To n - 1
    Add(Lines(), "  GDEX_SNFrom(gdsn_" + prefix + "_" + Ident(mis(i)\name) + ", " + Chr(34) + mis(i)\name + Chr(34) + ")")
  Next
  Add(Lines(), "")
  Add(Lines(), "  " + prefix + "::ptr_ptrcall = g_ptr_object_method_bind_ptrcall")
  For i = 0 To n - 1
    Protected vn.s = Ident(mis(i)\name)
    Add(Lines(), "  " + prefix + "::gdb_" + vn + " = _pGetMethodBind(@gdsn_" + prefix + ", @gdsn_" + prefix + "_" + vn + ", " + Str(mis(i)\hash) + ")")
  Next
  Add(Lines(), "EndProcedure")
  Add(Lines(), "")
EndProcedure

; ---------------------------------------------------------------------------
; REGISTRATION ORDER - ancestors first, so Register_<Parent>_Binds() exists
; before Register_<Child>_Binds() calls it.
; ---------------------------------------------------------------------------

; Nearest ancestor first (the walk order), filtered to what was requested.
Procedure CollectAncestors(cls.s, List requested.s(), List out.s())
  Protected cur.s = ClassInherits(cls)
  While cur <> ""
    If Has(requested(), cur) And Not Has(out(), cur)
      Add(out(), cur)
    EndIf
    cur = ClassInherits(cur)
  Wend
EndProcedure

Procedure BuildOrder(List requested.s(), List order.s())
  Protected i, k
  For i = 0 To ListSize(requested()) - 1
    SelectElement(requested(), i)
    NewList anc.s()
    CollectAncestors(requested(), requested(), anc())
    ; anc() is nearest-first; walk it backwards for oldest-first.
    For k = ListSize(anc()) - 1 To 0 Step -1
      SelectElement(anc(), k)
      If Not Has(order(), anc())
        Add(order(), anc())
      EndIf
    Next
  Next
  For i = 0 To ListSize(requested()) - 1
    SelectElement(requested(), i)
    If Not Has(order(), requested())
      Add(order(), requested())
    EndIf
  Next
EndProcedure

Procedure.s BuildHeader(outPath.s, List order.s())
  Protected cmd.s = ";   tools/gen_binds --classes"
  Protected i
  For i = 0 To ListSize(order()) - 1
    SelectElement(order(), i)
    cmd + " " + order()
  Next
  cmd + " --out " + outPath
  ProcedureReturn cmd
EndProcedure

Procedure Generate(apiPath.s, List requested.s(), outPath.s)
  LoadApi(apiPath)

  Protected i
  For i = 0 To ListSize(requested()) - 1
    SelectElement(requested(), i)
    If Not FindMapElement(gClassIdx(), requested())
      PrintN("no such class in the API: " + requested())
      End 1
    EndIf
  Next

  NewList order.s()
  BuildOrder(requested(), order())

  NewList lines.s()
  Add(lines(), "; " + LSet("", #OUT_EQUALS, "="))
  Add(lines(), "; " + BaseName(outPath) + " - GENERATED FILE. Do not edit by hand.")
  Add(lines(), ";")
  Add(lines(), BuildHeader(outPath, order()))
  Add(lines(), ";")
  Add(lines(), "; Source: " + BaseName(apiPath) + ". Every hash below is Godot's own.")
  Add(lines(), "; Included before gdex_class.pbi so the framework can see the bind")
  Add(lines(), "; globals; Register_*_Binds() resolves them at SCENE level and")
  Add(lines(), "; assigns them into one module per class, where the wrappers live.")
  Add(lines(), "; " + LSet("", #OUT_EQUALS, "="))
  Add(lines(), "")

  For i = 0 To ListSize(order()) - 1
    SelectElement(order(), i)
    Protected cls.s = order()
    NewList anc.s()
    CollectAncestors(cls, order(), anc())
    ; CollectAncestors gives nearest-first; Register_*_Binds() wants the
    ; parent before the child, so emit nearest-first (the parent is nearest).
    EmitClass(lines(), cls, anc())
  Next

  ; Join with #LF$, exactly as the reference implementation does.
  Protected text.s = JoinLines(lines())

  Protected f = CreateFile(#PB_Any, outPath)
  If Not f
    PrintN("cannot write " + outPath)
    End 1
  EndIf
  WriteString(f, text, #PB_UTF8)
  CloseFile(f)

  Protected total.l = 0
  For i = 0 To ListSize(order()) - 1
    SelectElement(order(), i)
    Protected methods = JGArr(GetJSONElement(gClasses, gClassIdx(order())), "methods")
    If methods
      total + JSONArraySize(methods)
    EndIf
  Next
  PrintN(outPath + ": " + Str(ListSize(order())) + " class(es), " + Str(total) + " methods")
EndProcedure

; ---------------------------------------------------------------------------
; DIRECTORY MODE - one file per engine class, so an extension can IncludeFile
; just the classes it uses instead of carrying a combined bundle.
;
; This is the mode to use when starting a project: generate the whole library
; once, then cherry-pick.
;
;     tools/gen_binds --outdir bindlib                  (every class)
;     tools/gen_binds --outdir bindlib --classes Node2D (just one, plus the
;                                                        ancestors it needs)
;
; EVERY FILE IS SELF-CONTAINED: it declares its own binds and its own
; Register_<Class>_Binds(), and includes nothing. That is deliberate - PureBasic
; has no include-once, so if Node2D.pbi pulled in Node.pbi and the caller also
; included Node.pbi directly, the second copy would be a duplicate definition.
; Self-contained files can be mixed in any combination, in any order.
;
; Nothing hand-written is grafted on, and nothing is added to the language
; surface either: callers use these generated names directly. The output
; directory holds nothing but generator output, so it is reproducible byte for
; byte and safe to delete.
; ---------------------------------------------------------------------------

; The nearest ancestor that is also being emitted, or "" if there is none.
Procedure.s NearestEmittedAncestor(cls.s, List emitted.s())
  Protected cur.s = ClassInherits(cls)
  While cur <> ""
    If Has(emitted(), cur)
      ProcedureReturn cur
    EndIf
    cur = ClassInherits(cur)
  Wend
  ProcedureReturn ""
EndProcedure

; No --classes means the whole library.
Procedure CollectClasses(List requested.s(), List out.s())
  Protected i
  If ListSize(requested()) = 0
    Protected nAll = JSONArraySize(gClasses)
    For i = 0 To nAll - 1
      Protected c0 = GetJSONElement(gClasses, i)
      If JSONType(c0) <> #PB_JSON_Object
        Continue
      EndIf
      If JGArr(c0, "methods") = 0
        Continue
      EndIf
      Add(out(), JGStr(c0, "name"))
    Next
  Else
    For i = 0 To ListSize(requested()) - 1
      SelectElement(requested(), i)
      Add(out(), requested())
    Next
  EndIf
EndProcedure

Procedure GenerateDir(apiPath.s, List requested.s(), outDir.s)
  LoadApi(apiPath)

  NewList wanted.s()
  CollectClasses(requested(), wanted())
  Protected i

  For i = 0 To ListSize(requested()) - 1
    SelectElement(requested(), i)
    If Not FindMapElement(gClassIdx(), requested())
      PrintN("no such class in the API: " + requested())
      End 1
    EndIf
  Next

  NewList order.s()
  BuildOrder(wanted(), order())
  If Not FileExists(outDir)
    CreateDirectory(outDir)
  EndIf

  Protected written.l = 0, unchanged.l = 0
  For i = 0 To ListSize(order()) - 1
    SelectElement(order(), i)
    Protected cls.s = order()

    NewList lines.s()
    Add(lines(), "; " + LSet("", #OUT_EQUALS, "="))
    Add(lines(), "; " + cls + ".pbi - GENERATED FILE. Do not edit by hand.")
    Add(lines(), ";")
    Add(lines(), ";   tools/gen_binds --outdir " + outDir)
    Add(lines(), ";")
    Add(lines(), "; Source: " + BaseName(apiPath) + ". Every hash below is Godot's own.")
    Add(lines(), "; Included before gdex_class.pbi so the framework can see the bind")
    Add(lines(), "; globals; Register_" + Ident(cls) + "_Binds() resolves them at SCENE level and")
    Add(lines(), "; assigns them into module " + Ident(cls) + ", where the method wrappers live.")
    Add(lines(), "; Self-contained: include this file and nothing else is needed.")
    Add(lines(), "; " + LSet("", #OUT_EQUALS, "="))
    Add(lines(), "")

    NewList anc.s()
    EmitClass(lines(), cls, anc())

    If WriteIfChanged(outDir + "/" + cls + ".pbi", JoinLines(lines()))
      written + 1
    Else
      unchanged + 1
    EndIf
  Next
  Protected msg.s = outDir + ": " + Str(ListSize(order())) + " class(es), "
  msg + Str(written) + " written, " + Str(unchanged) + " unchanged"
  PrintN(msg)
EndProcedure

; ---------------------------------------------------------------------------
; SELF-TEST - verify the whole library against the RUNNING engine.
;
;     tools/gen_binds --selftest generated/selftest.pbi --outdir generated
;
; --check compares the generated files against the same extension_api.json they
; were generated FROM, so it cannot catch a dump that does not match the Godot
; binary actually loading the extension. This can: it calls every
; Register_<Class>_Binds() and tests every bind global for null, which is
; Godot's own ClassDB answering "no such class, method or hash".
;
; The interesting distinction is PER CLASS, and it is self-classifying:
;
;   every bind of a class is null   -> the class is not registered here at all
;                                      (editor-only, or platform-gated such as
;                                      JavaClass and JavaScriptBridge). Expected.
;   some binds null, some not       -> a genuine mismatch. Reported loudly.
;
; That is better than classifying by api_type, because api_type says "core" for
; Android and Web classes that a macOS game run simply does not have.
; ---------------------------------------------------------------------------

Procedure EmitSelfTest(apiPath.s, List requested.s(), outFile.s)
  LoadApi(apiPath)
  NewList classes.s()
  CollectClasses(requested(), classes())
  Protected nClasses.l = ListSize(classes())

  NewList lines.s()
  Add(lines(), "; " + LSet("", #OUT_EQUALS, "="))
  Add(lines(), "; selftest.pbi - GENERATED FILE. Do not edit by hand.")
  Add(lines(), ";")
  Add(lines(), ";   tools/gen_binds --selftest <this file> --outdir <class dir>")
  Add(lines(), ";")
  Add(lines(), "; Includes the whole library and checks every bind against the")
  Add(lines(), "; running engine. Call GDEX_SelfTest() at SCENE level.")
  Add(lines(), "; " + LSet("", #OUT_EQUALS, "="))
  Add(lines(), "")

  Protected i, j
  For i = 0 To nClasses - 1
    SelectElement(classes(), i)
    Add(lines(), "IncludeFile " + Chr(34) + classes() + ".pbi" + Chr(34))
  Next
  Add(lines(), "")

  Add(lines(), "Procedure GDEX_SelfTest()")
  Add(lines(), "  Protected Dim gdName.s(" + Str(nClasses - 1) + ")")
  Add(lines(), "  Protected Dim gdOk.l(" + Str(nClasses - 1) + ")")
  Add(lines(), "  Protected Dim gdBad.l(" + Str(nClasses - 1) + ")")
  For i = 0 To nClasses - 1
    SelectElement(classes(), i)
    Add(lines(), "  gdName(" + Str(i) + ") = " + Chr(34) + classes() + Chr(34))
  Next
  Add(lines(), "  Protected i, ok.l = 0, bad.l = 0, absent.l = 0, partial.l = 0")
  Add(lines(), "  Protected absentNames.s, absentMethods.l")

  For i = 0 To nClasses - 1
    SelectElement(classes(), i)
    Protected cls.s = classes()
    Protected prefix.s = Ident(cls)
    Add(lines(), "")
    Add(lines(), "  Register_" + prefix + "_Binds()")
    Protected methods = JGArr(GetJSONElement(gClasses, gClassIdx(cls)), "methods")
    If methods
      Protected mc = JSONArraySize(methods)
      For j = 0 To mc - 1
        Protected m = GetJSONElement(methods, j)
        If JGBool(m, "is_virtual")
          Continue
        EndIf
        Protected mn.s = Ident(JGStr(m, "name"))
        Add(lines(), "  If " + prefix + "::gdb_" + mn + " : gdOk(" + Str(i) + ") + 1 : Else : gdBad(" + Str(i) + ") + 1 : EndIf")
      Next
    EndIf
  Next

  Add(lines(), "")
  Add(lines(), "  For i = 0 To " + Str(nClasses - 1))
  Add(lines(), "    ok + gdOk(i)")
  Add(lines(), "    bad + gdBad(i)")
  Add(lines(), "    If gdBad(i) > 0")
  Add(lines(), "      If gdOk(i) = 0")
  Add(lines(), "        absent + 1")
  Add(lines(), "        absentMethods + gdBad(i)")
  Add(lines(), "        absentNames + gdName(i) + " + Chr(34) + " " + Chr(34))
  Add(lines(), "      Else")
  Add(lines(), "        partial + 1")
  Add(lines(), "        GDEX_Report(" + Chr(34) + "PARTIAL " + Chr(34) + " + gdName(i) + " + Chr(34) + ": " + Chr(34) + " + Str(gdBad(i)) + " + Chr(34) + " binds null, " + Chr(34) + " + Str(gdOk(i)) + " + Chr(34) + " ok" + Chr(34) + ")")
  Add(lines(), "      EndIf")
  Add(lines(), "    EndIf")
  Add(lines(), "  Next")
  Add(lines(), "")
  Protected rep.s = "  GDEX_Report(" + Chr(34) + "[gdex] selftest: " + Chr(34)
  rep + " + Str(ok) + " + Chr(34) + " binds ok, " + Chr(34)
  rep + " + Str(bad) + " + Chr(34) + " null; " + Chr(34)
  rep + " + Str(absent) + " + Chr(34) + " class(es) absent, " + Chr(34)
  rep + " + Str(partial) + " + Chr(34) + " PARTIAL" + Chr(34) + ")"
  Add(lines(), rep)
  Add(lines(), "  If absent > 0")
  Add(lines(), "    GDEX_Report(" + Chr(34) + "[gdex] absent (not registered in this context): " + Chr(34) + " + absentNames)")
  Add(lines(), "  EndIf")
  Add(lines(), "EndProcedure")

  If WriteIfChanged(outFile, JoinLines(lines()))
    Protected msg.s = outFile + ": self-test for " + Str(nClasses) + " classes written"
    PrintN(msg)
  Else
    PrintN(outFile + ": self-test unchanged")
  EndIf
EndProcedure

; ---------------------------------------------------------------------------
; --check : re-verify every hash already present in a .pbi against the API.
; PureBasic has no regex, so the two line shapes are scanned by hand.
; ---------------------------------------------------------------------------

Procedure.s Between(s.s, startTag.s, endTag.s)
  Protected a = FindString(s, startTag, 1)
  If a = 0
    ProcedureReturn ""
  EndIf
  a + Len(startTag)
  Protected b = FindString(s, endTag, a)
  If b = 0
    ProcedureReturn ""
  EndIf
  ProcedureReturn Mid(s, a, b - a)
EndProcedure

Procedure.l Check(apiPath.s, List files.s())
  LoadApi(apiPath)
  Protected total.l = 0, bad.l = 0, i

  For i = 0 To ListSize(files()) - 1
    SelectElement(files(), i)
    Protected path.s = files()
    Protected f = ReadFile(#PB_Any, path)
    If Not f
      PrintN("  ?  cannot read " + path)
      bad + 1
      Continue
    EndIf
    NewMap sn.s()
    While Not Eof(f)
      Protected line.s = ReadString(f, #PB_UTF8)
      If FindString(line, "GDEX_SNFrom(")
        Protected alias.s = Trim(Between(line, "GDEX_SNFrom(", ","))
        Protected txt.s = Between(line, Chr(34), Chr(34))
        If alias <> "" And txt <> ""
          sn(alias) = txt
        EndIf
      EndIf
      If FindString(line, "_pGetMethodBind(@")
        total + 1
        Protected clsVar.s = Trim(Between(line, "_pGetMethodBind(@", ","))
        Protected methVar.s = Trim(Between(line, ", @", ","))
        Protected hashStr.s = Trim(Between(line, "@" + methVar + ",", ")"))
        Protected cls.s = "", meth.s = ""
        If FindMapElement(sn(), clsVar)
          cls = sn()
        EndIf
        If FindMapElement(sn(), methVar)
          meth = sn()
        EndIf
        If cls = "" Or meth = ""
          PrintN("  ?  " + path + ": cannot resolve " + clsVar + "/" + methVar)
          bad + 1
        ElseIf Not FindMapElement(gHash(), cls + "." + meth)
          PrintN("  ?  " + path + ": " + cls + "." + meth + " not in the API")
          bad + 1
        ElseIf Val(hashStr) <> gHash()
          PrintN("  X  " + path + ": " + cls + "." + meth + " has " + hashStr + ", API says " + Str(gHash()))
          bad + 1
        EndIf
      EndIf
    Wend
    CloseFile(f)
  Next

  If bad = 0
    PrintN("checked " + Str(total) + " binds in " + Str(ListSize(files())) + " file(s): all match the API")
  Else
    PrintN("checked " + Str(total) + " binds in " + Str(ListSize(files())) + " file(s): " + Str(bad) + " problem(s)")
  EndIf
  ProcedureReturn bad
EndProcedure

Procedure Stats(apiPath.s)
  LoadApi(apiPath)
  PrintN("classes              " + Str(gClassCount))
  PrintN("methods              " + Str(gMethodCount))
  PrintN("  with a hash        " + Str(MapSize(gHash())))

  Protected vararg.l = 0, typable.l = 0, i, j, m
  Protected classes = JSONArraySize(gClasses)
  Protected signals.l = 0, props.l = 0
  For i = 0 To classes - 1
    Protected c = GetJSONElement(gClasses, i)
    If JSONType(c) <> #PB_JSON_Object
      Continue
    EndIf
    Protected s = JGArr(c, "signals")
    If s
      signals + JSONArraySize(s)
    EndIf
    Protected pr = JGArr(c, "properties")
    If pr
      props + JSONArraySize(pr)
    EndIf
    Protected methods = JGArr(c, "methods")
    If Not methods
      Continue
    EndIf
    Protected mc = JSONArraySize(methods)
    For j = 0 To mc - 1
      m = GetJSONElement(methods, j)
      Protected mi.MethodInfo
      ReadMethod(m, @mi)
      If mi\isVararg
        vararg + 1
      EndIf
      If mi\wrappable
        typable + 1
      EndIf
    Next
  Next
  PrintN("  vararg (bind-only) " + Str(vararg))
  PrintN("  typable wrapper    " + Str(typable))
  PrintN("signals              " + Str(signals))
  PrintN("properties           " + Str(props))
EndProcedure


; ---------------------------------------------------------------------------
; WIZARD
;
;   pb_gdext_wizard <godot-executable> <project-name>
;
; Asks for a folder, then builds a whole project in it: the API dump taken from
; the Godot binary you named, the bindings generated from that dump, the
; framework, a PB entry file ready to open in the IDE, and a Godot project
; whose .gdextension already points at the dylib you are about to build.
; ---------------------------------------------------------------------------

Procedure MakeDirs(path.s)
  path = ReplaceString(path, "\", "/")
  If Right(path, 1) = "/" : path = Left(path, Len(path) - 1) : EndIf
  Protected i.l, acc.s
  For i = 1 To Len(path)
    acc + Mid(path, i, 1)
    If Right(acc, 1) = "/" And Len(acc) > 1
      CreateDirectory(Left(acc, Len(acc) - 1))
    EndIf
  Next i
  CreateDirectory(path)
EndProcedure

Procedure CopyTree(src.s, dst.s)
  Protected dir = ExamineDirectory(#PB_Any, src, "*")
  If Not dir
    ProcedureReturn
  EndIf
  MakeDirs(dst)
  Protected name.s, s.s, d.s, kind.l
  While NextDirectoryEntry(dir)
    name = DirectoryEntryName(dir)
    kind = DirectoryEntryType(dir)
    If name <> "." And name <> ".." And name <> ".DS_Store"
      s = src + "/" + name
      d = dst + "/" + name
      If kind = #PB_DirectoryEntry_Directory
        CopyTree(s, d)
      Else
        CopyFile(s, d)
      EndIf
    EndIf
  Wend
  FinishDirectory(dir)
EndProcedure

; Rewrite a file's text in place, for putting the project name into the entry
; file and the .gdextension.
Procedure ReplaceInFile(path.s, fromText.s, toText.s)
  Protected f = ReadFile(#PB_Any, path)
  If Not f
    ProcedureReturn
  EndIf
  Protected text.s
  While Not Eof(f)
    text + ReadString(f) + Chr(10)
  Wend
  CloseFile(f)
  text = ReplaceString(text, fromText, toText)
  Protected w = CreateFile(#PB_Any, path)
  If w
    WriteString(w, text)
    CloseFile(w)
  EndIf
EndProcedure

Procedure Wizard(godotExe.s, projectName.s)
  If FileSize(godotExe) <= 0
    PrintN("no such Godot executable: " + godotExe)
    ProcedureReturn 1
  EndIf

  ; A third argument is the destination folder, which skips the requester -
  ; useful for scripting, and the only way to drive this unattended.
  Protected base.s
  If CountProgramParameters() >= 3
    base = ProgramParameter(2)
  Else
    base = PathRequester("Choose the folder to create '" + projectName + "' in", "")
  EndIf
  If base = ""
    PrintN("cancelled")
    ProcedureReturn 1
  EndIf
  If Right(base, 1) <> "/"
    base + "/"
  EndIf
  Protected root.s = base + projectName
  MakeDirs(root)

  ; 1. The API dump, taken from the binary the user named. Godot writes
  ;    extension_api.json into its WORKING DIRECTORY - there is no output flag
  ;    - so RunProgram's third argument is what puts it here.
  MakeDirs(root + "/api")
  PrintN("dumping extension_api.json with " + godotExe + " ...")
  PrintN("  destination " + root)
  Protected api.s = root + "/api/extension_api.json"
  DeleteFile(api)
  RunProgram(godotExe, "--headless --dump-extension-api", root + "/api")

  ; Wait for the dump by watching the FILE, not the process. PureBasic's
  ; ProgramRunning() and CloseProgram() both segfault on this child - measured,
  ; exit 139, with the dump still written - so the child is left untracked. It
  ; exits on its own, and the file stops growing when it has.
  Protected waited.l = 0, last.q = -1, cur.q
  While waited < 600
    Delay(100)
    waited + 1
    cur = FileSize(api)
    If cur > 0 And cur = last
      Break
    EndIf
    last = cur
  Wend
  If FileSize(api) <= 0
    PrintN("the dump wrote no extension_api.json - is that a Godot 4 binary?")
    ProcedureReturn 1
  EndIf
  PrintN("  api dumped")

  ; 2. The bindings, from that dump rather than from any dump this repo ships.
  MakeDirs(root + "/generated")
  Protected NewList want.s()
  PrintN("  generating bindings ...")
  GenerateDir(api, want(), root + "/generated")
  PrintN("  bindings generated")

  ; 3. The framework, the entry file and the Godot project, taken from the
  ;    checkout this tool lives in - so there is exactly one copy of the
  ;    framework in the world and it cannot drift from what the wizard writes.
  Protected repo.s = GetPathPart(ProgramFilename()) + "../"
  If FileSize(repo + "gdex_class.pbi") <= 0
    PrintN("cannot find the framework beside this tool, expected " + repo + "gdex_class.pbi")
    ProcedureReturn 1
  EndIf
  PrintN("  copying the framework from " + repo)
  MakeDirs(root + "/generated/helpers")
  MakeDirs(root + "/godot")
  CopyFile(repo + "gdex_types.pbi",             root + "/gdex_types.pbi")
  CopyFile(repo + "gdextension_interface.pbi",  root + "/gdextension_interface.pbi")
  CopyFile(repo + "gdex_defs.pbi",              root + "/gdex_defs.pbi")
  CopyFile(repo + "gdex_api.pbi",               root + "/gdex_api.pbi")
  CopyFile(repo + "gdex_class.pbi",             root + "/gdex_class.pbi")
  CopyFile(repo + "generated/helpers/gdex_helpers.pbi", root + "/generated/helpers/gdex_helpers.pbi")
  CopyFile(repo + "generated/helpers/gdex_variant.pbi", root + "/generated/helpers/gdex_variant.pbi")
  CopyFile(repo + "generated/helpers/gdex_classdb.pbi", root + "/generated/helpers/gdex_classdb.pbi")
  CopyFile(repo + "generated/helpers/gdex_signal.pbi",  root + "/generated/helpers/gdex_signal.pbi")
  CopyFile(repo + "generated/helpers/gdex_macros.pbi",  root + "/generated/helpers/gdex_macros.pbi")
  ; The skeleton is a SIBLING of the framework, so its includes say "../".
  ; Copied to the project root those must lose the prefix.
  CopyFile(repo + "skeleton/example.pb", root + "/example.pb")
  CopyFile(repo + "skeleton/spinner.pbi", root + "/spinner.pbi")
  CopyFile(repo + "skeleton/godot/project.godot", root + "/godot/project.godot")
  CopyFile(repo + "skeleton/godot/main.tscn", root + "/godot/main.tscn")
  CopyFile(repo + "skeleton/godot/main.gd", root + "/godot/main.gd")
  CopyFile(repo + "skeleton/godot/example.gdextension", root + "/godot/example.gdextension")
  ReplaceInFile(root + "/example.pb", "../", "")
  PrintN("  framework copied")

  ; 4. The project's own name, in the places it has to appear.
  Protected q.s = Chr(34)
  Protected pb.s = root + "/" + projectName + ".pb"
  RenameFile(root + "/example.pb", pb)
  ReplaceInFile(pb, "example_library_init", projectName + "_library_init")
  ReplaceInFile(pb, "libexample.dylib", "lib" + projectName + ".dylib")
  RenameFile(root + "/godot/example.gdextension", root + "/godot/" + projectName + ".gdextension")
  ReplaceInFile(root + "/godot/" + projectName + ".gdextension", "example_library_init", projectName + "_library_init")
  ReplaceInFile(root + "/godot/" + projectName + ".gdextension", "libexample", "lib" + projectName)
  ReplaceInFile(root + "/godot/project.godot", "PB Skeleton Extension", projectName)

  PrintN("")
  PrintN("created " + root)
  PrintN("")
  PrintN("  " + projectName + ".pb    open this in the PureBasic IDE and compile")
  PrintN("  generated/       the bindings, built from the API of YOUR Godot")
  PrintN("  godot/           the Godot project, .gdextension already wired")
  PrintN("")
  PrintN("next:")
  PrintN("  1. open " + projectName + ".pb in the PureBasic IDE and compile it")
  PrintN("  2. cd godot && Godot --headless --path . --import")
  PrintN("  3. cd godot && Godot --path .")
  ProcedureReturn 0
EndProcedure

; ---------------------------------------------------------------------------
; MAIN
; ---------------------------------------------------------------------------

Procedure.s DefaultApi()
  ProcedureReturn GetPathPart(ProgramFilename()) + "../../prototype_gdext/godot-cpp/gdextension/extension_api-4-7.json"
EndProcedure

Procedure PrintHelp()
  PrintN("pb_gdext_wizard - generate PureBasic method-bind plumbing from extension_api.json")
  PrintN("")
  PrintN("  --api PATH        Godot's extension_api.json")
  PrintN("  --classes A B C   classes to emit")
  PrintN("  --out PATH        write one combined file")
  PrintN("  --outdir DIR      write one file per class (the cherry-pick library)")
  PrintN("  --selftest FILE   write a harness that checks every bind against Godot")
  PrintN("  --check FILE...   verify hashes already present in .pbi files")
  PrintN("  --stats           how big the whole API is")
  PrintN("")
  PrintN("or, to create a new project from scratch:")
  PrintN("")
  PrintN("  pb_gdext_wizard <godot-executable> <project-name>")
EndProcedure

InitTypeMap()

; Wizard mode: no option flags, just the Godot binary and a project name.
If CountProgramParameters() >= 2 And Left(ProgramParameter(0), 2) <> "--"
  End Wizard(ProgramParameter(0), ProgramParameter(1))
EndIf


Define apiPath.s = DefaultApi()
Define outPath.s = ""
Define outDir.s = ""
Define selfTestPath.s = ""
Define doStats.l = #False
NewList requested.s()
NewList checkFiles.s()

Define n = CountProgramParameters()
Define i = 0
While i < n
  Define p.s = LCase(ProgramParameter(i))
  Select p
    Case "--api"
      i + 1
      If i < n
        apiPath = ProgramParameter(i)
      EndIf
    Case "--out"
      i + 1
      If i < n
        outPath = ProgramParameter(i)
      EndIf
    Case "--outdir"
      i + 1
      If i < n
        outDir = ProgramParameter(i)
      EndIf
    Case "--selftest"
      i + 1
      If i < n
        selfTestPath = ProgramParameter(i)
      EndIf
    Case "--stats"
      doStats = #True
    Case "--classes"
      While i + 1 < n And Left(ProgramParameter(i + 1), 2) <> "--"
        i + 1
        Add(requested(), ProgramParameter(i))
      Wend
    Case "--check"
      While i + 1 < n And Left(ProgramParameter(i + 1), 2) <> "--"
        i + 1
        Add(checkFiles(), ProgramParameter(i))
      Wend
    Default
      PrintN("unknown option: " + p)
      PrintHelp()
      End 1
  EndSelect
  i + 1
Wend

If doStats
  Stats(apiPath)
ElseIf ListSize(checkFiles()) > 0
  If Check(apiPath, checkFiles()) > 0
    End 1
  EndIf
ElseIf selfTestPath <> "" And outDir <> ""
  EmitSelfTest(apiPath, requested(), selfTestPath)
ElseIf outDir <> ""
  GenerateDir(apiPath, requested(), outDir)
ElseIf ListSize(requested()) > 0 And outPath <> ""
  Generate(apiPath, requested(), outPath)
Else
  PrintHelp()
EndIf
