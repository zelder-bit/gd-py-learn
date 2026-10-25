# Progress

## Status
| Module | Track | Status | Started | Reviewed |
|---|---|---|---|---|
| 01 · Pong | Godot | 🟡 Ready to start | | |
| 02 · Log Analyzer CLI | Python | 🔒 Locked (unlocks after Module 1 review) | | |
| 03 · Snake | Godot | 🔒 | | |
| 04 · System Monitor TUI | Python | 🔒 | | |
| 05 · Breakout | Godot | 🔒 | | |
| 06 · Level/Data Validator | Python | 🔒 | | |
| 07+ | — | 🔒 see ROADMAP.md | | |

## Module 1 · Pong (`projects/01-pong/`)
- [ ] Lesson 01 · Editor, scene tree & GDScript basics
- [ ] Lesson 02 · Input & paddles
- [ ] Lesson 03 · The ball: velocity & wall bounces
- [ ] Lesson 04 · Paddle collisions & bounce angles
- [ ] Lesson 05 · Goals, scoring & signals
- [ ] Lesson 06 · Game states & the CPU paddle
- [ ] Lesson 07 · Polish, win condition & review prep
- [ ] 🔍 Requested code review

## Session Log
Add a line after each session: what you did, what confused you, and any questions for the next review. These notes go into your code review.

| Date | Lesson | Time | Notes / blockers |
|---|---|---|---|
| | | | |
|10-20-2026 | 01-Pong | 10PM - 10:10PM   | Can't find viewport window adjustment.
|10-20-2026| 01-Pong |10:17 PM | Was treating the spec section like the lesson, woops.|
|10-20-2026|01-pong|||
|10-24-2026|01-pong|6:06 PM|Set strecth to canvas so that it resizes automatically. I set the aspect to keep so that the play area doesnt get distorted.|
|10-24-2026|01-pong|7:28 PM| For this section in https://docs.godotengine.org/en/stable/getting_started/step_by_step/scripting_first_script.html - This expression, Vector2.UP.rotated(rotation) , how does this add velocity? Without the speed does it just make the icnon move up while rotating? |
|10-24-2026|01-pong|7:49 PM|"Break it on purpose" - Output seems to catch items earlier. If i attempt to run a scene with broken syntax, it shows up in the debugger panel and provides a stack trace|
|10-24-2026|01-pong|8:01 PM| Stretch goal: Not sure what you are asking for res:// and $NodePath. I don't see anything significantly out of the ordinary. Not exactly sure what $NodePath is, i maybe overthinking it, is it just the paths to the nodes within the scene? Like ColorRect? Not sure.|
|||||

## Questions for Review
-
