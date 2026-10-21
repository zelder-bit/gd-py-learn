# Lesson 07 · Polish, Win Condition & Review Prep
> **Session goal:** Add sound, pause, and restart, run a self-review against a checklist, document your architecture, and request the module review. **Time:** ~2 h. **Builds on:** Lesson 06.

## Concepts

### 1. Audio with `AudioStreamPlayer`
`AudioStreamPlayer` plays a sound with no positional effect (`AudioStreamPlayer2D` pans by position, which you don't need for Pong). Give it an `AudioStream` (a `.wav` or `.ogg` file) in the Inspector and call `play()` from code. Decide *who* plays which sound: the node that sees the event, or a listener of that event's signal. The second keeps game objects quiet and testable.

Generate effects instead of downloading them: [jsfxr](https://sfxr.me) (browser-based sfxr, with "Hit/Hurt", "Blip/Select", and "Pickup/Coin" presets) or [jfxr](https://jfxr.frozenfractal.com). Export as `.wav` into your project folder. Keep them short. One thing to check: if a sound can retrigger quickly (rapid paddle hits), does one player cut itself off? Think about how you'd handle it.

**Bridge:** Event-driven side effects, like a Lambda subscribed to an SNS topic. The emitter doesn't know about the sound.

### 2. Pausing and `process_mode`
`get_tree().paused = true` freezes the tree, but each node's `process_mode` decides whether it freezes. The values are `PROCESS_MODE_INHERIT` (default), `PAUSABLE`, `WHEN_PAUSED`, `ALWAYS` and `DISABLED`. A pause menu must keep processing input while the game is paused, so it needs `ALWAYS` or `WHEN_PAUSED`. Set the mode in the Inspector (Node, Process, Mode) or in code. Because children inherit, setting the mode on a parent can cover the subtree.

Watch for: timers. `SceneTree.create_timer` takes a `process_always` argument (default `true`), so a timer you made with defaults keeps counting down during a pause. A `Timer` node follows its own `process_mode` instead. Is that what you want?
```gdscript
process_mode = Node.PROCESS_MODE_ALWAYS
print(get_tree().paused)
```
**Bridge:** `SIGSTOP`/`SIGCONT` on a process group, except you choose which processes are exempt (like your shell).

### 3. Restart: reload vs. reset
Two honest strategies:
- **Reload the scene** (`get_tree().reload_current_scene()`): trivially clean, guarantees fresh state, but any state you wanted to keep (settings, mode choice) vanishes, and in-flight awaits and signal connections die with the old tree.
- **Reset state in place**: keeps what you want, but requires you to know and reset *every* piece of state. Anything you forget is a bug that only shows on the second game.

**Bridge:** Redeploy a fresh immutable instance vs. in-place config mutation. You already have strong opinions about this. It's the same trade-off.

Your state machine from Lesson 06 makes the second option much more tractable: entering a state is where resets live.

### 4. Juice (describe-level only)
A `Tween` animates properties over time. You get one with `create_tween()` on a node, chain steps with `tween_property`, and it frees itself when done. Ideas: a quick scale pulse on a paddle when hit; a flash of the score label; a tiny screen shake by briefly offsetting a `Camera2D`'s offset with decaying randomness. These are optional. Prioritise the checklist and the review.

**Bridge:** Smoothing and easing is a rate-limiter again: changing a value over time, not instantly.

### 5. Code-quality pass and review prep
You're a sysadmin: you know what "works on my machine" costs later. A review is easier when the repo tells its own story. Read the official [GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html) and fix what it flags: naming (`snake_case` functions/variables, `PascalCase` classes and nodes, `CONSTANT_CASE` constants), ordering of members, and spacing.

## Spec
**User stories**
- As a player, I hear feedback when the ball hits something or someone scores.
- As a player, I can pause and resume, and the pause screen responds to input.
- As a player, I can restart after game over (and optionally mid-game) with a clean slate.
- As the reviewer, I can understand the architecture from the README and the commit history before opening a single script.

**Functional requirements**
- [ ] At least three SFX: paddle hit, wall hit, score.
- [ ] A pause key toggles pause. A visible pause indicator shows. Gameplay (ball, paddles, CPU, timers) is fully frozen.
- [ ] A pause UI node processes while the tree is paused.
- [ ] Restart gives zero scores, a fresh serve, and no leftover state from the last game.
- [ ] Self-review checklist below fully passes.
- [ ] `projects/01-pong/README.md` exists, written in your own words.
- [ ] `PROGRESS.md` is current and a review is requested.

## Milestones
1. **Sound.** Generate and import your effects, and trigger them from the right places.
   ✅ Done when: each of the three events produces its own sound, in rapid succession without clipping or errors, and no game-object script has more than a line or two dedicated to audio.
   `git commit -m "Add sound effects"`
2. **Pause.** Toggle pause with a key, with a visible indicator.
   ✅ Done when: while paused, the ball, paddles, CPU and any serve countdown do not advance; pressing the key again resumes exactly where you left off; the pause key still works while paused.
   `git commit -m "Add pause"`
3. **Restart.** Choose reload or reset and implement it.
   ✅ Done when: play two full games back to back, and the second behaves identically to the first (scores, serve direction, state, CPU mode as intended). Write down why you chose your approach.
   `git commit -m "Add restart"`
4. **Self-review.** Work through the checklist below and fix what you find, in small commits.
   ✅ Done when: every box is ticked, or you've written a one-line justification beside each exception in your notes.
   `git commit -m "Self-review cleanup"`
5. **Architecture README.** Write `projects/01-pong/README.md`.
   ✅ Done when: it contains the scene tree, which script is attached to which scene, and a "who signals whom" list (emitter, signal, listener), all in your own words and short enough to read in 5 minutes.
   `git commit -m "Add architecture README"`
6. **Request the review.**
   ✅ Done when: PROGRESS.md has an entry for each lesson and a "ready for review" line, `git log --oneline` reads as a coherent story, the working tree is clean, and you've asked for the review.

## Self-Review Checklist
- [ ] Every variable, parameter and return value has an explicit type; no stray untyped `var`.
- [ ] No magic numbers: tunables are `@export` (if you'd tweak them in the Inspector) or `const` (if they're fixed).
- [ ] No `get_node("../../..")`-style chains or reliance on distant nodes; use `@export` node references, `@onready` for your own children, or signals.
- [ ] Signals are named in the past tense (`something_happened`), and handlers follow one convention (e.g. `_on_<node>_<signal>`).
- [ ] Each script has one responsibility, and you can say it in a sentence. No script is a god-script.
- [ ] State is owned in exactly one place; no UI reads game state per frame.
- [ ] No dead code, commented-out experiments, or leftover `print()` debugging (except deliberate logging).
- [ ] No duplicated scenes that should be instances of one.
- [ ] Node names in the scene tree are meaningful.
- [ ] `.gitignore` excludes `.godot/`, and no import cache or secrets are committed.
- [ ] The game runs from a fresh clone: open the project, press Play, no errors in the Debugger.

## How to Request the Review
1. Make sure `PROGRESS.md` has: a session log per lesson, your confusion one-liners, and the choices you made where the lessons offered options (paddle and ball body types, how the ball classifies hits, goal identification, state design, CPU approach, restart strategy), each with a sentence of reasoning.
2. Tidy `git log`. You can't rewrite published history casually, but make the last few commits tell a clean story.
3. Write the architecture README (scene tree, scripts, signal map) from memory first, then verify it against the project. Gaps between memory and reality are exactly where the review should dig.
4. List 2-3 specific things you want feedback on (e.g. "is my CPU design reasonable?").
5. Ask for the review in a new session, pointing at `projects/01-pong/`.

## Architectural Hints

<details><summary>Hint 1 (nudge): pause stops my pause key too</summary>
When the tree is paused, which nodes still process? Where does your pause-toggling input handling live, and what is *its* process mode?
</details>
<details><summary>Hint 2 (stronger): part of the game still moves</summary>
Something is ignoring the pause. Candidates: a node set to always process, a timer created with defaults, or a tween. Check each one's pause behaviour in its class docs.
</details>
<details><summary>Hint 3 (look up)</summary>
`Node.process_mode`, `SceneTree.paused`, the `process_always` argument of `SceneTree.create_timer`, and `Tween.set_pause_mode`.
</details>
<details><summary>Hint 1 (nudge): second game behaves differently</summary>
What was alive during the first game that isn't recreated? List every variable that changes during play, then check who resets it.
</details>
<details><summary>Hint 2 (look up): reload specifics</summary>
Check `SceneTree.reload_current_scene` and whether your pause flag is also reset (it's on the tree, not in the scene).
</details>
<details><summary>Hint 1 (nudge): sound cuts off or doesn't play</summary>
One `AudioStreamPlayer` restarts when you call `play()` again. Do you need several, or does the clipping not matter? Also verify the import: `.wav` files appear in the FileSystem dock and play from the Inspector preview.
</details>

## Debugging Toolkit
- **Debugger → Profiler/Monitors** show whether something is still processing during a pause. Compare against the Remote tree.
- **Audio bus layout** (bottom panel, Audio) shows level meters. If you see signal but hear nothing, check your OS mixer; if you see none, the stream isn't playing.
- **Print a line in each `_process`** in a suspect node to find who ignores pause (remove it afterwards).
- `git status`/`git log --oneline`/`git diff --stat` before you ask for review.

| Symptom | Inspect |
|---|---|
| Can't unpause | The node handling the key is paused. Check its `process_mode` and its parents' |
| Ball still resets while paused | A timer or `await` continues. Check `process_always` |
| Pause UI visible but unresponsive | The `Control`'s own `process_mode`, and whether a sibling is eating input |
| Sound doesn't play | Stream assigned? Bus muted? `play()` actually reached? |
| Restarted game has the old state | Anything not in the scene (autoload, `SceneTree` flags) survives a reload |
| Tween does nothing | Was it created on a node that is hidden/freed, or conflicting with another script writing the same property? |

## Docs
- [GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html): read this in full for naming, ordering, and formatting. You'll apply it in the self-review.
- [Pausing games](https://docs.godotengine.org/en/stable/tutorials/scripting/pausing_games.html): read this for `paused` and the `process_mode` options.
- [Audio streams](https://docs.godotengine.org/en/stable/tutorials/audio/audio_streams.html): read this for players, buses and supported formats.
- [AudioStreamPlayer](https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer.html): read this for `play()`, `finished`, and bus selection.
- [Tween](https://docs.godotengine.org/en/stable/classes/class_tween.html): read this for `tween_property`, chaining and easing.
- [Camera2D](https://docs.godotengine.org/en/stable/classes/class_camera2d.html): read this for `offset`, if you try screen shake.
- [SceneTree](https://docs.godotengine.org/en/stable/classes/class_scenetree.html): read this for `paused`, `reload_current_scene`, `create_timer`.
- [Static typing](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/static_typing.html): read this for the typing checks in the self-review.
- [Scene organization](https://docs.godotengine.org/en/stable/tutorials/best_practices/scene_organization.html): read this to sanity-check your structure.
- Tools: [jsfxr](https://sfxr.me) (browser-based), [jfxr](https://jfxr.frozenfractal.com) (alternative), [jsfxr source](https://github.com/chr15m/jsfxr).

## Stretch Goals
- Add the paddle-hit scale pulse using a `Tween`, and a brief score-label flash.
- Add subtle screen shake on score using a `Camera2D`, with a decay.
- Add a mute toggle that uses the audio bus rather than touching each player.
- Add a simple ball trail, then profile whether it costs anything.

## Reflection
1. Which checklist item did you fail most badly, and what does that tell you about how you write code under time pressure?
2. Reload vs. reset: which did you pick and what would make you change your mind?
3. If you started Pong again tomorrow, which single architectural decision would you change first?
