# Lesson 06 · Game States & the CPU Paddle
> **Session goal:** Replace scattered flags with an explicit state machine, add a title screen and game-over flow, and build a beatable CPU opponent. **Time:** ~2 h. **Builds on:** Lesson 05.

## Concepts

### 1. Why booleans rot
Right now "what is the game doing?" is implied by scattered facts: is the ball moving, is the timer running, did someone just score. Add a title screen and a game-over screen and you'll be tracking things like `is_playing && !is_over && !is_waiting`, with combinations that should be impossible but aren't. An explicit **state** collapses all that into one variable that can hold exactly one valid value.

**Bridge:** A systemd unit's `ActiveState` or a Step Functions state machine. Nobody models a service as three booleans. You'd never write `is_running && !is_failed`.

### 2. `enum` + `match`
```gdscript
enum Weather { SUNNY, RAINY, STORMY }
var today: Weather = Weather.SUNNY
match today:
	Weather.RAINY: print("umbrella")
	_: print("fine")
```
`match` is closer to a `switch` that doesn't fall through (no `break` needed), with `_` as the default. Enums are named integers, so use the name, never the number. In JS you'd reach for a string union or `Object.freeze({...})`; this is built in and type-checked.

Three more mechanics you'll need, each shown on weather rather than on your game:
- **An enum is a type.** `var today: Weather` means "this variable can only hold a `Weather` value", and the editor will flag `today = 5` or a typo like `Weather.SNOWY` before you run.
- **A function can take an enum as a parameter**, exactly like any other type: `func forecast(w: Weather) -> String:`. This is your first own, non-callback function with a parameter, so notice that Godot never calls it; *you* call it by name from other places (`forecast(Weather.RAINY)`). A `-> void` function returns nothing; one with `-> String` must hit a `return` on every path.
- **Printing an enum prints its integer.** To get a readable name, look up the `keys()` method that GDScript enums have (the Debugging Toolkit below points at it too).

### 3. One place for transitions
The pattern that scales: a single function (call it whatever you like) that takes the *new* state, does the exit/entry work (show/hide UI, start/stop motion, reset timers), and assigns the variable. Nothing else assigns the state variable directly. Then "what happens when we enter GAME_OVER" has exactly one answer, and you can put a `print` there to log every transition, like a state-change audit log.

Your states: **TITLE** (waiting for a key), **SERVING** (the pause before the ball launches), **PLAYING** (ball live), **GAME_OVER** (winner shown, waiting for restart). Decide on the legal transitions and write them as a table before coding. If you can't draw it, you can't build it.

**Bridge:** Transition table = IAM-style allow-list of edges. Illegal transitions should be loud (assert or error), not silent.

### 4. A beatable CPU
A CPU paddle that matches the ball's y exactly is a perfect, unbeatable controller. Make it imperfect the same way real control loops are imperfect:
- **Rate limit:** its maximum speed is lower than the ball's potential vertical speed. Cheap and effective.
- **Dead zone:** ignore errors smaller than some tolerance, so it doesn't jitter. This is hysteresis.
- **Reaction lag:** only update its target every so often rather than every frame, or only react when the ball is on its half.

The shape: *measure error → decide direction → move at capped speed → repeat.* No prediction required. Tune the numbers via `@export` while the game is running.

**Bridge:** Autoscaling with cooldowns and step limits, or a PID with only a P term and output clamping. Lag and rate limits are what make it settle imperfectly.

### 5. Human or CPU without duplicating the paddle
You want one Paddle scene. Options:
- **Exported mode** (an `enum` or `bool` on the paddle): simple, but the paddle script now holds both input code and AI code, and grows a branch for every new controller.
- **Swappable controller child** (a small node/script that produces "move direction" and the paddle just consumes it): paddle stays dumb, controllers are interchangeable, and each is testable alone. A bit more wiring up front.
- **Signals/intent:** the controller emits "desired direction" and the paddle listens. More decoupled still, but probably overkill here.

Pick one and justify it in your PROGRESS.md. The controller option is the more transferable skill, but the exported mode is a legitimate choice at this scale.

**Bridge:** Strategy pattern. Same interface, different backend. Like pointing one load balancer config at different target groups.

### 6. Building a title / game-over overlay
You already have a HUD on a `CanvasLayer` (Lesson 05). Overlays use the same ingredients, plus a few layout tools:
1. **Where it goes.** Add a second `CanvasLayer` (or a `Control` under your HUD layer) so the overlay draws above the game and ignores any camera. Name it for what it is, not "CanvasLayer2".
2. **Layout.** Add a `Control` child (or a `ColorRect` for a dim backdrop) and, with it selected, use the toolbar's **Anchor Preset** dropdown in the 2D viewport (or Inspector > Layout) and pick **Full Rect**. Anchors pin each edge of a `Control` to a fraction of its parent, so the overlay follows the window size. Add `Label`s inside it; give each a preset such as **Center** and set Horizontal/Vertical Alignment on the label for text. Read [Size and anchors](https://docs.godotengine.org/en/stable/tutorials/ui/size_and_anchors.html) for the model: anchors say *where the box attaches*, offsets say *how far from there*.
3. **Show and hide.** Every `CanvasItem` (so every `Control` and `Label`) has a `visible` property and `show()` / `hide()` methods. Hiding a parent hides its whole subtree. `visible` is just a property, so `lamp_panel.visible = false` and `lamp_panel.hide()` are equivalent. In the editor, the eye icon in the Scene dock sets the starting value.
4. **Referencing it from code.** The script that owns the state needs a handle on the overlay nodes. You've used `@onready var x = $Child` for your own children (Lesson 01); for a node elsewhere in the tree, `@export var overlay: Control` lets you drag it in via the Inspector, and the type tells autocomplete what you can call on it.

### 7. A key press as an event
Starting a game or restarting is a one-off *edge*, not a held state (Lesson 02, concept 2). Override `_unhandled_input(event: InputEvent)` and test `event.is_action_pressed("some_action")`. Unlike `Input.is_action_pressed`, this is a method *on the event*, true once for the press that triggered this call. Define the action in the Input Map first (a "start" action and, for the mode choice, a key each). The callback fires in every state, so what the press *means* depends on what the game is doing right now; that is a question for your state variable.

### 8. Switching a node off, and how a parent talks to a child script
- **Processing on and off.** Every node has `set_process(bool)` and `set_physics_process(bool)`; calling them with `false` stops that node's `_process` / `_physics_process` callbacks without freeing it. The Inspector's `process_mode` (Node > Process > Mode) is the config-time version; `Disabled` there stops the node and, by inheritance, its children. Signals and the node's own properties keep working while it's off.
- **Reaching a child's script.** `$Controller` gives you the child *node*. If its script defines `var reach: float` or `func wave()`, you can read `$Controller.reach` or call `$Controller.wave()` directly, since parents may call down (Lesson 05). With `@onready var ctl: Node = $Controller`, the type `Node` doesn't know about `reach`, so GDScript resolves it at runtime; give the script a `class_name` (see "Registering named classes" in the GDScript reference) and declare `@onready var ctl: Controller` to get editor checking.
- **Turning children on and off.** A node can have several children that each have a script, and processing can be switched on or off for each child independently. Keep that tool in mind when you weigh the options in concept 5. It's one possible mechanism, not the required design.

## Spec
**User stories**
- As a player, I see a title screen and press a key to begin.
- As a player, I see who won when someone reaches the target score and can start a new game.
- As a player with no friend around, I can play against a CPU I can actually beat.

**Functional requirements**
- [ ] A single state variable of an `enum` type with TITLE, SERVING, PLAYING, GAME_OVER.
- [ ] A single function owns all transitions; nothing else writes the state variable.
- [ ] `match` (or equivalent) decides what's active per state: e.g. paddles accept input only in the right states, the ball moves only in PLAYING.
- [ ] `points_to_win` is an `@export var` on the script that owns the score; change it in the Inspector, not the code.
- [ ] Game over shows the winner. A key press returns to TITLE or starts a new game.
- [ ] A way to choose 1-player or 2-player on the title screen (two keys is fine).
- [ ] CPU paddle uses the same Paddle scene, with speed cap and dead zone exposed via `@export`.
- [ ] An easy way to see the current state while running (printed or on-screen debug label).

## Milestones
1. **Design the state machine on paper.** List states, events and legal transitions in your notes (a table or sketch).
   ✅ Done when: every state has at least one way in and one way out, and every event from Lesson 05 (goal, delay finished) has a place in the table.
2. **State enum and single transition function.** Introduce the enum and route everything through it, leaving behaviour unchanged except that the game starts in SERVING. Take it in three steps:
   - **a. Declare.** Write the `enum` and a member variable typed with it (concept 2), on the script that owns the score.
   - **b. The function.** Write your own function that takes the new state as a typed parameter and returns nothing. At first have it only log the old and new names and assign the variable.
   - **c. Move behaviour in.** One existing behaviour at a time, relocate it from wherever it lives now into the matching `match` branch of that function, running the game after each move.
   ✅ Done when: grepping for the state variable shows exactly one assignment, and a log line prints on every transition.
   `git commit -m "Introduce game state enum"`
3. **Title and game-over screens.** Add UI for TITLE and GAME_OVER (visibility toggled by state), start with a key press, and check `points_to_win` after each score. Take it in three steps:
   - **a. Build the overlay in the editor** with a layer, a full-rect `Control`, and labels (concept 6). Check it looks right at a different window size, then hide it with the eye icon.
   - **b. Show and hide from code** (concept 6): get the overlay nodes into your script, and make the transition function's branches set their visibility.
   - **c. Wire the key press** with `_unhandled_input` (concept 7). Add the action to the Input Map, and decide what the press does in each state.
   ✅ Done when: reaching `points_to_win` shows the correct winner, the ball stops, and one key press gets you into a fresh game with scores at zero. Changing `points_to_win` in the Inspector changes the game without code edits.
   `git commit -m "Title and game over flow"`
4. **Guard the states.** Make sure nothing misbehaves in the wrong state.
   ✅ Done when: on the title screen the paddles don't move and the ball doesn't exist or is still; mashing keys in GAME_OVER never starts a second serve.
   `git commit -m "Gate behaviour by state"`
5. **CPU controller.** Implement the controller approach you chose and a 1-player option on the title screen. Take it in three steps:
   - **a. Mode flag.** Get a 1P/2P choice from two keys on the title screen into a variable, before any AI exists. Print it.
   - **b. Producer.** Write the CPU's decision as its own piece (concept 4) and test it with a `print` of what it would do, before connecting it to a paddle.
   - **c. Connect and gate.** Hook it to the paddle using your chosen option from concept 5, and use concept 8 to make sure only one producer is active at a time.
   ✅ Done when: in 1-player mode the right paddle tracks the ball; in a rally you can reliably out-angle it with edge hits; the human controls and the CPU never both drive the same paddle.
   `git commit -m "CPU paddle"`
6. **Tune.** Adjust the exported values live (Remote tree or editor) until the CPU wins roughly 30-40% of points against you.
   ✅ Done when: you can state the values you settled on and why.
   `git commit -m "Tune CPU difficulty"`

## Architectural Hints

<details><summary>Hint 1 (nudge): where does the state live?</summary>
Same answer as the score: one owner. Ask what else needs to *know* the state (HUD, ball, paddles) and whether that should be via a signal when it changes or via the owner calling down.
</details>
<details><summary>Hint 2 (stronger): the transition function</summary>
Think of it as having two jobs: leave the old state, enter the new one. Which of your existing behaviours (serve delay, ball launch, score reset, label visibility) are "on entering X" actions? Moving them there removes most of the flags you currently carry.
</details>
<details><summary>Hint 3 (look up): typing the state</summary>
Look in the GDScript reference for how enums act as types, and for `match` with enum values. Also look up `assert` for asserting illegal transitions.
</details>
<details><summary>Hint 1 (nudge): the CPU is perfect or twitchy</summary>
Perfect means its max speed is too high or has no lag. Twitchy means it reacts to errors too small to matter. Which of the three imperfection tools fixes which symptom?
</details>
<details><summary>Hint 2 (stronger): where does the CPU's decision go?</summary>
The paddle already turns a "direction" into movement (Lesson 02). What if the thing that *produces* the direction could be swapped? Decide what the shared interface is (a number each frame? a method? a signal?), then write two producers.
</details>
<details><summary>Hint 3 (look up)</summary>
Methods/properties worth reading: `move_toward`, `absf`/`signf`, `clampf`, and `Node.set_process`/`set_physics_process` or `process_mode` for turning controllers off in the wrong states.
</details>
<details><summary>Hint 1 (nudge): input in GAME_OVER also triggers a serve</summary>
The same key event is probably handled by two places. Which should win in which state, and does `match` on the current state in the input handler make that explicit?
</details>

## Debugging Toolkit
- **Log every transition** with old and new state names. You get an audit trail for free. Printing an enum gives an int; look up how to get its name (`Enum.keys()`).
- Show the state in a debug `Label` on a `CanvasLayer` while developing.
- **Remote scene tree:** edit your CPU `@export` values live and watch behaviour change without restarting.
- **Breakpoints:** click the gutter in the script editor, run with the debugger, step through the transition function.
- Visible collision shapes remain useful for "ball exists but frozen" bugs.

| Symptom | Inspect |
|---|---|
| Game stuck in SERVING | Which event moves it to PLAYING? Is the signal/timer for that connected, and does it run in this state? |
| Winner label shows wrong player | Does your scored signal report scorer or conceder? Check the naming |
| Both players control one paddle in 1P mode | The human controller is still active; check who disables it |
| CPU jitters around the ball | Dead zone too small or zero; also check for overshoot from large per-frame steps |
| CPU never misses | Speed cap high, no lag; check also that you aren't giving it perfect knowledge on every frame |
| Restart keeps old scores | What resets on entering TITLE or SERVING? Is anything not part of that? |

## Docs
- [GDScript reference: enums and match](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html): read this for `enum` and `match` syntax.
- [Static typing in GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/static_typing.html): read this for typed enums and typed signal parameters.
- [GDScript exported properties](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_exports.html): read this for `@export`, ranges, and enum exports.
- [Scene organization](https://docs.godotengine.org/en/stable/tutorials/best_practices/scene_organization.html): read this for composition vs. branching in scenes.
- [Node class](https://docs.godotengine.org/en/stable/classes/class_node.html): read this for `process_mode` and `set_process` for enabling or disabling behaviour.
- [Button class](https://docs.godotengine.org/en/stable/classes/class_button.html): read this if you build the title screen with buttons rather than key presses.
- [Size and anchors](https://docs.godotengine.org/en/stable/tutorials/ui/size_and_anchors.html): read this for anchor presets and full-rect overlays.
- [InputEvent](https://docs.godotengine.org/en/stable/tutorials/inputs/inputevent.html): read this for `_unhandled_input` and `is_action_pressed` on an event.
- [Control node gallery](https://docs.godotengine.org/en/stable/tutorials/ui/control_node_gallery.html): read this for a quick tour of UI controls.
- [@GlobalScope math functions](https://docs.godotengine.org/en/stable/classes/class_@globalscope.html): read this for `move_toward`, `clampf`, `signf`, and friends.

## Stretch Goals
- Add a difficulty setting on the title screen that changes the CPU's exports.
- Let the CPU make deliberate mistakes: occasionally target the wrong position by an error amount. Compare to just lowering speed.
- Add a second CPU so both paddles are controlled by AI (attract mode on the title screen).
- Write the transition table as data (a dictionary of allowed edges) and validate transitions against it.

## Reflection
1. Which booleans did your state enum delete? Was any of them hard to remove?
2. Which paddle-control approach did you pick, and what would make you regret it?
3. What did you change to make the CPU beatable, and which of the three tools worked best?
