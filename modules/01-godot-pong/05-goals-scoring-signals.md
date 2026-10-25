# Lesson 05 · Goals, Scoring & Signals
> **Session goal:** Detect goals with `Area2D`, track the score in exactly one place, drive the UI purely through signals, and re-serve after a delay. **Time:** ~2 h. **Builds on:** Lesson 04.

## Concepts

### 1. `Area2D` and the `body_entered` signal
An `Area2D` is a region that detects overlaps but doesn't push anything around. It has a `CollisionShape2D`, and it emits signals such as `body_entered(body)` and `body_exited(body)` when a physics body overlaps it. Whether it notices a body depends on **layers and masks** (Lesson 04): the area's *mask* must include the ball's *layer*. No detection? Check the mask before anything else.

**Building one (editor steps, first use):** Add a new scene with an `Area2D` root (Scene dock → **Other Node**, or the 2D Scene button if you've saved other roots). Add a child `CollisionShape2D`. The node shows a yellow warning triangle until you fix it: select it and in the Inspector set **Shape** → click the empty slot → **New RectangleShape2D**, then click the shape to expand it and set its size (or drag the handles in the viewport). Save the scene, then instance it twice into `main.tscn` the way you did with the paddle. In the Inspector's **Collision** section set the area's Layer/Mask per Lesson 04 (an area has both too). Only the **mask** matters for what it detects.

**Bridge:** An S3 event notification or a CloudWatch alarm: the thing watches a condition and announces it. It doesn't decide what happens next.

### 2. Signals: built-in, custom, and the two ways to connect
A signal is a named event on a node. Listeners subscribe with a `Callable`. You can connect in the editor (Node dock, Signals tab, which writes the connection into the `.tscn`) or in code. Declare your own with arguments and fire them with `.emit()`:
```gdscript
signal door_opened(door_id: int)
door_opened.emit(7)
other_node.door_opened.connect(_on_door_opened)
```
**Connecting a built-in signal via the Node dock, step by step:**
1. Select the node that *emits* (the `Area2D`) and open the **Node** dock (tab beside the Inspector) → **Signals** tab.
2. Double-click `body_entered(body: Node2D)`. A dialog asks which node receives it, so pick the node whose script should hold the handler.
3. Leave the generated method name or edit it, press **Connect**. Godot appends a new `func _on_..._body_entered(body: Node2D) -> void:` to that script and the editor jumps there. A green icon now appears beside it. Put your code in that body.
The handler's parameter is the node that entered, so you can ask it things (`body.name`) just like the collider in Lesson 04.

**Connecting in code** instead: `emitter.some_signal.connect(handler_func)`, naming the function without parentheses, as in the snippet above. Do it in `_ready()` so both nodes exist.

**Getting a reference to another node (first use).** To connect in code, a script needs a handle on the other node:
- `$Lamp` (shorthand for `get_node("Lamp")`) finds a **child** by name; `$Rooms/Kitchen` goes deeper. Like a relative filesystem path.
- `@onready var lamp := $Lamp` caches it in a member variable after the children exist (Lesson 01 concept 3).
- `@export var lamp: Node2D` puts a slot in the Inspector, and you drag a node from the scene into it. Stored in the scene file, survives renames.
Notice that all three point *down* at children (or sideways via the owner). That's concept 3.

**Declaring and emitting** a signal is two separate things: `signal` goes at the top of the **emitter's** script, outside any `func`, and `.emit(...)` goes at the moment the event happens. Mismatched argument counts between the declaration, the `emit` and the handler are the usual bug.

Trade-off: editor connections are visible in the scene file but easy to forget about; code connections are greppable and live next to the logic. Pick one convention per project and be consistent. Note that a signal with no listeners is fine. The emitter never knows or cares.

**Bridge:** SNS topic / EventBridge bus. Publishers don't hold subscriber ARNs. In JS: `dispatchEvent` / `addEventListener`, except signals are typed, declared on the class, and checked at parse time.

### 3. "Call down, signal up"
The tree gives you a natural direction. A parent knows its children, so it may call their methods or set their properties. A child must not assume anything about its parent, so it emits a signal and lets whoever owns it react. This keeps scenes reusable: your Goal scene should work in any project that wires up its signal. If you catch yourself writing `get_parent().get_parent()...`, stop and ask which signal should exist instead.

**Bridge:** Control plane vs. data plane. Orchestrators call down into workers; workers publish metrics/events up. A worker with a hardcoded address of its orchestrator is the anti-pattern.

### 4. A single source of truth
Score state lives in exactly one node (a `Main`/`Game` script is the usual home). The goal doesn't count. The HUD doesn't count. The owner changes the score, then *announces* the new value. The UI only renders what it was told. If the UI reads the score every frame in `_process`, you have two readers coupled to one writer's internals, and you've lost the point of this lesson.

*Mechanics:* an `int` member variable on `Main` holds a score (declared at the top of the file so it persists). Changing it is plain assignment, and the signal is emitted by whatever code changed it.

**Bridge:** The database is the source of truth, and dashboards subscribe to change streams instead of polling tables from inside the app.

### 5. UI with `CanvasLayer` + `Label`, and delays with `await`
A `CanvasLayer` draws on its own layer, independent of any camera, which makes it the right parent for HUD controls. `Label.text` is a `String`, so converting an `int` needs a conversion call (look up `str()` and `String.num`/format strings).

For the re-serve delay you have two options: a `Timer` node (configured in the Inspector, with a `timeout` signal), or the one-shot `get_tree().create_timer(seconds)`, which returns an object with a `timeout` signal. In GDScript 4 you can pause a function until a signal fires:
```gdscript
await get_tree().create_timer(1.5).timeout
print("1.5 s later")
```
**`await` vs. JS `await`:** In JS you await a Promise, and the function becomes `async` and returns one. In GDScript you await a *signal* (or a coroutine), and there is no `async` keyword. Any function containing `await` quietly becomes a coroutine, and callers that don't await it carry on immediately. It is *not* a thread. The rest of the game keeps running while you wait. Beware of what happens if the node is freed or the state changes during the wait: your code resumes anyway.

**Building the HUD (editor steps, first use):** Add a new scene (or a child in `main.tscn`) with a `CanvasLayer` root, then add a `Label` child. The Label's **Text** property can be typed in the Inspector for layout testing; place it with the **Layout** controls in the toolbar (the anchor presets menu) or the Inspector's Layout section. Give the text a readable size via **Theme Overrides → Font Sizes**. `Label` comes from `Control`, so its position and size use anchors rather than the plain `position` you used on `Node2D`s. Attach a script to the HUD root that gets references to the labels (`@onready var`, see above), and provides a function that takes new values and sets the text.

**Setting `Label.text` from an int:** `text` only accepts a `String`. `str(5)` converts a value to one, and `"%d" % 5` is printf-style formatting. Assigning an `int` straight to `text` is a type error. Compare `String(n)`/`n.toString()` in JS.

**Where the awaiting happens:** `await` can only appear inside a function, and what follows it in that function runs later. Which function owns the pause is a design decision. Think about which node knows the ball and which node knows the score.

**Bridge:** `sleep` in a state machine vs. a scheduled event. Think "a step in a Step Functions Wait state".

## Spec
**User stories**
- As a player, when the ball goes past my opponent's paddle I score a point and see it on screen.
- As a player, after a point the ball pauses briefly, then is served toward the player who just conceded.
- As the developer, I can change how the score is displayed without touching the goal or ball code.

**Functional requirements**
- [ ] Two goal zones (`Area2D`) behind the paddles, one per side, that detect only the ball.
- [ ] A goal reports *which side* was reached by emitting a signal. It does not touch the score.
- [ ] One node owns both scores. Nothing else stores or mutates them.
- [ ] That owner emits a custom signal (with arguments) whenever a score changes.
- [ ] A HUD on a `CanvasLayer` shows both scores. It has no `_process` and no reference to the score owner's variables.
- [ ] After a goal, the ball stops and is hidden or parked at centre, waits roughly 1 s, then serves toward the conceding side.
- [ ] No goal can be double-counted while the reset is pending.

## Milestones
1. **Goal zones.** Add two `Area2D` goals with collision shapes behind the paddles. Connect `body_entered` and print which goal fired.
   ✅ Done when: the Output panel prints exactly one line per ball entry, on the correct side, and nothing prints when a paddle or wall touches the goal.
   `git commit -m "Add goal areas"`
2. **Custom signals up the tree.** The goal emits its own signal (past tense, carrying whatever the owner needs) rather than doing anything itself. `Main` connects to it. In steps: **(a)** declare the signal at the top of the goal's script; **(b)** `emit` it from the existing `body_entered` handler, replacing the print; **(c)** in `Main`, get a reference to each goal and connect to the signal in `_ready()`; **(d)** write the handler and print the payload.
   ✅ Done when: `Goal` has no reference to `Main`, the score or the ball, and `Main` prints the event.
   `git commit -m "Goals emit signals"`
3. **Score ownership.** `Main` keeps both scores and emits a signal whenever one changes.
   ✅ Done when: scoring ten times in a row yields correct totals in the debugger, and the score variables appear in no other script.
   `git commit -m "Main owns score state"`
4. **HUD.** A `CanvasLayer` with two `Label`s, updated only in response to your score signal. In steps: **(a)** build the layer and labels in the editor and position them; **(b)** write the HUD function that sets both texts from two ints, and test it by calling it from `_ready()` with made-up numbers; **(c)** connect `Main`'s score signal to it, from `Main`, and remove the test call.
   ✅ Done when: the labels change on a goal, the HUD script contains no `_process`, and temporarily deleting the HUD node doesn't crash the game (scores still tracked).
   `git commit -m "Score HUD via signals"`
5. **Reset and re-serve.** After a goal the ball is stopped, waits ~1 s, then serves toward the side that conceded. **(a)** Warm up on a throwaway node: `await` a one-second timer, `print()` before and after, and note the gap. **(b)** Decide which function should wait, and what the ball does meanwhile. **(c)** Wire it into the goal handler.
   ✅ Done when: ten consecutive goals each produce one clean serve in the correct direction, with no double scoring and no ball moving during the delay.
   `git commit -m "Reset and re-serve after goals"`

## Architectural Hints

<details><summary>Hint 1 (nudge): the goal can't detect anything</summary>
Three things have to line up: the ball is on a layer, the goal's mask includes it, and the goal has a shape with non-zero size. Look at Lesson 04's layer reasoning, and decide which side is the "listener".
</details>
<details><summary>Hint 2 (stronger): who should know what?</summary>
Draw three boxes: Goal, Main, HUD. Draw arrows only where one *must* know the other. Goal knows nothing. Main knows its children (so it may connect to their signals). HUD knows nothing about Main's variables, only about the signal's payload. Fewer arrows is better.
</details>
<details><summary>Hint 3 (look up): identifying which goal fired</summary>
Options: give each Goal an `@export` that says which player it belongs to and include it in the signal, or connect each Goal's signal with a bound argument (see `Callable.bind`). Compare the two and pick one deliberately.
</details>
<details><summary>Hint 1 (nudge): the ball keeps scoring while I wait</summary>
Between "goal detected" and "serve" the world is in a state you haven't named. What should the ball be doing then? What should the goal ignore? (This is what Lesson 06 formalises.) For now, think about how to make the ball inert and how to make a second `body_entered` harmless.
</details>
<details><summary>Hint 2 (look up): disabling safely</summary>
Changing collision or monitoring flags inside a physics callback can error with "Can't change this state while flushing queries". Look up `set_deferred` and `call_deferred`.
</details>
<details><summary>Hint 1 (nudge): await behaves oddly</summary>
Who is awaiting, and is that function called from a signal handler? What does the caller do while the coroutine is suspended? If you only need a delay, ask whether a `Timer` node you can `start()` and connect to would make the flow easier to read.
</details>

## Debugging Toolkit
- **Debug → Visible Collision Shapes** in the editor's Debug menu shows goal areas while running.
- **Remote scene tree:** while running, switch the Scene dock to *Remote*, then click a node to see live properties in the Inspector (monitoring, positions, your `@export`s).
- **Node dock → Signals tab** lists connections for a selected node, including editor-made ones. Great for "why isn't this firing".
- `print()` inside handlers, with the arguments, is a reasonable log line. Prefix with the node name so you can tell sources apart.
- **Debugger → Errors/Stack Trace** for `null` instances and "Invalid call" messages.

| Symptom | Inspect |
|---|---|
| Signal handler never runs | Is it connected (Signals tab)? Mask/layer? Shape size? Did the connection happen before the node was ready? |
| Handler runs twice per goal | Connected both in the editor *and* in code? Ball overlapping both goals? |
| "Invalid call. Nonexistent function" | Handler name typo, or the signal's argument count doesn't match the handler |
| Score labels stay at 0 | HUD connected to the signal? Is the emit happening before the HUD is in the tree? |
| Ball serves the wrong way | Which side did the signal report: the scorer or the conceder? Name things to avoid mixing them up |
| Game continues after node freed | An `await` resumed on a stale object; check what you assume still exists |

## Docs
- [Using signals](https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html): **guided walkthrough for milestones 1-2.** Do it in a throwaway scene before building yours. It covers connecting in the editor and in code and custom signals. Type it by hand, delete the scene, then rebuild the idea from memory on your project.
- [GDScript reference: signals and await](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html): read this for `signal`, `.emit()`, `await`, and `Callable` syntax.
- [Area2D class](https://docs.godotengine.org/en/stable/classes/class_area2d.html): read this for `body_entered`, `monitoring`, and layer/mask properties.
- [Using Area2D](https://docs.godotengine.org/en/stable/tutorials/physics/using_area_2d.html): read this for what an area is meant for.
- [Callable class](https://docs.godotengine.org/en/stable/classes/class_callable.html): read this for `bind` and how handlers are referenced.
- [Signal class](https://docs.godotengine.org/en/stable/classes/class_signal.html): read this for `connect`, `emit`, and connection flags.
- [Timer](https://docs.godotengine.org/en/stable/classes/class_timer.html) and [SceneTree](https://docs.godotengine.org/en/stable/classes/class_scenetree.html): read these for `one_shot`/`start` and `create_timer`.
- [CanvasLayer](https://docs.godotengine.org/en/stable/classes/class_canvaslayer.html) and [Label](https://docs.godotengine.org/en/stable/classes/class_label.html): read these for HUD building blocks.
- [Scene organization](https://docs.godotengine.org/en/stable/tutorials/best_practices/scene_organization.html): read this for the "call down, signal up" reasoning (see the sections on dependencies and node ownership).

## Stretch Goals
- Add a short-lived "GOAL!" label that fades in and out in response to the same signal. Judge whether it needed any change to existing scripts. If so, your signals aren't decoupled enough.
- Connect two unrelated listeners to the same signal (HUD and a debug logger) and confirm neither knows about the other.
- Replace the `Timer`/`create_timer` approach with the other one, and write down which was clearer.
- Handle the ball being freed or the scene reloading during the delay without errors.

## Reflection
1. Draw your "who signals whom" diagram. Which arrows go *up* and which go *down*? Any that you broke?
2. What bug appeared when the ball sat in the goal during the delay, and how did you stop it?
3. How would your design change if there were four goals?
