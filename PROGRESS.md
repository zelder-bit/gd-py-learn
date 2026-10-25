# Progress

## Status
| Module | Track | Status | Started | Reviewed |
|---|---|---|---|---|
| 01 · Pong | Godot | 🟢 In progress (Lesson 02 next) | 2026-10-20 | |
| 02 · Log Analyzer CLI | Python | 🔒 Locked (unlocks after Module 1 review) | | |
| 03 · Snake | Godot | 🔒 | | |
| 04 · System Monitor TUI | Python | 🔒 | | |
| 05 · Breakout | Godot | 🔒 | | |
| 06 · Level/Data Validator | Python | 🔒 | | |
| 07+ | — | 🔒 see ROADMAP.md | | |

## Module 1 · Pong (`projects/01-pong/`)
- [x] Lesson 01 · Editor, scene tree & GDScript basics
- [ ] Lesson 02 · Input & paddles
- [ ] Lesson 03 · The ball: velocity & wall bounces
- [ ] Lesson 04 · Paddle collisions & bounce angles
- [ ] Lesson 05 · Goals, scoring & signals
- [ ] Lesson 06 · Game states & the CPU paddle
- [ ] Lesson 07 · Polish, win condition & review prep
- [ ] 🔍 Requested code review

> **How this file works:** your words are written as plain text. Notes from Claude are in quote blocks starting with 💬. Add new session entries at the bottom of each lesson's log.

---

## Lesson 01 · Editor, Scene Tree & GDScript Basics ✅

### Decisions
| Decision | Choice | My reasoning |
|---|---|---|
| Stretch mode | `canvas_items` | Set strecth to canvas so that it resizes automatically. |
| Stretch aspect | `keep` | I set the aspect to keep so that the play area doesnt get distorted. |
| Speed type | `float` (`200.0`) | |

> 💬 **Stretch mode:** `viewport` resizes automatically too. What sets `canvas_items` apart is that it **redraws at the real window resolution**, so flat shapes stay sharp instead of being a stretched image.
>
> 💬 **Aspect:** `expand` doesn't distort either; only `ignore` does. What `keep` actually gives you is a **fixed play area**: every window shape shows the same 1280×720 world, with black bars filling the extra space, so your paddle clamps and goals match what the player sees.
>
> 💬 **Speed type:** pixels-per-second values are usually floats because `× delta` gives fractional pixels anyway. `:= 200.0` infers `float`. `= float(200)` with no `:` or `:=` would have left the variable untyped.

### Session log

**2026-10-20, 10:00–10:10 PM**
- Can't find viewport window adjustment.

> 💬 It's under **Project → Project Settings → General → Display → Window**. The fastest route is to type `stretch` or `viewport` in the **Filter Settings** box. Some options only appear with **Advanced Settings** toggled on.

**2026-10-20, 10:17 PM**
- Was treating the spec section like the lesson, woops.

> 💬 Lesson layout: **Concepts** = read first. **Milestones** = what you actually *do*, in order. **Spec** = definition of done, ticked at the end. **Hints / Debugging / Docs** = for when you're stuck.

**2026-10-24, 6:06 PM**
- Set stretch and aspect. My reasoning is in the Decisions table above.

**2026-10-24, 7:28 PM**
- For this section in https://docs.godotengine.org/en/stable/getting_started/step_by_step/scripting_first_script.html - This expression, Vector2.UP.rotated(rotation) , how does this add velocity? Without the speed does it just make the icnon move up while rotating?

> 💬 `Vector2.UP.rotated(rotation)` is a **direction, not a velocity**. It's an arrow of length 1 pointing where the sprite faces:
> - `Vector2.UP` = `(0, -1)`; y grows downward on screen.
> - `.rotated(...)` turns the arrow but keeps its length at 1.
> - `* speed` stretches it to 400 px/s, which makes it a **velocity**.
> - `* delta` shrinks it to this frame's step.
>
> Without `* speed`, it moves at 1 px/s in the direction it *faces*, which keeps turning, so it effectively spins in place. Even with speed, it travels in a **circle**, because "forward" keeps rotating.
>
> **Direction × speed, kept separate** comes back in Lesson 03.
>
> **Side bug you hit:** `to_string(x)` was a **parse error**. `to_string()` is a no-argument method called *on* an object. A parse error stops the **whole script** from loading, which is why nothing moved. Use `str(x)`, or pass several arguments to `print()`.

**2026-10-24, 7:49 PM**
- "Break it on purpose" - Output seems to catch items earlier. If i attempt to run a scene with broken syntax, it shows up in the debugger panel and provides a stack trace

> 💬 The **script editor** catches parse errors earliest: a red underline and an error bar appear *as you type*, before you run anything. Output and the Debugger only see errors once the game runs, and the Debugger adds the stack trace.

**2026-10-24, 8:01 PM**
- Stretch goal: Not sure what you are asking for res:// and $NodePath. I don't see anything significantly out of the ordinary. Not exactly sure what $NodePath is, i maybe overthinking it, is it just the paths to the nodes within the scene? Like ColorRect? Not sure.

> 💬 Yes, you had it right. The point is that they're **two different trees**:
>
> | | `res://…` | `$…` |
> |---|---|---|
> | Points into | **Files on disk** in the project | **Nodes in the running scene tree** |
> | Example | `res://color_rect.gd` (top of `main.tscn`) | `$ColorRect` written in Main's script |
> | Relative to | Project root, like a chroot | **The node running the script** |
>
> Both use `/` for nesting, and `$` supports `..` too (`$"../Sibling"`). One names *files*, the other names *live objects*.

**2026-10-24, 8:59 PM**
- Local tree vs remote tree Local: Editing in the file directly Remote: Editing via the exported value in the properties tab

> 💬 You edit both in the **Inspector**. The difference is *which copy* you're editing:
> - **Local** = the scene as saved in the editor. Edits are written to `main.tscn`, **persist**, and show in `git diff`.
> - **Remote** = the live running game. Edits apply **instantly** but are **thrown away** when the game stops.
>
> Ops analogy: `sysctl -w` (running system) vs. editing `/etc/sysctl.conf` (what you boot with).

**2026-10-24, 8:59 PM**
- Timer test (you test it)

> 💬 Measured headless over 3 s: **190.0 px/s at a 60 FPS cap, 189.0 px/s at 30 FPS** (exported value 190.556). The rate holds at both frame rates, so `delta` scaling works ✅. That's about 6.7 s to cross 1280 px. Run it yourself next time; watching it hold is the point.

### Reflection

**1. Where does state live in the saved project: in the `.tscn`, the `.gd`, or `project.godot`? What would you change in each, and how would git show it?**

.gd are the scripts. .tscn files store the active scene state o that would be the answer. project.godot stores config related items. git shows them as any other code change via diffs.

> 💬 Mostly there. The sharper version is **defaults vs. overrides**:
> - `.gd` holds behaviour plus **default** values (your `200.0`).
> - `.tscn` holds the node tree plus **per-node overrides**. That's why `speed = 190.556` landed in `main.tscn` and not in the script. It's the *saved* scene; runtime state never reaches disk.
> - `project.godot` holds project-wide settings (window size, main scene).
>
> Ops analogy: a Terraform module's variable defaults vs. a `.tfvars` file. This is central to Lesson 02, where two paddle instances share one script with different controls.

**2. Explain `delta` in your own words using a rate or throughput analogy from your ops work. What breaks if you leave it out?**

delta is the time between the current frame and last frame. Its allows for variables that would be affected by frame rate to be normalized across all ranges. Ops related items would be ethernet speeds between different ports and using network tools to create policies to normalize traffic for users. If left out some users may have an advantage over other users, and in terms of Ops work, that benefit may not be needed and could be wasteful.

> 💬 The definition is right, and fairness is a good point: without `delta`, a 144 Hz monitor gets a faster paddle than a 60 Hz one. A closer analogy: `delta` is like **dividing a byte counter by the sampling interval** to get bytes/sec. Without it, your numbers depend on how often you happen to poll.

**3. What surprised you coming from JavaScript: what felt familiar, and what felt like a step backward?**

GDScript reminds me alot of python, which i have used in work / generated a lot of handy scripts. It seems more human readable than JS and more forgiving.

> 💬 GDScript was deliberately designed to resemble Python (indentation blocks, `func`/`def`-style syntax, `and`/`or`/`not`), so this carries straight into Module 2. One caution: "forgiving" mostly comes from optional typing. Keep typing everything, because that's what makes the editor catch mistakes early.

---

## Lesson 02 · Input & Paddles

### Session log
- 

---

## Questions for Review
- 
