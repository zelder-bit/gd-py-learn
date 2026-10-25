# Lesson 01 · Editor, Scene Tree & GDScript Basics
> **Session goal:** Create the Pong project, get oriented in the editor, and write your first GDScript that moves a throwaway object using `delta`. **Time:** ~1.5-2 h. **Builds on:** nothing (first lesson).

Launch Godot from `/home/citrus/.local/opt/godot/Godot_v4.7.2-stable_linux.x86_64`. Everything you build goes in `projects/01-pong/`.

## Concepts

### 1. Nodes, scenes, scripts
- A **node** is the atom: one small piece of behaviour (`Node2D` has a position, `ColorRect` draws a rectangle, `Timer` counts down).
- A **scene** is a tree of nodes saved to a `.tscn` file. Every scene has exactly one root node. A scene can be instanced inside another scene, so a scene is also a reusable "type".
- A **script** (`.gd`) is attached to one node and extends its behaviour. A script is a class; the node is an instance of it.
- The **scene tree** is the live tree of all running nodes. The running game is just your main scene loaded into it.

**Bridge:** The tree is a process tree (parents own children, killing a parent kills the subtree) and also a filesystem (paths like `Main/Paddle/Sprite`). A scene is a CloudFormation nested stack or a launch template: a saved definition you can instantiate many times. A script is the user-data you attach to one resource.

### 2. The editor layout
Spend 10 minutes clicking everything. You need: **Scene dock** (the tree of the open scene), **FileSystem dock** (`res://`, your project root), **Inspector** (properties of the selected node, including script variables marked `@export`), **2D viewport** (visual editing), **Output / Debugger** panels at the bottom (print output, errors, and the live Remote tree while the game runs).

**Bridge:** `res://` is a path rooted at the project dir, like a chroot. The Inspector is a live editor for resource config, close to the console view of a resource's properties.

### 3. GDScript 2.0, by diff from JavaScript
- Indentation (tabs by default) replaces braces; no semicolons. Every `.gd` file is implicitly a class; `extends Node2D` says what it inherits.
- `var` declares a variable (like `let`). `const` is a compile-time constant. Types are optional but you will use them: `var lives: int = 3`, or inferred with `:=` as in `var name := "x"`.
- `func name(arg: float) -> void:` replaces `function`. The `->` is the return type.
- `self` replaces `this` (and is usually implicit). `null`, `true`/`false`, `and`/`or`/`not` (the symbolic forms also work). `==` is value comparison and there is no `===`.
- Dictionaries are `{}` like JS objects; arrays are `[]`. `print()` writes to the Output panel. `#` starts a comment.
- `@export var speed: float = 100.0` exposes a variable in the Inspector. `@onready var label = $Label` assigns when the node enters the tree and its children exist.
- Static typing is optional but catches errors in the editor before runtime. Turn it into a habit now.

**Bridge:** Think of typed GDScript as TypeScript to JS's JavaScript: same shapes, but the editor tells you when you misuse them. `@export` is a CloudFormation Parameter; the value lives in the scene file, not in code.

### 4. Lifecycle callbacks
Godot calls specific method names on your nodes if they exist. Two matter today:
- `_ready()`: called once when the node and all its children are in the tree. Setup goes here.
- `_process(delta)`: called every rendered frame. `delta` is the seconds elapsed since the last frame (a float, like 0.0166 at 60 fps).

Rate times elapsed time is distance. If something should move 200 px per second, a per-frame step must be scaled by `delta`, otherwise it runs faster on faster machines.

**Bridge:** The frame loop is a control loop / reconciler, running over and over. `delta` is the same normalisation you do when you compute a rate from counters sampled at irregular intervals (bytes per second from two `/proc/net/dev` reads). Per-frame increments without `delta` are like alerting on raw counter values instead of rates.

### 5. Project Settings and the main scene
Project Settings (Project menu) holds project-wide config in `project.godot`, a plain-text file you can diff and commit. The **main scene** is what runs on F5. Run the project with F5 and the current scene with F6.

**Bridge:** `project.godot` is the config file; the `.godot/` directory is the cache (like `node_modules/` or `.terraform/`). Commit the first, ignore the second.

### 6. Anatomy of the script Godot generated for you
Open the `.gd` file you attached in milestone 3 and read it line by line before you change anything:
- **`extends ColorRect`** means this script *is* a `ColorRect`, with extra behaviour added. Every property you can see in that node's Inspector (its colour, size, position…) belongs to your script too, and you can read or assign it **by name, with no prefix**. JS bridge: inside a class method, it's as if `this.` were always implied.
- **`func _ready() -> void:`** and **`func _process(delta: float) -> void:`** are the two lifecycle hooks from concept 4. Godot calls them; you never call them yourself.
- **`pass`** is a placeholder meaning "this function does nothing yet", like an empty `{}` body in JS. Replace it with your own lines.
- **Indentation is the block.** Every line indented one tab under a `func` line belongs to that function. A line back at the left margin is outside every function.

**There are two places a variable can live**, and choosing between them is the first real design decision you'll make:
| Where you declare it | Lifetime | JS equivalent |
|---|---|---|
| At the top of the file, outside any `func` | As long as the node exists; every function can see it. Only these can be `@export`ed. | A class field |
| Inside a `func` | Created fresh on every call, gone when the function returns. | A `let` inside a method |

`_process` runs about 60 times a second. A value you want to *keep* from one frame to the next can't be recreated on every call.

### 7. How to find out what anything is called
You'll spend your whole Godot life looking up names, so learn these tools on day one:
- **Hover over a property in the Inspector.** The tooltip shows the name you use in code, plus a description. The Inspector and your script talk about the same properties.
- **Autocomplete.** Start typing inside a function body and the editor lists what this node has. Typing the first few letters of a property you saw in the Inspector will find it.
- **Ctrl+click** any name in the script editor to jump to its documentation. **F1** (Search Help) opens the class reference *inside* the editor, so you don't need a browser.
- **Some properties have parts.** A `Vector2` value has `x` and `y` components, and you can read or assign one component on its own. Arithmetic and compound assignment (`+=`, `-=`, `*=`) work like they do in JS.

## Spec

**User stories**
- As the developer, I have a fresh Godot project in version control that ignores generated files, so my repo stays small and clean.
- As the developer, I can run the project and see a window of a fixed, deliberate size that scales sensibly.
- As the developer, I can see a script print on startup, then move an object at a speed I can tweak without editing code.

**Requirements**
- [ ] Project exists at `projects/01-pong/`, created with Godot 4.7 and the Git metadata option enabled.
- [ ] `.gitignore` includes `.godot/` (you verified it by reading the file).
- [ ] Viewport base size set to a landscape size of your choice (e.g. 1280x720); stretch mode and aspect set intentionally.
- [ ] A main scene (`main.tscn`) saved and configured as the project's main scene.
- [ ] A throwaway node with a script that prints in `_ready()`.
- [ ] That node moves horizontally at a constant speed in pixels per second, independent of frame rate.
- [ ] The speed is an `@export` variable, typed, editable in the Inspector.
- [ ] All variables and function signatures in your script have explicit or inferred types.

## Milestones

1. **Project scaffolding.** In the Project Manager, create a new project in `projects/01-pong/`. Pick the Forward+ or Compatibility renderer (Pong needs nothing fancy; either works, so note which you picked and why in PROGRESS.md). Tick the option to create version control metadata for Git.
   Open the generated `.gitignore` and read it. The **repository root is already initialised** (`learning-coding-no-ai-generated/`), so don't run `git init` inside `projects/01-pong/`: a nested repo would hide your project from the outer one. A `.gitignore` in a subdirectory applies relative to that directory. Confirm that it does, then make your first commit from the repo root.
   ✅ **Done when:** `git status` shows a clean tree after the commit, and `git check-ignore -v projects/01-pong/.godot` reports that the directory is ignored. You can state in one sentence why `.godot/` doesn't belong in git.

2. **Window settings and main scene.** In Project Settings, find the Display > Window section and set the base viewport width and height. Then find the stretch mode and aspect options and choose values; read the "Multiple resolutions" doc to decide (hint: for a game with no pixel art that must stay sharp at any window size, one mode redraws at the target resolution and another renders at base size then scales; pick, and write down why). Create a root node, save the scene as `main.tscn`, and set it as the main scene (Run/Application section, or let the editor prompt you on first F5).
   ✅ **Done when:** F5 opens a window of the size you chose; resizing the window by dragging does not distort or break the layout the way you expect from your stretch settings.
   *Commit.*

3. **First script.** Add a `ColorRect` child of your main node (give it a size and a visible colour in the Inspector). Attach a new script to it. Use the script-creation dialog; note which template and file location it defaults to. In `_ready()`, print a message.
   ✅ **Done when:** Running the game prints your message exactly once in the Output panel.
   *Commit.*

4. **Drift with delta.** Take this in three steps:
   - **a. Guided walkthrough (~20 min).** Make a throwaway scene (not `main.tscn`) and work through the official [Creating your first script](https://docs.godotengine.org/en/stable/getting_started/step_by_step/scripting_first_script.html) tutorial. It walks through a sprite that turns and moves over time, explaining each line. Type every line yourself rather than copy-pasting it. Delete the throwaway scene when you're done.
   - **b. Close the tutorial.** Now, from memory, apply the same idea to your own `ColorRect` in `main.tscn`. It should move horizontally, at a speed you declare as a typed variable, in pixels per second. Use concepts 4, 6 and 7 above. Decide where the speed variable belongs (concept 6), and find the name of the property that holds the rectangle's position (concept 7).
   - **c. If you're stuck,** reopen the tutorial and compare it with your attempt, then close it again and fix yours. Peeking is fine, but copying isn't. The point is that you can rebuild it without the tutorial.
   ✅ **Done when:** At speed 200 it crosses a 1280-wide window in about 6.4 s, timed by you with a stopwatch. Temporarily changing Project Settings > Application > Run > Max FPS to 30 (and back) does not change the crossing time noticeably.
   *Commit.*

5. **Tune from the Inspector.** Turn the speed variable into an `@export`. Change the value in the Inspector, and also tweak it while the game is running via the Remote tab of the Scene dock.
   ✅ **Done when:** You can change speed from the Inspector without touching the script, and you can explain the difference between editing the property in the Local scene tree vs. the Remote tree while running.
   *Commit.*

6. **Break it on purpose (5 min).** Remove one type annotation, misspell a variable, and call a method that doesn't exist on your node. Note where each error surfaces: the script editor, the Output panel, or the Debugger's Errors tab.
   ✅ **Done when:** You've written one line in PROGRESS.md about which of those caught the mistake earliest.

> The `ColorRect` and its script are disposable. You will delete them in Lesson 02.

## Architectural Hints

<details><summary>Hint 1 (nudge): Moving it</summary>

A node's position is a property on the node itself. Ask: what are the units of `position` (pixels), what are the units of your speed (pixels per second), and what value turns one into the other for a single frame?
</details>
<details><summary>Hint 2 (stronger nudge)</summary>

You are not setting position to a number; you are changing it by a small amount each frame. The amount is rate multiplied by elapsed time. `_process` hands you the elapsed time as its argument. Keep the speed variable separate from the position so it can be tuned.
</details>
<details><summary>Hint 3 (look this up)</summary>

Read the `Node2D` and `CanvasItem` class references for the `position` property (and note `Control`-derived nodes like `ColorRect` use `position` too). Note that `Vector2` has `x` and `y` fields you can read and assign individually.
</details>

<details><summary>Hint: "my @export doesn't show up in the Inspector"</summary>

Did you save the script? Is the script attached to the node you have selected? Exported variables appear in the Inspector under the script name section, lower in the property list.
</details>

<details><summary>Hint: "Which node should be the root of main.tscn?"</summary>

A plain `Node2D` is a fine root for a 2D game: it has a transform and no behaviour of its own. Later lessons may change this, which is fine, since scenes are cheap to refactor.
</details>

## Debugging Toolkit
- **`print()`**: goes to the Output panel. Start with it, since it works like `console.log`. `print_debug()` also shows the script and line.
- **Remote scene tree**: while the game runs, switch the Scene dock to the Remote tab to inspect live nodes and edit properties on the fly. Changes there are not saved.
- **Debugger panel**: the Errors tab shows runtime errors with a stack trace; double-click a line to jump to it. Also see Profiler and Monitors; glance at FPS.
- **Debug > Visible Collision Shapes** and other toggles under the Debug menu: not needed yet, but know it exists.
- **Symptoms to causes**
  - Script runs but nothing prints: is it attached to the node in the running scene? Is this scene the main scene or are you running the wrong one with F6?
  - Object doesn't move: did you edit the right property? Is `_process` spelled exactly, with the underscore? Check for a typo; GDScript won't warn you that an unknown function name is just never called (a warning may appear in the editor for unused parameters).
  - Object moves at different speeds on different runs: you forgot `delta`, or applied it twice.
  - Parse error mentioning indentation: you mixed tabs and spaces. Use the editor's defaults.
  - `.godot/` appears in `git status`: the ignore file is missing or in the wrong directory; check where `.gitignore` sits relative to your repo root.

## Docs
All links are Godot stable docs.
- [Key concepts overview](https://docs.godotengine.org/en/stable/getting_started/introduction/key_concepts_overview.html): read for the nodes/scenes/scene-tree/signals vocabulary in one place.
- [First look at the editor](https://docs.godotengine.org/en/stable/getting_started/introduction/first_look_at_the_editor.html): read for what each dock and panel is for.
- [Nodes and scenes](https://docs.godotengine.org/en/stable/getting_started/step_by_step/nodes_and_scenes.html): read for how scenes are saved and composed.
- [Creating your first script](https://docs.godotengine.org/en/stable/getting_started/step_by_step/scripting_first_script.html): read for attaching a script and the `_process` loop (note: it does a rotation, not what you're building).
- [GDScript reference](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html): skim the whole thing once; keep it as a reference. Focus on variables, constants, functions, and annotations.
- [Static typing in GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/static_typing.html): read for `:`, `:=`, and `->`.
- [GDScript exports](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_exports.html): read for `@export` and its variants (ranges, enums).
- [Idle and physics processing](https://docs.godotengine.org/en/stable/tutorials/scripting/idle_and_physics_processing.html): read for what `delta` means in `_process`.
- [Multiple resolutions](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html): read for the stretch mode and aspect options (Display > Window).
- [Version control systems](https://docs.godotengine.org/en/stable/tutorials/best_practices/version_control_systems.html): read for what Godot's Git option creates and what to ignore (`.godot/`).
- [Overview of debugging tools](https://docs.godotengine.org/en/stable/tutorials/scripting/debug/overview_of_debugging_tools.html): read for the Remote tree and debugger tabs.
- [Node class reference](https://docs.godotengine.org/en/stable/classes/class_node.html): see `_ready` and `_process` in context.
- [CanvasItem class reference](https://docs.godotengine.org/en/stable/classes/class_canvasitem.html): `position`-adjacent properties for 2D things live here and on `Node2D`.
- [GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html): skim now, so you pick up conventions (naming, ordering) from day one.

## Stretch Goals
- Make the rectangle wrap around: when it leaves the right edge, it reappears at the left. Use the viewport size, not a magic number.
- Add a second exported variable (a `Color`) and a `_ready()` that applies it. See how the Inspector widget changes with the type.
- Set the speed's `@export` with a range hint, so the Inspector shows a slider.
- Write a one-paragraph note in PROGRESS.md comparing `res://` paths and `$NodePath` syntax to filesystem paths.

## Reflection
1. Where does state live in the saved project: in the `.tscn`, the `.gd`, or `project.godot`? What would you change in each, and how would git show it?
2. Explain `delta` in your own words using a rate or throughput analogy from your ops work. What breaks if you leave it out?
3. What surprised you coming from JavaScript: what felt familiar, and what felt like a step backward?
