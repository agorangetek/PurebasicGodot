#!/bin/sh
# Generate the PureBasic bindings for Godot's engine classes, once, up front.
#
#   ./generate-bindings.sh                      -> every class, into generated/
#   ./generate-bindings.sh Node2D Object Engine -> just these
#   ./generate-bindings.sh --check              -> verify what is already there
#
# RUN THIS ONCE, BEFORE YOU START WRITING A GDEXTENSION. It builds
# tools/pb_gdext_wizard from source, walks Godot's extension_api.json, and writes one
# self-contained PureBasic file per engine class. After that, ./build.sh
# compiles your extension and never looks at the API dump again.
#
# Re-run it only when you want MORE classes than are already in generated/, or
# when you move to a newer Godot. It rewrites only the files whose bytes
# change, so re-running is safe and cheap.
#
# WHERE THE API DUMP COMES FROM. Godot publishes it; this checkout keeps a copy
# in the sibling godot-cpp tree. Override with GDEXT_API:
#
#   GDEXT_API=/path/to/extension_api.json ./generate-bindings.sh
#
# You can get a matching dump from a Godot binary with:
#   godot --headless --dump-extension-api
#
# WHAT IT WRITES, AND WHY IT IS COMMITTED. generated/ is not throwaway build
# output - it is a normal dependency of your project, like a vendored library.
# Commit it. Nobody should need Godot's 7 MB API dump just to compile.
set -e
here=$(cd "$(dirname "$0")" && pwd)
cd "$here"

PB=${PBCOMPILER:-/Applications/PureBasic.app/Contents/Resources/compilers/pbcompiler}
if [ ! -x "$PB" ]; then
  echo "pbcompiler not found at $PB - set PBCOMPILER to its path" >&2
  exit 1
fi

API=${GDEXT_API:-$here/../prototype_gdext/godot-cpp/gdextension/extension_api-4-7.json}
GEN=tools/pb_gdext_wizard
GEN_SRC=tools/pb_gdext_wizard.pb
OUTDIR=generated

CHECK_ONLY=0
CLASSES=""
for arg in "$@"; do
  case "$arg" in
    --check) CHECK_ONLY=1 ;;
    -h|--help)
      sed -n '2,5p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    -*) echo "unknown option: $arg" >&2; exit 1 ;;
    *) CLASSES="$CLASSES $arg" ;;
  esac
done

if [ ! -f "$API" ]; then
  echo "Godot's API dump not found at:" >&2
  echo "  $API" >&2
  echo "Point GDEXT_API at one, or produce it with:" >&2
  echo "  godot --headless --dump-extension-api" >&2
  exit 1
fi

# --- the generator itself ---------------------------------------------------
if [ ! -x "$GEN" ] || [ "$GEN_SRC" -nt "$GEN" ]; then
  echo "building tools/pb_gdext_wizard..."
  "$PB" "$GEN_SRC" -c -e "$GEN"
  rm -f tools/purebasic.c
fi

if [ "$CHECK_ONLY" = 1 ]; then
  # The framework hard-codes the four engine methods it resolves for itself;
  # those hashes deserve the same verification as the generated ones.
  "$GEN" --api "$API" --check gdex_class.pbi "$OUTDIR"/*.pbi
  exit 0
fi

# --- the bindings -----------------------------------------------------------
# --classes last, so an empty CLASSES leaves it consuming nothing and the
# generator falls back to the whole API.
"$GEN" --api "$API" --outdir "$OUTDIR" --classes $CLASSES

# The self-test harness covers the same classes, so it is regenerated with
# them. selftest/ builds it into a GDExtension that checks every bind against
# the running engine - the one thing --check cannot do, because --check only
# compares the files against the dump they came from.
"$GEN" --api "$API" --selftest "$OUTDIR/selftest.pbi" --outdir "$OUTDIR"

# Every hash written must match the dump it came from.
"$GEN" --api "$API" --check gdex_class.pbi "$OUTDIR"/*.pbi

# --- the helper layer inside generated/ -------------------------------------
# generated/helpers/ is the one hand-written thing under generated/: the
# godot-cpp-shaped surface over the generated binds, so a class declares its
# methods, properties and signals the way a godot-cpp class does. Written only
# if missing, so editing those files is safe and "rm -rf generated" stays
# recoverable.
create() {   # create <path> ; body on stdin, written only if the path is absent
  [ -f "$1" ] && { cat >/dev/null; return 0; }
  mkdir -p "$(dirname "$1")"
  cat > "$1"
  echo "  wrote $1"
}

create "$OUTDIR/helpers/gdex_helpers.pbi" <<'PBEOF'
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
PBEOF

create "$OUTDIR/helpers/gdex_variant.pbi" <<'PBEOF'
; ===========================================================================
; gdex_variant.pbi - native value <-> Variant, for EVERY type.
;
; Godot hands out one constructor per Variant type:
;
;   get_variant_from_type_constructor(type)  -> (VariantPtr dest, TypePtr src)
;   get_variant_to_type_constructor(type)    -> (TypePtr dest, VariantPtr src)
;
; so a single pair of procedures covers every builtin - float, int, bool,
; Vector2, Vector3, Color, Transform3D, Basis, RID, String, Object, Array,
; Dictionary, ... There is deliberately nothing per-type here.
;
; `src` is a pointer to the native value, and the type constant says how to
; read it. For the pointer-sized types (String, StringName, Object, Array,
; Dictionary) that means a pointer to the Godot object itself, which the caller
; owns and must destroy - this layer constructs Variants, not Godot objects.
; ===========================================================================

; Native value -> Variant.
Procedure GDEX_VariantFromType(*dest, vtype.l, *src)
  Protected ctor.GDExtensionVariantFromTypeConstructorFunc
  ctor = g_get_variant_from_type(vtype)
  If ctor
    ctor(*dest, *src)
  EndIf
EndProcedure

; Variant -> native value.
Procedure GDEX_TypeFromVariant(*dest, vtype.l, *variant)
  Protected ctor.GDExtensionTypeFromVariantConstructorFunc
  ctor = g_get_variant_to_type(vtype)
  If ctor
    ctor(*dest, *variant)
  EndIf
EndProcedure

; Scratch storage for one Variant: 24 opaque bytes, nothing more.
Procedure.i GDEX_NewVariant()
  ProcedureReturn AllocateMemory(#GDEX_VARIANT_SIZE)
EndProcedure

; Release one that GDEX_NewVariant made.
Procedure GDEX_FreeVariant(*v)
  If *v
    g_variant_destroy(*v)
    FreeMemory(*v)
  EndIf
EndProcedure
PBEOF

create "$OUTDIR/helpers/gdex_classdb.pbi" <<'PBEOF'
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
; PropertyInfo and ADD_SIGNAL use. The trailing types are (return, arg0, arg1).
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

  Prototype BindMethodFn(Name.s, A1.s, A2.s, A3.s, Proc.i, RetType.l, Arg0.l, Arg1.l)
  Prototype AddPropertyFn(PropType.l, PropName.s, SetterName.s, GetterName.s)
  Prototype AddSignalFn(SigName.s, T0.l, N0.s, T1.l, N1.s, T2.l, N2.s, T3.l, N3.s)

  Declare bind_method(Name.s, A1.s = "", A2.s = "", A3.s = "", Proc.i = 0, RetType.l = 0, Arg0.l = -1, Arg1.l = -1)
  Declare add_property(PropType.l, PropName.s, SetterName.s, GetterName.s)
  Declare add_signal(SigName.s, T0.l = 0, N0.s = "", T1.l = 0, N1.s = "", T2.l = 0, N2.s = "", T3.l = 0, N3.s = "")
EndDeclareModule

Module ClassDB
  EnableExplicit

  ; ClassDB::bind_method(D_METHOD("set_amplitude", "amplitude"), @GDExample_set_amplitude(), #VOID, #FLOAT)
  Procedure bind_method(Name.s, A1.s = "", A2.s = "", A3.s = "", Proc.i = 0, RetType.l = 0, Arg0.l = -1, Arg1.l = -1)
    Protected f.BindMethodFn = bind_method_fn
    f(Name, A1, A2, A3, Proc, RetType, Arg0, Arg1)
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
PBEOF

create "$OUTDIR/helpers/gdex_signal.pbi" <<'PBEOF'
; ===========================================================================
; gdex_signal.pbi - emit_signal, spelled as godot-cpp spells it.
;
;     emit_signal(*self, "position_changed", @new_position)
;
; godot-cpp's emit_signal is a variadic template over Object::emit_signal, so
; the C++ compiler packs the Variant array. PureBasic has no variadics, so the
; value pointers are declared up to four and the TYPES come from the signal's
; OWN declaration - ADD_SIGNAL(MethodInfo(...)) already recorded them. That is
; why no type constant appears at an emit site: it would only repeat what the
; class already said.
;
; Object.emit_signal is variadic and cannot be ptrcalled, so the call goes
; through object_method_bind_call with real Variants, and the signal name is
; itself call-argument 0 (the "+ 1" below). godot-cpp does the same in
; Object::emit_signal.
;
; Requires generated/Object.pbi to be included and Register_Object_Binds() to
; have run at SCENE level: Object::gdb_emit_signal is that generated bind.
; ===========================================================================

; The instance's own signal.
Procedure emit_signal(*self, Name.s, *v0 = 0, *v1 = 0, *v2 = 0, *v3 = 0)
  Protected *o.GDObject = *self
  If Not Object::gdb_emit_signal Or Not *o Or Not *o\class_info Or Not *o\object
    ProcedureReturn
  EndIf
  Protected *ci.GDClassInfo = *o\class_info

  ; Find the declaration: that is where the argument types live.
  Protected want.GodotStringName
  GDEX_SNFrom(want, Name)
  Protected found.l = #False
  Protected si.l
  For si = 0 To *ci\signal_count - 1
    If GDEX_StringNameEq(@want, @*ci\signals[si]\name)
      found = #True
      Break
    EndIf
  Next si
  If Not found
    GDEX_Fail("[gdex] emit_signal: this class did not declare a signal named " + Name)
    ProcedureReturn
  EndIf
  Protected *sig.GDSignalEntry = @*ci\signals[si]
  Protected n.l = *sig\arg_count

  Protected Dim given.i(3)
  given(0) = *v0
  given(1) = *v1
  given(2) = *v2
  given(3) = *v3

  Protected j.l
  For j = 0 To n - 1
    If given(j) = 0
      GDEX_Fail("[gdex] emit_signal(" + Name + "): argument " + Str(j + 1) + " was not given")
      ProcedureReturn
    EndIf
  Next j

  ; Object.emit_signal(signal: StringName, ...) - the name is call-argument 0,
  ; so the Variant list is one longer than the signal's own argument count.
  Protected *vsig = GDEX_NewVariant()
  GDEX_VariantFromType(*vsig, #STRINGNAME, @want)
  Protected Dim args.i(n)
  args(0) = *vsig
  For j = 0 To n - 1
    Protected *av = GDEX_NewVariant()
    GDEX_VariantFromType(*av, *sig\args[j]\vtype, given(j))
    args(j + 1) = *av
  Next j

  Protected *ret = GDEX_NewVariant()
  Protected err.GDExtensionCallError
  g_object_method_bind_call(Object::gdb_emit_signal, *o\object, @args(0), n + 1, *ret, @err)

  GDEX_FreeVariant(*vsig)
  For j = 0 To n - 1
    GDEX_FreeVariant(args(j + 1))
  Next j
  GDEX_FreeVariant(*ret)
EndProcedure
PBEOF

create "$OUTDIR/helpers/gdex_macros.pbi" <<'PBEOF'
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
PBEOF

# --- the self-test extension ------------------------------------------------
# The harness above is generated; the GDExtension that runs it is boilerplate,
# so it is recreated here too if missing.
SELFTEST=selftest

create "$SELFTEST/selftest.pb" <<'PBEOF'
; ===========================================================================
; selftest/selftest.pb - a PureBasic GDExtension that tests the whole library.
;
;   ../generate-bindings.sh     writes generated/, including selftest.pbi
;   ./build.sh                  compiles this into the Godot project
;   cd godot && Godot --headless --path . --import
;   cd godot && Godot --headless --path .
;
; It defines no class. All it does is call GDEX_SelfTest() at SCENE level,
; which resolves every method bind in generated/ against the running Godot and
; reports which failed.
;
; Why this is worth its own extension: tools/pb_gdext_wizard --check compares the
; generated files against the same extension_api.json they came from, so it
; cannot detect a dump that does not match the Godot binary actually loading
; them. Only the engine can answer "does this class, method and hash exist".
; ===========================================================================

IncludeFile "../gdex_defs.pbi"
IncludeFile "../gdex_api.pbi"
IncludeFile "../generated/selftest.pbi"   ; pulls in all 870 class files
IncludeFile "../gdex_class.pbi"

Procedure initialize_selftest(*p_userdata, p_level)
  ; SCENE: ClassDB has both halves by now, so a null here is meaningful.
  If p_level = #GDEXTENSION_INITIALIZATION_SCENE
    GDEX_SelfTest()
  EndIf
EndProcedure

Procedure deinitialize_selftest(*p_userdata, p_level)
EndProcedure

ProcedureCDLL.a selftest_library_init(*p_get_proc_address, *p_library, *r_initialization)
  GDExtensionClassLibraryPtr = *p_library
  load_api(*p_get_proc_address)
  Protected *ri.GDExtensionInitialization = *r_initialization
  *ri\minimum_initialization_level = #GDEXTENSION_INITIALIZATION_SCENE
  *ri\userdata = 0
  *ri\initialize = @initialize_selftest()
  *ri\deinitialize = @deinitialize_selftest()
  ProcedureReturn 1
EndProcedure

; The framework calls these two; they are how an extension lists its classes
; and resolves engine MethodBinds. This extension has no classes of its own -
; it only runs GDEX_SelfTest() - but the hooks must still exist.
Procedure GDEX_RegisterClasses()
EndProcedure

Procedure GDEX_ResolveBinds()
EndProcedure


; IDE Options = PureBasic 6.41 - C Backend (MacOS X - arm64)
; ExecutableFormat = Shared .dylib
; Executable = libselftest.dylib
PBEOF

create "$SELFTEST/build.sh" <<'SHEOF'
#!/bin/sh
# Build the self-test extension and drop it into its Godot project.
#
#   ./build.sh
#   cd godot && /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --import
#   cd godot && /Applications/Godot.app/Contents/MacOS/Godot --headless --path .
set -e
here=$(cd "$(dirname "$0")" && pwd)
cd "$here"

PB=${PBCOMPILER:-/Applications/PureBasic.app/Contents/Resources/compilers/pbcompiler}
if [ ! -x "$PB" ]; then
  echo "pbcompiler not found at $PB - set PBCOMPILER to its path" >&2
  exit 1
fi
if [ ! -f ../generated/selftest.pbi ]; then
  echo "../generated/selftest.pbi is missing. Run ../generate-bindings.sh first." >&2
  exit 1
fi

rm -f libselftest.dylib
"$PB" selftest.pb -dl libselftest.dylib
rm -f purebasic.c
codesign -s - -f libselftest.dylib >/dev/null 2>&1 || true
cp libselftest.dylib godot/libselftest.dylib
codesign -s - -f godot/libselftest.dylib >/dev/null 2>&1 || true

printf "  exports: %s\n" "$(nm -gU libselftest.dylib | grep -c " T _" || true)"
printf "  size:    %s bytes\n" "$(wc -c < libselftest.dylib | tr -d ' ')"
echo "installed into godot/"
SHEOF
chmod +x "$SELFTEST/build.sh"

create "$SELFTEST/godot/project.godot" <<'EOF'
config_version=5

[application]

config/name="PB GDExtension Selftest"
run/main_scene="res://main.tscn"
config/features=PackedStringArray("4.4")

[rendering]

renderer/rendering_method="mobile"
renderer/rendering_method.mobile="mobile"
EOF
create "$SELFTEST/godot/selftest.gdextension" <<'EOF'
[configuration]

entry_symbol = "selftest_library_init"
compatibility_minimum = "4.4"
reloadable = false

[libraries]

macos.debug = "res://libselftest.dylib"
macos.release = "res://libselftest.dylib"
EOF
create "$SELFTEST/godot/main.tscn" <<'EOF'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://main.gd" id="1_main"]

[node name="Main" type="Node"]
script = ExtResource("1_main")
EOF
create "$SELFTEST/godot/main.gd" <<'EOF'
extends Node
# The extension does its work in its SCENE-level initialize callback, before
# this runs, and prints its report to Godot's log.
func _ready() -> void:
	get_tree().quit()
EOF

echo
echo "Include the classes you need, for example:"
echo "    IncludeFile \"generated/Node2D.pbi\""
echo
echo "Then verify the library (${SELFTEST}/ was recreated if missing):"
echo "    cd ${SELFTEST} && ./build.sh && cd godot"
echo "    /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --import"
echo "    /Applications/Godot.app/Contents/MacOS/Godot --headless --path ."
