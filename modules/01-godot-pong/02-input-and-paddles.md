# Lesson 02 · Input & Paddles
> **Session goal:** Define input actions, build a reusable Paddle scene, instance it twice with different controls, and keep both on screen. **Time:** ~2 h. **Builds on:** Lesson 01.

Before you start: delete the throwaway rectangle and script from Lesson 01 (or keep it only until your first paddle works).

## Concepts

### 1. The Input Map: actions, not keys
Project Settings > Input Map lets you name **actions** (e.g. `jump`, `fire`) and bind physical inputs (keys, gamepad buttons, axes) to each. Code asks about the action, never the key. Rebinding then needs no code change, and one action can have several bindings (keyboard and gamepad).
```gdscript
if Input.is_action_pressed("fire"):
```
**Bridge:** Actions are IAM roles vs. users, or DNS names vs. IPs: callers reference a stable logical name, and the binding behind it can change.

### 2. Polling vs. event callbacks
- **Polling:** each frame, ask the `Input` singleton for the current state. `Input.is_action_pressed(action)` is true while held; `Input.get_axis(negative, positive)` returns a float from -1 to 1 built from two actions; `Input.get_vector(...)` does the same for 2D. Best for continuous state ("is the key held?").
- **Events:** override `_input(event)` or `_unhandled_input(event)` and Godot calls you once per input event. Best for discrete things ("pressed once", "toggle pause"). `_unhandled_input` only receives events nobody else (for example, UI controls) consumed.

**Bridge:** Polling is a health check on an interval; events are webhooks / interrupts. Held-key movement is a level (state), a press is an edge (event). `Input.is_action_just_pressed` gives you the edge when polling.

### 3. Who drives the motion? Choosing a body type
Godot's 2D physics bodies differ mainly in who owns movement:

| Node | Driven by | Typical use |
|---|---|---|
| `StaticBody2D` | Nobody; it doesn't move (or you teleport it) | Walls, floors |
| `CharacterBody2D` | **Your code** sets motion; engine does collision queries | Players, paddles, scripted movers |
| `RigidBody2D` | **The physics engine** (forces, mass, gravity) | Crates, balls you want to behave "realistically" |
| `Area2D` | Nobody; it detects overlaps, doesn't block | Triggers, goals, pickups |

For a paddle, the player decides where it goes, so you want code in control. Decide between `CharacterBody2D`, `AnimatableBody2D`, or a bare `Node2D`/`StaticBody2D` that you move manually, and write down your pick and why. Think ahead to Lesson 04: the ball will need to detect hitting it. A body that has a collision shape is something the ball can collide with; one without is invisible to physics.

**Bridge:** Declarative (`RigidBody2D`: you describe the forces and the engine converges) vs. imperative (`CharacterBody2D`: you run the steps). It's the Terraform vs. shell-script distinction.

### 4. Collision shapes
A physics body does nothing alone; it needs a `CollisionShape2D` child with a `Shape2D` resource (e.g. `RectangleShape2D`) to give it a physical extent. The editor warns you when it's missing. The visual (`ColorRect`, `Sprite2D`) and the collision shape are independent: they must be sized to match by you. Keep them aligned so what you see is what hits.

**Bridge:** The sprite is the UI; the collision shape is the ACL/security-group rule. They're configured separately, and mismatches are bugs.

### 5. Reusable scenes and per-instance parameters
Save the paddle as its own scene (`paddle.tscn`) with its own script. Drop that scene into `main.tscn` twice (Scene dock: instantiate child scene, or drag from FileSystem). Each instance is independent, can be moved and renamed, and has its own `@export` values overridden in the Inspector, without modifying `paddle.tscn`.

Design question: the two paddles differ by which input actions they respond to. Where should that difference live: in two scripts, in `if` branches on a node name, or in exported configuration? Parameters on the instance is the usual answer.

**Bridge:** One launch template (AMI + user-data), two instances launched with different tags/parameters.

### 6. `_process` vs. `_physics_process`
`_process(delta)` runs once per rendered frame, so its rate varies. `_physics_process(delta)` runs on a fixed tick (60 Hz by default), synchronised with the physics engine, so `delta` is nearly constant. Anything that interacts with physics bodies (moving them, querying collisions) belongs in `_physics_process`. Purely visual updates belong in `_process`.

**Bridge:** `_process` is "as fast as the box can", `_physics_process` is a cron/fixed-rate tick. Fixed ticks give deterministic simulation.

### 7. Reading the screen size and clamping
`Viewport.get_visible_rect()`, or the node shortcut `get_viewport_rect()`, returns a `Rect2` of the visible area. The global `clampf()` / `clamp()` functions constrain a value to a min and max. Think about where a paddle's position is measured from (its centre? its top-left?) and how its height changes the bounds.

### 8. Editor workflows you haven't done yet
Do these once in a scratch scene and they stop being scary:
- **Add a binding in the Input Map.** Project > Project Settings > **Input Map** tab. Type a name in the "Add New Action" box and press **Add**. The new action appears in the list; click the **+** at the right of its row, then press the physical key in the capture dialog and confirm with OK. Each action can hold several bindings. (If the list looks empty, tick "Show Built-in Actions" only to *see* the `ui_*` defaults; your own actions are listed regardless.)
- **Create a scene from scratch.** Scene menu > **New Scene**. In the Scene dock, pick a root node type (the "Other Node" button lets you search all types). Save with **Ctrl+S**; the dialog asks for a path under `res://` and a file name, and the file is a `.tscn`. A scene's root is the node whose script and exports define the scene's public face.
- **Give a body a physical shape.** Select the body root, press the **+** (Add Child Node) button, pick `CollisionShape2D`. It shows a warning triangle because its `shape` property is empty. In the Inspector click the empty **Shape** slot, choose **New RectangleShape2D**, then click the shape itself (it expands) and set its **Size**, or drag the orange handles in the viewport. The shape is a *resource* (a small data object stored inside the scene), distinct from the node that holds it. The same dance works for a visual: add a `ColorRect` child and set its size and colour.
- **Line a visual up with a shape.** A `CollisionShape2D` is centred on its own position, while a `ColorRect` draws from its top-left corner at its own position. So two equal sizes will not overlap until you offset one of them. Turn on Debug > Visible Collision Shapes to see the mismatch, then decide which node to move and by how much (the Inspector shows each node's position and size).
- **Instance a saved scene.** Open the destination scene, then either drag the `.tscn` from the FileSystem dock into the Scene dock/viewport, or use the chain-link **Instantiate Child Scene** button at the top of the Scene dock. Instances show a "clapperboard" icon. Selecting one shows its root node's properties, including the `@export`s from the script, and edits made there are stored in the *destination* scene's file, not in the original.

**Bridge:** the saved scene is the template; each instance in `main.tscn` is a small diff (overrides) layered on top, much like a Helm chart plus a values file.

### 9. Language mechanics for this lesson
- **Typed exports for names.** `@export var mode: String = "idle"` puts a text box in the Inspector. Godot also has `StringName`, an interned, cheap-to-compare string type that the Input API uses for action names. Writing `@export var door_action: StringName = &"open"` works the same way (the `&"..."` literal makes a StringName). Either type is fine here; see the `StringName` class page and the `Input.get_axis` signature to see what it accepts.
- **A variable can be passed straight in.** `Input.is_action_pressed(my_variable)` uses whatever the variable holds, exactly like passing a string argument in JS.
- **Reading the viewport.** `get_viewport_rect()` returns a `Rect2`, a rectangle with `position` and `size` fields, and `size` is itself a `Vector2`. So reading its height is `rect.size.y`, a chain of property reads like JS `a.b.c`.
- **Clamping.** `clampf(value, min, max)` returns `value` pulled into the range. It *returns* a result and doesn't change the variable, so assign it back: `lamp_level = clampf(lamp_level, 0.0, 1.0)`.
- **Reading another node's data.** The collision shape lives in a child node, so a script on the root can reach it with `$CollisionShape2D` (the same `$Name` shortcut as in the `@onready` example in Lesson 01 concept 3), then read `.shape.size` from it. Names in `$` must match the node's name in the Scene dock exactly.

## Spec

**User stories**
- As player 1, I move my paddle up and down with W and S.
- As player 2, I move mine with the Up and Down arrow keys.
- As a player, my paddle never leaves the visible play area, and it stops cleanly at the edges.
- As the developer, I can change which keys a paddle uses without editing the script.

**Requirements**
- [x] Four actions are defined in the Input Map, named by you with a consistent scheme (player prefix and direction).
- [ ] `paddle.tscn` is a standalone scene with a visual, a collision shape, and one script.
- [ ] The paddle script has exported variables for its up action, down action and speed. The Inspector shows them on each instance.
- [ ] `main.tscn` instances the paddle scene twice, one on the left and one on the right, with different action names set on each.
- [ ] The script contains no hard-coded key names (no `KEY_W` and no raw action strings baked into its logic as the only option).
- [ ] Movement is in pixels per second, scaled by `delta`, and runs in the physics tick.
- [ ] Both paddles are fully clamped inside the viewport, including the paddle's own half height.
- [ ] Both paddles can move at the same time (two players on one keyboard).
- [ ] The Lesson 01 throwaway is gone.

## Milestones

1. **Define the actions.** In Project Settings > Input Map, add four actions, and bind keys (concept 8 has the click path).
   - **a.** Add the four actions with a naming scheme you can explain (player prefix and direction).
   - **b.** Bind one key to each.
   - **c.** Temporarily attach a script to your Lesson 01 throwaway rectangle (it's still there, and is deleted later) and poll each action in `_process`, printing only when pressed.
   ✅ **Done when:** All four actions appear in the list with a binding, and the temporary `print` proves each fires only when its key is held. Remove the print afterwards.
   *Commit.*

2. **One paddle moves.** Build `paddle.tscn`. Take it in steps:
   - **a. New scene.** Scene > New Scene, choose the root type you picked from the table in concept 3, rename the root to something sensible, and save as `paddle.tscn` (concept 8).
   - **b. Visual and shape.** Add a `ColorRect` and a `CollisionShape2D` with a new `RectangleShape2D` of matching size, and make them line up (concept 8). Check with Debug > Visible Collision Shapes.
   - **c. Script.** Attach `paddle.gd` to the *root*. Use the F1/Ctrl+click tools from Lesson 01 concept 7 to find the `Input` axis helper in the hints below.
   - **d. Instance it once** into `main.tscn` so you can press F5, and move it vertically from input for one hard-coded player, using polling inside the right callback (concept 6).
   ✅ **Done when:** In the running game, holding the up key moves it up at a steady speed, holding the down key moves it down, releasing stops it. Holding both does not move it (net zero). Speed doesn't change if you alter Max FPS.
   *Commit.*

3. **Make the controls a parameter.** Add `@export` variables so that the paddle's actions and speed come from the Inspector. Make the script read them instead of fixed names.
   - **a.** Declare the exports at the top of the file (concept 9 covers the types), save, and confirm they appear in the Inspector on the paddle instance.
   - **b.** Give each a default that matches your first player's actions.
   - **c.** Replace each fixed name in your movement code with the matching variable.
   ✅ **Done when:** Changing the exported action names on the instance in the Inspector changes which keys control it, with no script edit.
   *Commit.*

4. **Instance it twice.** In `main.tscn`, instance the paddle scene twice, position one at the left and one at the right, and set the second instance's actions to the other player's. Delete the Lesson 01 throwaway.
   - **a. Guided walkthrough (optional, ~15 min).** If instancing felt shaky, read the official [Instancing](https://docs.godotengine.org/en/stable/getting_started/step_by_step/instancing.html) tutorial in a throwaway scene, typing nothing into your project, then close it.
   - **b.** Add the second instance and rename the two nodes so the tree reads clearly (for example by player).
   - **c.** Select each instance, move it, and override its exports in the Inspector. Watch that `paddle.tscn` doesn't show as modified in git.
   ✅ **Done when:** Both paddles are controlled independently at the same time (hold W and Up simultaneously and both move). `paddle.tscn` and `paddle.gd` are unchanged after setting up the second instance beyond the first.
   *Commit.*

5. **Clamp to the viewport.** Restrict vertical position to the visible area, taking the paddle's size into account.
   - **a. On paper.** With the viewport height and the paddle's height as symbols, write the smallest and largest legal `position.y`, given where the origin sits (concept 7).
   - **b. Find the inputs.** Work out how your script will read the viewport height and the paddle's height (concept 9).
   - **c. Apply.** Constrain the position right after you move it in the same tick, and test against both edges.
   ✅ **Done when:** Holding a direction key against an edge leaves the paddle's visible edge exactly flush with the window edge: no gap, no overshoot, no jitter. Changing the viewport height in Project Settings (Lesson 01) keeps working without code changes, and changing the paddle's size in the Inspector too (if you derive it from the node rather than a literal).
   *Commit.*

## Architectural Hints

<details><summary>Hint 1 (nudge): Which body type?</summary>

Ask who decides the paddle's position each frame. If the answer is "the player's input, directly", you don't want a physics engine integrating forces on it. Also ask what Lesson 03's ball needs to detect when it touches the paddle. Both questions narrow the list to two choices; either is defensible if you can say why.
</details>
<details><summary>Hint 2 (stronger nudge)</summary>

Pick `CharacterBody2D` unless you can argue otherwise. It exists for "code sets the motion, engine handles collision". Note that it has its own `velocity` property and movement methods meant for this. For a paddle that only moves along one axis, you may decide you don't need them, and may set `position` directly. Weigh that choice and note it in PROGRESS.md.
</details>
<details><summary>Hint 3 (look this up)</summary>

Read the `CharacterBody2D` class reference (`move_and_slide`, `velocity`) and the "Using CharacterBody2D" page. Compare it against just writing to `position`. What does each cost you when the ball arrives in Lesson 03/04?
</details>

<details><summary>Hint 1 (nudge): Direction from input</summary>

You need a single number in the range -1..1 that represents "up", "down" or "neither". Two held keys should cancel out. Check whether `Input` already has a helper that combines two actions into that value.
</details>
<details><summary>Hint 2 (stronger nudge)</summary>

You already solved "rate × elapsed time" for the Lesson 01 drift. What's new is that the *sign* of the motion now comes from the player instead of being fixed. Which of your three ingredients (sign, rate, time step) comes from input, which from configuration, and which from the engine?
</details>
<details><summary>Hint 3 (look this up)</summary>

Look at `Input.get_axis(negative_action, positive_action)`. Remember that in Godot's 2D coordinates, y grows downward, so "up" is the negative side.
</details>

<details><summary>Hint 1 (nudge): Per-instance actions</summary>

Exported variables can have any type. Think about what type holds an action name and what default makes sense. The values are stored in `main.tscn`, per instance, not in `paddle.tscn`.
</details>
<details><summary>Hint 2 (stronger nudge)</summary>

Action names are strings, but a dedicated string-like type exists for them in the Input API. Declare exported variables of that type (or plain `String` if you prefer). Check how the Inspector shows each.
</details>
<details><summary>Hint 3 (look this up)</summary>

`@export var` with a `StringName` or `String` type; see the `Input.get_axis` signature to see what types it takes. If a mistyped action name triggers an error, read the Debugger's Errors tab.
</details>

<details><summary>Hint 1 (nudge): Clamping</summary>

Two numbers define the legal range of the paddle's y: the lowest and highest value that keeps the whole rectangle on screen. Where is the paddle's origin relative to its rectangle? If it's the centre, how far from each edge must it stay?
</details>
<details><summary>Hint 2 (stronger nudge)</summary>

Compute the min and max from the viewport height and the paddle's half height, then constrain after you move. Don't hard-code 720 or 100; you'll change those later. Where can you read the paddle's height from, so there is one source of truth? (Your collision shape's size, or an export.)
</details>
<details><summary>Hint 3 (look this up)</summary>

`CanvasItem.get_viewport_rect()` -> `Rect2` (see `size`), the global `clampf()` in `@GlobalScope`, and `RectangleShape2D.size`. Mind that sizes can be scaled by the node's `scale`.
</details>

## Debugging Toolkit
- **Debug > Visible Collision Shapes** (editor Debug menu) draws collision shapes while the game runs. Use it to check the shape matches the visual.
- **Remote scene tree**: select each paddle instance and read its exported values and position live. Compare the two instances.
- **`print()`** the axis value and position for one tick to verify sign and units. Remove it after; per-tick prints flood the Output.
- **Debugger > Errors / Output**: invalid action names produce errors naming the action.
- **Symptoms to causes**
  - Paddle doesn't move: is the script attached to the paddle scene root (not a child)? Are the actions spelled identically to Input Map entries? Did you edit the instance's exports in `main.tscn` rather than in `paddle.tscn`?
  - Both paddles respond to the same keys: the instance exports were not overridden, or you're setting them on the wrong node. Check the Remote tree.
  - Moves down when you press up: y grows downward. Check which action you passed as negative.
  - Speed differs between machines: missing delta or the wrong callback.
  - Paddle overshoots the edge by half its height, or stops with a gap: the origin is not where you assumed. Check the origin point in the viewport and your bounds math.
  - Jitter at the edge: movement applied after the constraint, or the constraint ignoring the new position.
  - Collision shape warning in the Scene dock: a shape resource isn't set on the `CollisionShape2D` in the Inspector.
  - Changing the shape size in one instance changes both: shape resources are shared between instances by default; look at the resource's "local to scene" option only if you hit this.

## Docs
- [Input examples](https://docs.godotengine.org/en/stable/tutorials/inputs/input_examples.html): read for polling vs. event callbacks, and the Input Map.
- [Using InputEvent](https://docs.godotengine.org/en/stable/tutorials/inputs/inputevent.html): read for how events propagate (`_input`, `_unhandled_input`) and what the action system does.
- [Input class reference](https://docs.godotengine.org/en/stable/classes/class_input.html): read `get_axis`, `get_vector`, `is_action_pressed`, `is_action_just_pressed`.
- [InputMap class reference](https://docs.godotengine.org/en/stable/classes/class_inputmap.html): actions in code, for stretch goals.
- [Listening to player input](https://docs.godotengine.org/en/stable/getting_started/step_by_step/scripting_player_input.html): read for the beginner view of input in a script.
- [Physics introduction](https://docs.godotengine.org/en/stable/tutorials/physics/physics_introduction.html): read for the body types, who moves them, and collision shapes.
- [Using CharacterBody2D](https://docs.godotengine.org/en/stable/tutorials/physics/using_character_body_2d.html): read to decide whether you need its movement methods.
- [Collision shapes (2D)](https://docs.godotengine.org/en/stable/tutorials/physics/collision_shapes_2d.html): read for adding shapes to bodies and the gotchas.
- [CharacterBody2D](https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html), [StaticBody2D](https://docs.godotengine.org/en/stable/classes/class_staticbody2d.html), [RigidBody2D](https://docs.godotengine.org/en/stable/classes/class_rigidbody2d.html), [Area2D](https://docs.godotengine.org/en/stable/classes/class_area2d.html): skim each description paragraph.
- [CollisionShape2D](https://docs.godotengine.org/en/stable/classes/class_collisionshape2d.html) and [RectangleShape2D](https://docs.godotengine.org/en/stable/classes/class_rectangleshape2d.html): read for `shape` and `size`.
- [Idle and physics processing](https://docs.godotengine.org/en/stable/tutorials/scripting/idle_and_physics_processing.html): read for `_process` vs. `_physics_process`.
- [Viewport class reference](https://docs.godotengine.org/en/stable/classes/class_viewport.html) and [Node class reference](https://docs.godotengine.org/en/stable/classes/class_node.html): for `get_visible_rect` and `get_viewport`; check what shortcut exists on `CanvasItem` ([class_canvasitem](https://docs.godotengine.org/en/stable/classes/class_canvasitem.html)).
- [@GlobalScope](https://docs.godotengine.org/en/stable/classes/class_%40globalscope.html): `clamp`, `clampf` and friends.
- [PackedScene](https://docs.godotengine.org/en/stable/classes/class_packedscene.html): what a saved scene is as an object.
- [Scene organization](https://docs.godotengine.org/en/stable/tutorials/best_practices/scene_organization.html): read for how scenes should be self-contained and configured from outside.
- [GDScript exports](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_exports.html): for `@export` on various types.

## Stretch Goals
- Support a gamepad: add a joystick axis or d-pad binding to each action, with no script changes.
- Add an acceleration/deceleration curve so the paddle eases in and out. Describe the control-loop analogy in PROGRESS.md.
- Support `Input.get_vector`-style input by letting the paddle optionally move horizontally too. Only if you can keep the script free of special cases.
- Make the paddle's height an export and have both the visual and the collision shape follow it from one place.

## Reflection
1. What did you choose as the paddle's root node type, and what would break or get harder with each of the alternatives?
2. Where does the "which player am I" information live now, and why is that better (or worse) than two separate scripts?
3. You used polling for movement. Name one thing in Pong where an event callback would be the better fit, and say why.
