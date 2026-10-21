# Module 1 · Godot: Pong

**Track:** Godot 4.7 / GDScript · **Sessions:** 7 × 1–2 h (~2 weeks) · **Project folder:** `projects/01-pong/`

## Why Pong first
Pong is the smallest game that still touches every core Godot system: the scene tree, scripts, input, the frame loop, vectors, physics collision, signals, and UI. Every mechanic is simple, so all your attention goes to *how Godot is wired*, not game design.

## What you'll be able to do afterwards
- Navigate the editor and explain the difference between a **node**, a **scene**, and a **script**.
- Read and write GDScript 2.0: variables, static types, functions, `@export`, `enum`, `match`, signals.
- Explain when to use `_process` vs. `_physics_process`, and why `delta` matters.
- Pick between `Node2D`, `Area2D`, `CharacterBody2D`, `StaticBody2D`, and `RigidBody2D` for a job.
- Decouple systems with **custom signals** instead of reaching across the tree.
- Structure a game as a small state machine using an `enum` and `match`.

## Final spec (definition of done)
A two-player (and optionally one-player vs. CPU) Pong game where:
1. Two paddles move vertically with separate keys and can't leave the screen.
2. A ball serves from the centre in a randomized direction, bounces off the top/bottom walls, and bounces off paddles at an angle that depends on *where* it hit the paddle.
3. The ball speeds up slightly on each paddle hit, up to a cap.
4. When the ball passes a paddle, the opponent scores, the score UI updates, and the ball re-serves after a short delay.
5. First to N points (an `@export` value) wins. A game-over screen offers a restart.
6. A title/serving/playing/game-over flow exists, and the game can be paused.
7. The code is your own, organised into several scripts that talk through signals. No single 400-line god-script.

## Session plan
| # | Lesson | You'll end the session with… |
|---|---|---|
| 01 | [Editor, scene tree & GDScript basics](01-editor-scene-tree-gdscript.md) | A project, a main scene, and a script that moves a rectangle |
| 02 | [Input & paddles](02-input-and-paddles.md) | Two keyboard-driven paddles clamped to the screen |
| 03 | [The ball: velocity & wall bounces](03-ball-velocity-and-walls.md) | A ball that moves and bounces off the top/bottom walls |
| 04 | [Paddle collisions & bounce angles](04-paddle-collisions.md) | Real Pong rallies with angled returns and speed-up |
| 05 | [Goals, scoring & signals](05-goals-scoring-signals.md) | Working scores, a UI, and serve/reset driven by signals |
| 06 | [Game states & the CPU paddle](06-game-states-and-cpu.md) | Title/serve/play/game-over flow and a beatable AI |
| 07 | [Polish, win condition & review prep](07-polish-and-review.md) | Sound, pause, restart, and a codebase ready for review |

**Pacing:** Lessons 04 and 06 are the densest. Each has six milestones, and it's normal for either to take two sessions. Each milestone ends with a commit, so stopping after any milestone is fine. If a session hits the 2 h mark, stop at the last green milestone and pick up from there next time.

## Ground rules for this module
- **Docs over tutorials.** If you get stuck, go to the linked doc page first, then the class reference, then search the official forum. Don't follow a "make Pong in Godot" video. That would defeat the point.
- **Use placeholder art.** `ColorRect`s and simple shapes only. Graphics are not the lesson.
- **Commit at every milestone.** You know why. 🙂
- **Write down your confusion.** A one-liner in the `PROGRESS.md` session log is worth more to your review than you'd think.

## Launching Godot
Your editor binary is at `/home/citrus/.local/opt/godot/Godot_v4.7.2-stable_linux.x86_64`. Consider making it easier to launch (a symlink on your `PATH`, a shell alias, or a `.desktop` entry). Doing that is up to you.
