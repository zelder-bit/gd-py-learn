# Lesson 03 · The Ball: Velocity & Wall Bounces

> **Session goal:** Build a Ball scene that serves in a random direction at constant speed and bounces cleanly off top and bottom walls. **Time:** ~1.5–2 h. **Builds on:** Lesson 02 (paddle scene, physics body family, `_physics_process`).

## Concepts

### 1. A velocity is a direction times a speed
A `Vector2` is just two floats. Used as a *velocity*, it encodes both "how fast" (its length) and "which way" (its angle). Splitting these is the single most useful habit in this game:

- **direction**: a unit vector (length 1). Pure heading.
- **speed**: a scalar, in pixels per second.
- **velocity** = direction scaled by speed.

Why separate them? Because later you'll change speed (speed-up per hit) and direction (bounce angle) *independently*, and a vector that mixes both makes each change error-prone. Keep the speed as its own variable and treat the direction as something you can renormalize at will.

`normalized()` rescales a vector to length 1 while keeping its heading. Normalizing `(0, 0)` returns `(0, 0)` (no heading exists), so never normalize something that might be zero and assume it worked.

**Bridge:** velocity is like a rate with a direction. Throughput is a scalar (Mbps); a velocity is throughput *plus* which link it's going down. Separating direction from speed is like separating a route (where traffic goes) from a rate limit (how much).

### 2. Frame-rate-independent motion, again
You met `delta` in Lesson 01. Per-frame displacement is `velocity × delta`: pixels/second times seconds/frame gives pixels/frame. Physics bodies move in `_physics_process`, which runs at a fixed tick rate (60 by default), so `delta` there is steady.

**Bridge:** a fixed physics tick is a cron interval rather than an event-driven handler; you size each step by elapsed time so the system behaves the same if the interval changes.

### 3. Four ways to move a ball (pick one deliberately)
| Approach | Who drives motion | Collision response | Verdict for Pong |
|---|---|---|---|
| Set `position` manually on a `Node2D`/`Area2D` | You | None. You test overlaps yourself | Works, but you reimplement collision detection and tunnel-prevention |
| `RigidBody2D` | Physics engine | Automatic (forces, friction, restitution) | Fights you: speed drifts, angles aren't controllable, spin creeps in. Pong needs *authored* physics, not simulated |
| `CharacterBody2D.move_and_slide()` | You set `velocity`; engine slides along surfaces | Slides along the surface instead of bouncing | Designed for characters on floors; wrong feel for a ball |
| `CharacterBody2D.move_and_collide()` | You supply a motion vector; engine moves until contact and **reports** it | None applied. You decide what happens | **Recommended.** Detection is done for you, response is yours |

My recommendation is `CharacterBody2D` + `move_and_collide()`. The engine does the hard part (swept collision against shapes, stopping at the contact point, giving you the surface normal) and leaves the "what does a collision *mean* in Pong" logic to you, which is the point of the exercise. The `Area2D` + manual approach is a legitimate alternative if you want more control; it's more work and you'll hit tunneling and overlap edge cases yourself. Choose either, but write down in PROGRESS.md why.

`move_and_collide` takes a motion vector (the displacement for *this* step, not a velocity), moves the body until it touches something, and returns a `KinematicCollision2D` object, or `null` if nothing was hit. Since it can return null, you must check before using the result (JS bridge: like a function that returns an object or `null`, so guard before property access).

### 4. `KinematicCollision2D` and the normal
The returned collision object carries the data you need. Three accessors matter now:
- the **normal**: a unit vector perpendicular to the surface that was hit, pointing away from it, back toward the mover;
- the **collider**: the object you hit (essential in Lesson 04);
- the **remainder**: the part of this step's motion that *wasn't* used because contact happened first. If you ignore it, the ball loses a sliver of movement on each bounce; decide whether that matters for you.

### 5. Reflection is mirror geometry, described with the normal
When a ball hits a flat surface, the component of its velocity *along the normal* flips sign, and the component *parallel to the surface* is untouched. That's the entire law of reflection.

```
   incoming          outgoing
        \               /
         \  n  ^      /
          \    |     /
           v   |    ^
  ===================== surface
```

Concretely for a horizontal wall: the normal is vertical, so the vertical part of velocity flips and the horizontal part is kept. Speed (the length) is unchanged. For a tilted surface the same rule holds, just using that surface's normal instead of "up/down".

Godot gives you a built-in that does this. **Read the docs carefully**: Godot's `Vector2.bounce()` takes the surface **normal**, while `Vector2.reflect()` takes a direction *along the line*. This is the reverse of what many other engines call these. Picking the wrong one produces a ball that bounces plausibly in some walls and insanely in others. Check both class-reference entries before choosing.

**Bridge:** decomposing a vector against a normal is like splitting a flow into two independent components that you handle with separate rules, such as ingress vs. egress on an interface. The bounce applies a rule to exactly one component and passes the other through untouched.

### 6. A fair serve needs a constrained random angle
Random direction means a random angle, not a random `x` and `y` independently. And not just any angle. If the serve lands near vertical, the ball crawls sideways while bouncing between the walls for ages and nobody can interact with it. If it's near horizontal it's boringly flat. So choose an angle from a *limited* range off the horizontal axis (say within ±30–45° of straight left or right), then pick left or right as a separate coin flip. Convert degrees to radians where an API demands radians, and build a direction vector from the angle (look at the `Vector2` class for a constructor/static method that does this).

**Bridge:** like constraining a jittered retry backoff: random, but within bounds that guarantee useful behavior.

## Spec

**User stories**
- As a player, I see the ball start in the centre and move in a different direction each run, so rallies aren't predictable.
- As a player, the ball keeps a steady pace and never gets stuck on walls or slows down mysteriously.
- As a player, the ball never disappears through the top or bottom of the screen.

**Functional requirements**
- [ ] `Ball` is its own scene (saved as e.g. `scenes/ball.tscn`), instanced into your main scene
- [ ] Ball has a visible shape (`ColorRect` or similar) and a matching `CollisionShape2D`
- [ ] Speed is an `@export` value (px/s), tweakable in the Inspector
- [ ] On start, ball serves from the screen centre in a random direction: left or right, within a limited angle range of horizontal
- [ ] Top and bottom walls exist as `StaticBody2D` nodes with collision shapes spanning the full width of the viewport
- [ ] Ball bounces off both walls with no loss or gain of speed
- [ ] Ball never visibly sticks to, slides along, or passes through a wall

## Milestones

1. **Ball scene.** Create the ball scene, rooted in the node type you chose above (`CharacterBody2D` if you took the recommendation), with a visible rectangle/square and a collision shape of matching size. Instance it in your Main scene at the viewport centre.
   ✅ Done when: running the game shows a ball in the centre, and Debug → Visible Collision Shapes shows a shape that lines up with the visuals.
   `git commit -m "Add ball scene"`

2. **Constant-speed serve.** On `_ready`, compute a random serve direction (limited angle range, random side) and move the ball every physics frame in that direction at your exported speed. No walls yet.
   ✅ Done when: ten consecutive runs produce visibly different serve angles, always heading left or right, never nearly vertical, and the ball's speed is the same on every run.
   `git commit -m "Ball serves with random direction at constant speed"`

3. **Walls.** Add two `StaticBody2D` walls (top and bottom, each with a rectangular collision shape wider than the viewport). Consider giving the wall its own small scene or just two nodes in Main.
   ✅ Done when: with visible collision shapes on, both walls are visible lines just outside (or exactly at) the screen edges, and a ball aimed at one stops at it rather than passing through (a temporary stop is fine for this milestone).
   `git commit -m "Add top and bottom walls"`

4. **Bounce.** On wall contact, reflect the direction using the surface normal from the collision info.
   ✅ Done when: the ball bounces between top and bottom walls for 60 seconds with a steady speed, and a `print()` of the velocity's length on each bounce shows the same value (within float noise) every time.
   `git commit -m "Ball bounces off walls"`

5. **Robustness pass.** Raise the speed export way up (3–5× normal), and try serving 20+ times.
   ✅ Done when: at very high speed the ball still never leaves the screen vertically, and across 20 runs the serve angle never falls inside your forbidden near-vertical zone.
   `git commit -m "Verify ball at high speed"`

## Architectural Hints

<details><summary>Hint 1 (nudge): where does the state live?</summary>

The ball needs two persistent pieces of state: its current **direction** and its **speed**. Neither should be recomputed from scratch each frame. They persist between frames as member variables. The per-frame work is: compute this frame's displacement from them, ask the engine to move you, react to the result.
</details>

<details><summary>Hint 2 (stronger): why not just use velocity and move_and_slide?</summary>

`move_and_slide` is built around the idea of a character walking along surfaces and modifies the velocity for you as it slides. A ball doesn't *slide* along a wall; it bounces. You want an API that stops at contact and tells you what happened so you can apply your own response. Look at what `move_and_collide` returns and when.
</details>

<details><summary>Hint 3 (exact API to look up): reflection</summary>

Open the `Vector2` class reference and read `bounce`, `reflect`, `slide`. Decide which takes a normal and which takes a line direction, and verify with a print that a ball heading down-right into a floor ends up heading up-right. For the collision's normal, look at `KinematicCollision2D`.
</details>

<details><summary>Hint 1 (nudge): the random serve</summary>

Break it into three independent random choices: (a) left or right, (b) an angle magnitude within your allowed band, (c) up or down tilt. Then turn an angle into a direction vector; the `Vector2` class has a way to build one from an angle.
</details>

<details><summary>Hint 2 (stronger): which random function</summary>

You want a float in a range for the angle and a coin flip for the sign/side. Search `@GlobalScope` for the random-range function that returns a float, and think about how to turn a 50/50 into ±1.
</details>

<details><summary>Hint 3 (exact API to look up): angle to vector</summary>

Look up `Vector2.from_angle()` and `deg_to_rad()`. Note that GDScript's trigonometry works in radians.
</details>

<details><summary>Hint 1 (nudge): ball stops or jitters at the wall</summary>

If the ball reverses only *after* touching the wall and then the engine immediately re-detects contact, you may be reflecting an already-reflected direction. Think about what happens when the same collision is processed twice in consecutive frames, and about the leftover motion from the frame of impact.
</details>

<details><summary>Hint 2 (stronger): bounce but still stuck</summary>

When the ball touches the wall, the engine stops it at the surface. Whether the remaining part of that frame's movement is thrown away is up to you. Check what `KinematicCollision2D` offers for leftover motion and decide whether to spend it.
</details>

## Debugging Toolkit

- **Debug → Visible Collision Shapes** (in the editor's Debug menu): the first thing to turn on for any collision issue. Shapes you can't see are shapes you assume are right.
- **`print()`** the direction, its `length()`, and the normal on every collision. The length should stay constant (if you intended it to); the normal should be `(0, ±1)` for top/bottom walls.
- **Remote scene tree**: while the game runs, switch the Scene dock to the "Remote" tab and click your Ball. The Inspector shows live `position` and any exported variables. Great for confirming where the ball *actually* is.
- **Debugger → Errors/Output** tabs: null-reference errors from forgetting to guard a missing collision show up here with line numbers.
- **Slow it down**: temporarily drop the speed to a crawl to watch contact behavior frame by frame.

**Symptoms → what to inspect**
| Symptom | Likely cause |
|---|---|
| Ball flies straight through a wall | Wall has no `CollisionShape2D` shape assigned (warning triangle in the Scene dock), or layer/mask mismatch (see Lesson 04). Also check that you're using a move method that actually reports contact |
| Ball bounces in a wrong direction | Normal and line-direction confusion between `bounce` and `reflect`; print the normal and result |
| Ball gradually speeds up or slows down | Direction isn't unit length, or you're mixing speed into the direction. Print the length |
| Ball sticks to / vibrates on the wall | Reflecting twice, or the direction is being reassigned after your reflect call |
| Serve is boringly vertical | Angle range too wide, or you're picking `x` and `y` independently |
| Everything is jittery | Moving in `_process` instead of `_physics_process` |
| Error about calling a method on `null` | You used the collision result without checking whether one occurred |

## Docs

- [CharacterBody2D class](https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html): read for the node's properties and the `move_and_slide` overview and caveats.
- [PhysicsBody2D class](https://docs.godotengine.org/en/stable/classes/class_physicsbody2d.html): read for the exact signature of `move_and_collide` (it lives here), its `test_only` and `safe_margin` parameters.
- [Using CharacterBody2D/3D](https://docs.godotengine.org/en/stable/tutorials/physics/using_character_body_2d.html): read the `move_and_collide` section; it literally discusses the ricochet use case.
- [KinematicCollision2D class](https://docs.godotengine.org/en/stable/classes/class_kinematiccollision2d.html): read for the normal, collider, travel and remainder accessors.
- [Vector2 class](https://docs.godotengine.org/en/stable/classes/class_vector2.html): read `normalized`, `bounce`, `reflect`, `slide`, `from_angle`, `length`. Pay attention to the note contrasting `bounce` and `reflect`.
- [Vector math tutorial](https://docs.godotengine.org/en/stable/tutorials/math/vector_math.html): read the normalization, dot product and reflection sections for the geometric intuition.
- [Physics introduction](https://docs.godotengine.org/en/stable/tutorials/physics/physics_introduction.html): read for the overview of body types and why you'd choose each.
- [StaticBody2D class](https://docs.godotengine.org/en/stable/classes/class_staticbody2d.html): read to confirm what a static body is and isn't.
- [@GlobalScope](https://docs.godotengine.org/en/stable/classes/class_@globalscope.html): search for `randf_range`, `deg_to_rad`, `signf` (long page; use Ctrl+F).
- [RandomNumberGenerator class](https://docs.godotengine.org/en/stable/classes/class_randomnumbergenerator.html): read if you want seeded randomness (useful for reproducing a bug).

## Stretch Goals

1. **Serve visualization.** Draw a short line showing the upcoming serve direction before launch (look into `_draw()` and `queue_redraw()`), then clear it.
2. **Compare approaches.** Make a throwaway second ball using `RigidBody2D` with zero gravity and a bouncy physics material. Record in PROGRESS.md what you observe about speed drift and angle control versus your `CharacterBody2D` ball, then delete it.
3. **Seeded serves.** Use a `RandomNumberGenerator` instance with a fixed seed so you can reproduce the exact same serve sequence for debugging.
4. **Use the remainder.** Make the ball spend the leftover motion after a bounce so that a bounce doesn't cost any distance. Verify with a speed readout that nothing changes at normal speeds, and think about when it would.

## Reflection

1. Why does `move_and_collide` suit Pong better than `move_and_slide` and `RigidBody2D`? Which trade-off did you actually choose, and what did it cost you?
2. Describe the law of reflection in your own words using the normal vector, without referring to Godot. What stays the same and what flips?
3. What would break if the serve angle were picked by choosing `x` and `y` independently at random? How did you constrain it?
