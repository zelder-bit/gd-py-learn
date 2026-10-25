# Lesson 04 · Paddle Collisions & Bounce Angles

> **Session goal:** Turn the bouncing ball into real Pong: paddles that return it at angles depending on where it hit, with per-hit speed-up, intentional collision layers, and no sticking. **Time:** ~2 h. **Builds on:** Lesson 03 (Ball scene, walls, reflection).

## Concepts

### 1. Knowing *what* you hit
`move_and_collide` hands you a collision with a `collider`: the object you touched. Right now your ball treats every contact the same (reflect off the normal). Paddles need different treatment from walls, so the ball must classify the thing it hit. Options:

- **Groups.** Tag nodes (editor Node dock → Groups, or from code) and ask the collider whether it belongs to one. Cheap, decoupled: the ball doesn't need to know the Paddle's class.
- **Type checks.** Test whether the collider is an instance of a particular script class (needs a `class_name` on the script). Tighter coupling; fails silently if you rename things.
- **Duck typing / method presence.** Ask whether the collider has a method or property. Flexible, but weakest at catching typos.
- **Layers** (concept 4) can make some of this unnecessary by preventing contact entirely.

Choose one and justify it in PROGRESS.md. The brief for design: the ball should not need to know about *Paddle internals*, only "is this a thing I bounce with angle logic?"

**Bridge:** groups are resource tags (`Environment=prod`): a label you filter on, rather than a hard type. A type check is more like requiring a specific AMI ID.

**Mechanics you'll need (first use):**
- *Adding a node to a group in the editor.* Select the node (in `paddle.tscn`, select the **root**, so every instance inherits it) → **Node** dock (next to the Inspector) → **Groups** tab → type a name in the box → **Add**. Reopen the tab to confirm it's listed. In code, `add_to_group("lamps")` does the same thing at runtime.
- *Asking the question.* `some_node.is_in_group("lamps")` returns a `bool`. Compare to checking a tag on a resource.
- *What `get_collider()` gives you.* The collision result's `collider` is typed as a generic object, not as a specific node type, so the editor won't autocomplete node properties on it. Two ways around that: declare a typed local with a cast, `var door := thing as Node2D` (gives `null` if `thing` isn't a `Node2D`), or test first with `if thing is Node2D:`. `is` asks "is this that type?", `as` converts or gives `null`. Both are `instanceof`/a checked cast in other languages. After the cast, `door.global_position` is readable like any property.
- *Printing which branch ran.* A one-line `print("wall")` in each branch of an `if / else` is your whole test harness for milestone 2.

### 2. Hit offset becomes a bounce angle
Real Pong feels good because *where* you strike the ball steers it. The geometry:

```
        paddle (side view, y axis vertical)

   top edge      -1.0  ──┐
                          │  hit near top    -> ball leaves steeply UP
                -0.5  ──┤
   centre         0.0  ──┤  hit dead centre -> ball leaves straight
                +0.5  ──┤
   bottom edge   +1.0  ──┘  hit near bottom -> ball leaves steeply DOWN
```

What you're building is a **mapping**: *contact point on the paddle* → *outgoing angle*. Work it out yourself on paper before writing any code. These questions are the design:
- What two positions do you compare to find "where on the paddle" the hit was? In which coordinate space?
- How do you turn that raw pixel distance into a size-independent value (like the −1..+1 scale above), so resizing the paddle doesn't break anything? What happens at the corners, where the ball's centre can sit *beyond* the paddle's edge?
- How does that normalised value become an angle, and what caps the steepest possible return? (Make the cap a tunable.)
- The left paddle must send the ball right and the right paddle left. Where does that sign come from?
- Where does the ball's *speed* go during all this? (Lesson 03 kept direction and speed separate for exactly this moment.)

Notice you are **not** reflecting off the normal for paddles; you're *overwriting* the direction using the offset. That's the "arcade physics" trick: a lie that plays better than the truth. Consider why the reflect result would feel bad on a flat paddle (every hit would be a pure horizontal flip, so the rally never changes).

The angle-to-vector step reuses the tool from the serve in Lesson 03. Mapping one range onto another is linear interpolation, and `@GlobalScope` has more than one function for it.

**Mechanics only (the algorithm is still yours):**
- *Your own function.* Everything so far has been callbacks Godot calls for you. You can also define helpers and call them yourself, with parameters and a return value: `func is_open(door: Node2D) -> bool:` then `return` something inside, and call it as `if is_open(front_door):`. A helper that takes the inputs of one question and returns the answer is easy to `print()`-test in isolation. Local variables inside it die when it returns (Lesson 01 concept 6).
- *Reading a position off another node.* Any `Node2D` has `global_position`, a `Vector2`, readable from a different script once you hold a reference to that node. Ctrl+click `global_position` to read how it differs from `position`. Remember `x` and `y` components are readable separately.
- *Paper-test first.* Pick three hit positions, write the number you expect out for each, then compare to your `print()`. That's the milestone-3 test.

**Bridge:** normalising an offset to −1..1 is like converting a metric to a utilisation percentage so thresholds don't depend on the absolute size of the thing.

### 3. Speed-up with a cap, and not hitting twice
Each paddle hit increases the ball's speed by a small amount, up to a ceiling. Both numbers are tunables: expose them. Whether the increase is additive or multiplicative is a design choice: think about which one saturates more gracefully.

**Hazard: the double-hit / stuck-in-paddle bug.** The ball is a body with area. If a collision response is applied while the ball still overlaps the paddle, the next physics step detects contact again, applies the response again, and the direction flips back toward the paddle. Symptoms: ball jitters inside the paddle, ball passes through the paddle, or speed increases several times per hit. Two common defenses, which can be combined:
- **Direction guard:** only apply paddle logic if the ball is actually moving *toward* that paddle. If it's already leaving, ignore the contact.
- **Separation:** after responding, make sure the ball isn't left overlapping (nudge it out along the normal, or by using the travel/remainder information from the collision).

Both are about idempotency: handle each physical hit exactly once. **Bridge:** a webhook receiver that must deduplicate retries with an idempotency key; here the "key" is "I'm already leaving".

### 4. Collision layers and masks: your ACLs
Every `CollisionObject2D` (all bodies and areas) has two 32-bit fields:
- **`collision_layer`**: the layer(s) this object *is on* ("my VLAN/tag").
- **`collision_mask`**: the layer(s) this object *scans* ("what I'm allowed to see/hit").

Both default to layer 1, which is why everything collides with everything until you choose otherwise. The rule from the docs: object A detects B only if B is on a layer that A's mask includes. The relationship is **directional**, like a stateless ACL where an allow in one direction doesn't imply the reverse. Plan it as a small matrix:

| Object | On layer | Scans (mask) |
|---|---|---|
| Ball | ? | ? |
| Paddles | ? | ? |
| Walls | ? | ? |

Fill in that table *on paper first*. Ask: what must the ball collide with? What should paddles collide with (walls? ball? each other?)? Does a wall need to scan anything at all? Name the layers under Project Settings → Layer Names → 2D Physics so the Inspector shows "ball", "paddle", "wall" rather than numbers.

**Editor mechanics (first use):**
- *Naming layers:* **Project → Project Settings → Layer Names → 2D Physics**, then type a name beside each layer number you plan to use.
- *Assigning them:* select a body node (e.g. the root of `paddle.tscn`) → Inspector → **Collision** section. **Layer** and **Mask** are rows of numbered toggle squares; click one to flip it, hover for the name you set. Each row has a `...` button to open a bigger editor. Do this on the scene root of `paddle.tscn`/`ball.tscn`, not on a single instance, so both paddles get it.
- *Where it lives in code:* the same bits are `collision_layer` and `collision_mask` on the node, but the Inspector is the right tool here. `get_collision_layer_value()`/`set_collision_mask_value()` exist (see docs) if you ever need them at runtime.
- *Negative test:* untick one mask square, run, confirm the symptom, tick it again.

**Bridge:** CCNA mode: layers are VLAN membership or security-group tags; masks are the ingress ACL. Default layer 1 for everything is "one flat /16 with permit any any". It works until it doesn't, and then debugging is painful.

## Spec

**User stories**
- As a player, I can hit the ball back with my paddle.
- As a player, where the ball strikes my paddle determines how steeply it goes: I can aim returns.
- As a player, a rally gets faster the longer it goes, but it never becomes unplayable.
- As a player, the ball never gets "stuck" in or tunnels through a paddle.

**Functional requirements**
- [ ] Ball bounces off both paddles (left and right) and still bounces off walls as before
- [ ] Ball identifies *paddles* distinctly from *walls* by a mechanism you can explain
- [ ] Return angle is a function of the hit offset: centre hit sends the ball roughly horizontally, edge hits send it at (up to) your max angle
- [ ] Max bounce angle is an `@export` variable
- [ ] Ball always leaves the paddle heading away from it (left paddle: rightward, right paddle: leftward)
- [ ] Each paddle hit increases ball speed by an exported amount up to an exported maximum
- [ ] Walls do **not** change the ball's speed
- [ ] Collision layers and masks are set deliberately, with named layers, and your table is recorded in PROGRESS.md
- [ ] No double-hit: one physical hit yields exactly one speed increase and one direction change

## Milestones

1. **Plain paddle bounce.** Make the ball bounce off paddles with the same reflect-style response as the walls. Make sure paddles exist with proper collision shapes.
   ✅ Done when: the ball bounces off both paddles in a live game and never passes through them at normal speed.
   `git commit -m "Ball bounces off paddles"`

2. **Distinguish paddles from walls.** Introduce a classification mechanism (group, type check, or other) so the ball's code can branch on "paddle vs. other". Take it in steps:
   - **a.** Pick the mechanism and note why (PROGRESS.md). If groups, add the tag in `paddle.tscn` using the Node dock steps above and verify it shows on both instances.
   - **b.** In the ball's collision handling, get the collider out of the collision result and ask your question about it. Add the cast from concept 1 if your mechanism needs one.
   - **c.** Print one word per branch.
   ✅ Done when: a `print()` on each collision says "paddle" or "wall" correctly, 20 out of 20 times, in a play session where you hit both.
   `git commit -m "Ball classifies collisions"`

3. **Angle by hit offset.** For paddle hits only, compute the hit offset (−1..1) and set the outgoing direction from it, heading away from the paddle. Take it in steps:
   - **a. On paper.** Answer the design questions in concept 2 and write your three expected test values (centre, top edge, bottom edge) with the numbers you expect out.
   - **b. Get the inputs.** Get the paddle's and ball's `global_position` into locals inside the paddle branch and `print()` them. Move the paddle and confirm they change as you expect.
   - **c. Build the offset** as its own helper function (parameters in, one number out), and print it for your three paper cases before using it for anything.
   - **d. Use the result** to set the outgoing direction, and compare the printed angle to your paper values.
   ✅ Done when: printing the offset and the outgoing angle shows ≈0° at the paddle centre and ≈±(max angle) at the edges. Hitting with the paddle's top edge sends the ball upward, bottom edge sends it downward, and the ball always moves away from the paddle you hit.
   `git commit -m "Paddle hit offset controls bounce angle"`

4. **Speed-up with cap.** Increase speed on each paddle hit (not wall hits) up to a max.
   ✅ Done when: with a low cap, a printed speed rises hit by hit, plateaus exactly at the cap, and never exceeds it, even after 30+ hits (use a test rally or set the paddles very wide).
   `git commit -m "Ball speeds up per hit with cap"`

5. **Layers and masks.** Name the layers, assign them per your table, and remove all default-layer-1-for-everyone leftovers. Order: **(a)** fill the table on paper, **(b)** name layers in Project Settings, **(c)** set Layer/Mask on the roots of `ball.tscn`, `paddle.tscn` and the wall nodes, **(d)** run the negative test.
   ✅ Done when: your table is in PROGRESS.md; the Inspector shows named layers; and as a negative test, deliberately removing the ball's paddle mask bit makes the ball pass through paddles (then restore it).
   `git commit -m "Configure collision layers and masks"`

6. **Kill the double-hit.** Stress test: grab the ball with the paddle's edge, hit it at a corner, push the paddle into it while it's moving away.
   ✅ Done when: across a 2-minute stress session, you never see jitter inside a paddle, a single hit never raises speed twice (confirm with a printed hit counter vs. speed), and the ball never reverses direction back into the paddle it just left.
   `git commit -m "Prevent double-hit and sticking"`

## Architectural Hints

<details><summary>Hint 1 (nudge): who owns the paddle-hit logic?</summary>

Two options: the ball asks "what did I hit and how do I respond?", or the paddle exposes something like "tell me the outgoing direction for a hit at this point". The first keeps the paddle dumb; the second puts paddle-specific knowledge (its height) with the paddle. Neither is wrong. Pick, and note what the ball needs to know about the paddle in each design (its centre, its half-height).
</details>

<details><summary>Hint 2 (stronger): the offset needs two positions in the same space</summary>

The ball's and paddle's positions need to be compared in the same coordinate space. Global positions are the simplest. The paddle's half-height has to come from somewhere: don't hard-code a number that duplicates the collision shape's size, or the two will drift apart the first time you resize the paddle. Think about a single source of truth, e.g. an `@export` on the paddle.
</details>

<details><summary>Hint 3 (exact API to look up): angle math</summary>

`remap`, `clamp`, `deg_to_rad`, and `Vector2.from_angle()`. For the horizontal side, think about how to get a ±1 from "which paddle is this", or from the sign of the ball's current horizontal travel.
</details>

<details><summary>Hint 1 (nudge): tagging the paddles</summary>

You don't want the ball importing the paddle's script. Look at how a node can be placed into a named set and later queried.
</details>

<details><summary>Hint 2 (stronger): both editor and code work</summary>

The Node dock has a Groups tab. The same membership can be declared in the script's `_ready`. If you instance the Paddle scene twice, group membership saved in the scene file applies to both instances, which is exactly what you want.
</details>

<details><summary>Hint 3 (exact API to look up): group queries</summary>

`Node.add_to_group()` and `Node.is_in_group()`, and the Groups tutorial linked below. The collider from `KinematicCollision2D.get_collider()` is typed as a generic object, so think about whether you need to cast it before calling node methods on it.
</details>

<details><summary>Hint 1 (nudge): the stuck ball</summary>

Draw three frames on paper: before contact, the contact frame, the frame after. At which frame can the same paddle hit be detected twice? What would make the second detection harmless?
</details>

<details><summary>Hint 2 (stronger): a guard condition</summary>

Compare the direction the ball is *currently travelling* horizontally with the side the paddle is on. If it is already moving away from that paddle, the hit has already been handled.
</details>

<details><summary>Hint 3 (exact API to look up): separation</summary>

On `KinematicCollision2D`: `get_normal`, `get_travel`, `get_remainder`, `get_position`. The simplest robust fix often combines the direction guard with one of these to avoid ending the frame embedded in the paddle. Also read `safe_margin` on `CharacterBody2D`.
</details>

<details><summary>Hint 1 (nudge): layers design</summary>

Start from the question "who needs to *detect* whom?" for each pair. Remember the relationship is one-way: you set the mask on the object doing the detecting.
</details>

<details><summary>Hint 2 (stronger): what the moving body needs</summary>

For `move_and_collide`, the body that is *moving* is the one whose mask matters. Walls and paddles only need to be on a layer; they don't scan for anything unless they are themselves moving or using areas. Keep the table minimal and justify each tick.
</details>

<details><summary>Hint 3 (exact API to look up)</summary>

Project Settings → Layer Names → 2D Physics to name layers; the Collision section in the Inspector for assigning them. Read the "Collision layers and masks" section of the Physics introduction page.
</details>

## Debugging Toolkit

- **Debug → Visible Collision Shapes**: also tints shapes when they're active. Check that the paddle's shape matches what you see; an oversized or off-centre shape ruins the offset math.
- **`print()` a one-line summary per hit**: offset, outgoing angle (in degrees), speed before/after, and which paddle. If you can't read the log and say "yes, that's right", you can't trust the behaviour either.
- **Remote scene tree + Inspector**: select the ball while playing and watch exported values; confirm the collision layer/mask bits shown there match your table.
- **Debugger → Profiler/Monitors**: mostly overkill here, but the Monitors tab shows physics and frame time if you suspect a stall.
- **Pause and step**: temporarily slow the ball (`Engine.time_scale`, or low speed) to watch the contact frame.
- **A hit counter** on the ball is a cheap idempotency test.

**Symptoms → what to inspect**
| Symptom | Likely cause |
|---|---|
| Ball ignores the paddle entirely | Layer/mask mismatch, missing collision shape, or the paddle is on a layer the ball doesn't scan |
| Ball ignores *only one* paddle | The two instances have different settings (check that layers are saved in the scene, not set on one instance) |
| Ball flies off at a crazy angle | Offset not clamped, wrong divisor (full height instead of half), or degrees fed to a radians API |
| Ball always returns at the same angle | Offset is constantly ~0 (comparing the wrong positions/spaces) or max angle is tiny |
| Ball goes up on bottom hits (inverted) | Remember that screen y grows *downward* |
| Speed jumps several times for one hit | Double-hit; add a guard and verify with the hit counter |
| Ball sinks into the paddle and vibrates | Direction not leaving the paddle; separation missing |
| Ball hits the paddle's top/bottom edge and teleports | Collision with the paddle's side surface; think about whether to treat side hits specially (stretch goal) |
| Speed exceeds the cap | Cap applied before the increment instead of after, or a second code path changes speed |

## Docs

- [Physics introduction](https://docs.godotengine.org/en/stable/tutorials/physics/physics_introduction.html): read the "Collision layers and masks" section (GUI example, code example) and the body type overview.
- [CollisionObject2D class](https://docs.godotengine.org/en/stable/classes/class_collisionobject2d.html): read `collision_layer`, `collision_mask`, and the `*_collision_*_value()` helpers.
- [KinematicCollision2D class](https://docs.godotengine.org/en/stable/classes/class_kinematiccollision2d.html): read for `get_collider`, `get_normal`, `get_position`, `get_travel`, `get_remainder`.
- [PhysicsBody2D class](https://docs.godotengine.org/en/stable/classes/class_physicsbody2d.html): read the `move_and_collide` entry, including `test_only` and `safe_margin`.
- [CharacterBody2D class](https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html): read for `safe_margin` and how recovery pushes bodies apart.
- [Groups tutorial](https://docs.godotengine.org/en/stable/tutorials/scripting/groups.html): read for editor and code group membership, and scene vs. global groups.
- [Node class](https://docs.godotengine.org/en/stable/classes/class_node.html): look up `add_to_group` and `is_in_group`.
- [Vector math tutorial](https://docs.godotengine.org/en/stable/tutorials/math/vector_math.html): re-read the normal and reflection sections to contrast with your angle-override approach.
- [Vector2 class](https://docs.godotengine.org/en/stable/classes/class_vector2.html): `from_angle`, `limit_length`, `length`, `normalized`.
- [@GlobalScope](https://docs.godotengine.org/en/stable/classes/class_@globalscope.html): `clamp`/`clampf`, `remap`, `lerp`, `deg_to_rad`, `sign` (long page; Ctrl+F).
- [Using CharacterBody2D/3D](https://docs.godotengine.org/en/stable/tutorials/physics/using_character_body_2d.html): the `move_and_collide` section again, for how collision info is used.

## Stretch Goals

1. **Side-hit handling.** If the ball strikes the *top or bottom edge* of a paddle (normal is vertical), decide on a sensible behaviour: a plain reflect, or ignore the angle override. Document your choice.
2. **Paddle influence.** Let the paddle's own motion at the moment of contact nudge the outgoing angle (the collision exposes the collider's velocity; check whether that is populated for your paddle type and why).
3. **Layer assertions.** Write a tiny debug check in `_ready` that prints a warning if the ball's mask doesn't include the paddle or wall layers. A startup config lint, in your own words.
4. **Tuning panel.** Expose max angle, speed-up amount and cap together as a small group of exported vars (see `@export_group`) and tune the game feel using only the Inspector while it runs.

## Reflection

1. Why does overwriting the direction on a paddle hit (instead of reflecting) make for better gameplay? What would a pure reflection do to rally dynamics?
2. Which mechanism did you use to tell paddles from walls, and what is its biggest weakness? Under what change would it silently break?
3. Describe in your own words how the double-hit bug arises, and which defence you used. Fill in your layers/masks table and say which pairs you chose *not* to let interact, and why.
