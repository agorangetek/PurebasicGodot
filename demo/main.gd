extends Node
#
# Smoke test for the reconstructed PureBasic GDExtension.
#
# It exercises every mechanism the framework provides:
#   * a Node2D extension class with float properties and a signal  (GDExample)
#   * a second one, to prove descriptors are per-class               (GDBouncer)
#   * an Object-derived singleton registered at CORE                 (GDService)
#   * a Node-derived singleton registered at SCENE                   (GDNativeTicker)
#   * exported methods, called from GDScript                         (bump/reset)
#   * `_process` actually running                                    (positions)
#   * a signal emitted from PureBasic                                (bounced)
#   * dynamic access through the class get/set callbacks             (set/get)
#
# The GDService lines are the ones the original Aug-27 log recorded, so they
# are the direct before/after comparison:
#
#     GDService singleton class = GDService | counter = 0.0
#     GDService counter after bump+set: 41.5

func _ready() -> void:
	print("=== PB GDExtension demo ===")
	
	# --- a Node2D extension class, from GDScript --------------------------
	var ex := GDExample.new()
	ex.amplitude = 10.0
	ex.speed = 1.0
	add_child(ex)
	print("GDExample: class=", ex.get_class(),
		" amplitude=", ex.amplitude, " speed=", ex.speed)

	# --- a second Node2D class, and one that emits immediately -------------
	# A tiny amplitude with a high speed makes GDBouncer cross its limit on
	# the first frame, so the signal path is exercised without waiting.
	var b := GDBouncer.new()
	b.amplitude = 0.001
	b.speed = 1000.0
	add_child(b)
	var bounced := []
	b.bounced.connect(func(p): bounced.append(p))
	print("GDBouncer: class=", b.get_class(),
		" amplitude=", b.amplitude, " speed=", b.speed)

	# --- Object-derived singleton, registered at CORE ---------------------
	print("GDService singleton: class=", GDService.get_class(),
		" | counter=", GDService.counter)
	GDService.bump()
	GDService.counter = 41.5
	print("GDService counter after bump+set: ", GDService.counter)

	# --- Node-derived singleton, registered at SCENE ----------------------
	var ticker = Engine.get_singleton("GDNativeTicker")
	print("Native singleton GDNativeTicker: class=", ticker.get_class(),
		" | counter=", ticker.counter)

	# --- let _process run -------------------------------------------------
	for i in 5:
		await get_tree().process_frame

	print("after 5 frames:")
	print("  GDExample.position   = ", ex.position, "   <- set from PureBasic")
	print("  GDBouncer.position   = ", b.position)
	print("  GDBouncer emits      = ", bounced.size(), " bounced")
	print("  GDNativeTicker.count = ", ticker.counter,
		" (not in the tree, so no processing - only bump() moves it)")
	ticker.bump()
	ticker.bump()
	print("  GDNativeTicker after 2x bump() = ", ticker.counter)

	# --- dynamic property access, i.e. the class get/set callbacks --------
	GDService.set("counter", 7.25)
	print("GDService via set()/get(): ", GDService.get("counter"))
	ex.set("amplitude", 3.5)
	print("GDExample via set()/get(): ", ex.get("amplitude"))

	# --- Godot builtin types across the boundary --------------------------
	# `span` is a Vector2 property; the three calls cover Vector2 as a
	# return value, as an argument, and as both.
	print("--- Vector2 across the boundary ---")
	print("  b.span              (Vector2 property)  = ", b.span,
		"  type=", type_string(typeof(b.span)))
	print("  b.bounds()          (Vector2 return)    = ", b.bounds())
	b.apply_bounds(Vector2(7.0, 8.0))
	print("  after apply_bounds(Vector2(7,8)): span = ", b.span)
	print("  b.scaled_span(Vector2(2,3)) (both)      = ", b.scaled_span(Vector2(2.0, 3.0)))
	var scaled: Vector2 = b.scaled_span(Vector2(2.0, 3.0))
	print("  assigned into a typed Vector2 local     = ", scaled,
		"  (GDScript accepted it as Vector2)")
	b.span = Vector2(1.5, 2.5)
	print("  b.span = Vector2(1.5,2.5) -> span       = ", b.span)

	# --- methods that take more than one argument --------------------------
	# C++ gets a whole signature from the member function pointer; here the
	# trailing constants of bind_method are the signature, and past one
	# argument the callee reads its arguments out of *args.
	print("--- multi-argument methods ---")
	var before_phase: float = b.get_phase()
	var before_amp: float = b.amplitude
	b.move_by(2.0, 3.0)
	print("  move_by(2.0, 3.0)   (2 args, void)     phase %.4f -> %.4f, amplitude %.4f -> %.4f"
		% [before_phase, b.get_phase(), before_amp, b.amplitude])
	print("  mix(2.0, 4.0)       (2 args, returns float) = ", b.mix(2.0, 4.0))
	print("  blend(10, 20, 0.25) (3 args, returns float) = ", b.blend(10.0, 20.0, 0.25))
	var grown: Rect2 = b.grow_by(Vector2(3.0, 4.0), 2.0)
	print("  grow_by(Vector2(3,4), 2.0) (builtin + float) = ", grown)
	print("  steps(6, 7)         (2 ints, returns int) = ", b.steps(6, 7))

	# --- a spread of other builtins, same mechanism ------------------------
	print("--- other builtins, all through the generic path ---")
	print("  b.tint        (Color property)  = ", b.tint,
		"  type=", type_string(typeof(b.tint)))
	print("  b.axes()      (Vector3)         = ", b.axes())
	print("  b.extents()   (Rect2)           = ", b.extents())
	print("  b.frame()     (Transform2D)     = ", b.frame())
	print("  b.basis3()    (Transform3D)     = origin ", b.basis3().origin)
	print("  b.grow(Rect2(1,2,3,4))          = ", b.grow(Rect2(1.0, 2.0, 3.0, 4.0)))
	b.tint = Color(0.2, 0.4, 0.6, 1.0)
	print("  b.tint = Color(...) -> tint     = ", b.tint)
	var t2: Transform2D = b.frame()
	print("  assigned into a typed Transform2D local: origin = ", t2.origin)

	# --- a PureBasic-managed member inside an instance ---------------------
	# GDTicker holds a PB List. That only works because it supplies
	# alloc_func/free_func (AllocateStructure/FreeStructure); on the plain
	# AllocateMemory path the first AddElement would segfault. announce()
	# prints the list from PureBasic into Godot's log.
	print("--- PureBasic-managed member inside an instance ---")
	ticker.bump()
	ticker.bump()
	ticker.announce()
	print("  ticker.mark_count() = ", ticker.mark_count(), "  (PB List size)")

	# --- a signal per type: the emitter names no type ---------------------
	# Each signal is declared with its own typed argument in ADD_SIGNAL, and
	# emit_signal in PureBasic then reads the type off that declaration - so
	# the same one-line emit_signal call carries a float, an int, a bool, a
	# Vector2, a Vector3 and a Color, plus a two-argument signal.
	print("--- signals of every type (typed at declaration) ---")
	var probe := GDSignalProbe.new()
	var seen := {}
	probe.none.connect(func(): seen["none"] = "<no argument>")
	probe.float_value.connect(func(v): seen["float_value"] = v)
	probe.int_value.connect(func(v): seen["int_value"] = v)
	probe.bool_value.connect(func(v): seen["bool_value"] = v)
	probe.vector2_value.connect(func(v): seen["vector2_value"] = v)
	probe.vector3_value.connect(func(v): seen["vector3_value"] = v)
	probe.color_value.connect(func(v): seen["color_value"] = v)
	probe.pair.connect(func(a, b): seen["pair"] = [a, b])
	probe.emit_none()
	probe.emit_float()
	probe.emit_int()
	probe.emit_bool()
	probe.emit_vector2()
	probe.emit_vector3()
	probe.emit_color()
	probe.emit_pair()
	for sig in ["none", "float_value", "int_value", "bool_value",
			"vector2_value", "vector3_value", "color_value", "pair"]:
		print("  %-14s <- %s" % [sig, seen.get(sig, "<not received>")])
	print("  ", seen.size(), " signals, one emit_signal shape, types from ADD_SIGNAL")

	# --- a signal with no argument at all ---------------------------------
	var ping := GDSignalPing.new()
	var pings := []
	ping.pinged.connect(func(): pings.append(true))
	ping.ping()
	ping.ping()
	print("  GDSignalPing.ping() x2 -> pinged fired ", pings.size(),
		" time(s), pings()=", ping.pings())

	# --- the signal registered from GDClassInfo\signal_name$ --------------
	if bounced.is_empty():
		print("!! bounced signal never arrived - emit path is broken")
	else:
		print("signal OK: bounced carried ", bounced[0])

	# Both probes are Node-derived and were never added to the tree, so
	# nothing else will free them - without this they are still in ObjectDB
	# at exit and Godot reports them as leaked instances.
	probe.free()
	ping.free()

	print("=== demo done ===")
	get_tree().quit()
