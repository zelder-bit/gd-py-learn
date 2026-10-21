# Roadmap: Hand-Coded Godot 4 + Python

Two tracks that alternate every module. Each module ends with a **review gate**: you ask for a code review of `projects/NN-*`, and the next module only gets generated after that review, calibrated to what your code shows.

| | |
|---|---|
| **Pace** | 1–2 h sessions, 3–4×/week. A module is about 6–8 sessions (~2 weeks). |
| **Starting point** | Odin Foundations done (JS: functions, loops, arrays, objects, DOM). Python and GDScript are both new. |
| **Bridge language** | JavaScript (from Odin) for syntax; AWS/Linux/CCNA for architecture. |
| **Toolchain** | Godot 4.7.2 · Python 3.14 · `uv` · git |
| **Your code lives in** | `projects/NN-name/` (one Godot project or uv project per module) |

Only the next module is spelled out in detail. The later modules are a plan that will be revised as we go.

---

## Phase 1: Foundations (Modules 1–6)
The goal is fluency in both languages and the Godot scene tree. Every project is small enough to hold entirely in your head.

### Module 1 · Godot: Pong ✅ *generated*
Editor, scene tree, nodes vs. scenes vs. scripts, GDScript syntax (bridged from JS), `_ready`/`_process`/`_physics_process`, Input Map, `Vector2`, physics bodies and collision, custom signals, a minimal game-state `enum`.
**Bridge:** the scene tree is a process tree or filesystem; signals are SNS/EventBridge-style pub/sub; the frame loop is a control loop or reconciler.

### Module 2 · Python: Foundations via a Log Analyzer CLI
Python syntax from zero (bridged from JS), `uv init`/`uv run`, types, collections (list/dict/set/tuple), comprehensions, functions, `pathlib`, file I/O, `re`, `argparse`, exit codes, `if __name__ == "__main__"`.
**Project:** `logscan`, a CLI that parses real logs (journald export, nginx/sshd auth logs) and prints top-N stats: failed SSH logins by IP, status-code histograms.
**Bridge:** everything you already do with `grep | awk | sort | uniq -c`, done as a program.

### Module 3 · Godot: Snake
Grid vs. pixel space, `Array` as a queue, `Timer` node for a fixed tick, spawning with `randi()`, self-collision checks, game-over and restart, scene switching (`change_scene_to_file`), `_unhandled_input` and buffering input.
**Bridge:** a fixed-tick update is a cron or polling interval; the snake body is a FIFO queue.

### Module 4 · Python: OOP + Testing via a System Monitor TUI
Classes, `@dataclass`, modules and packages, type hints, `pytest`, `psutil`, `rich` (tables and live display). Packaging as a `uv` tool you can install (`uv tool install .`).
**Project:** `sysmon`, a live terminal dashboard of CPU, memory, disk, top processes, and listening sockets.
**Bridge:** `htop`/`ss -tlnp`, rebuilt by you.

### Module 5 · Godot: Breakout
Scene instancing (`PackedScene`), groups, levels defined as data (arrays → bricks), `GPUParticles2D`, `AudioStreamPlayer`, tweens, screen shake, and "juice" in general.
**Bridge:** a `PackedScene` is an AMI or launch template; instancing is launching from it.

### Module 6 · Python: Game-Dev Helper, a Level & Data Validator
JSON/CSV handling, schema validation (`pydantic`), useful error messages, `typer` CLI, exit codes for CI use.
**Project:** a tool that validates and generates level files for your Breakout game (and later games), plus a git pre-commit hook that runs it.
**Bridge:** `cfn-lint`/`terraform validate` for your own game data.

---

## Phase 2: Architecture & Systems (Modules 7–12)
The goal is reusable patterns: state machines, data-driven design, persistence, and async I/O.

### Module 7 · Godot: Asteroids (or Space Invaders)
Object pooling, screen wrap, wave spawner, Autoloads (singletons) for score and settings, saving a high score (`ConfigFile`/`FileAccess`), pause menu, `CanvasLayer` UI.
**Bridge:** an object pool is a warm pool or connection pool; an Autoload is a shared service, which carries the same risks as global state.

### Module 8 · Python: Async Home-Lab Health Checker
`asyncio`, `httpx`, TCP/port checks with `asyncio.open_connection`, timeouts and retries, YAML config, scheduling, and alerts sent to a Discord webhook.
**Project:** `homewatch`, which checks your self-hosted services concurrently and alerts when something goes down.
**Bridge:** this one's natural for you (CCNA plus CloudWatch alarms): you're building a tiny Route 53 health checker and the SNS step after it.

### Module 9 · Godot: Platformer Character + Finite State Machine
A node-based FSM (idle/run/jump/fall/attack), custom `Resource` classes for stats, `AnimationPlayer`/`AnimatedSprite2D`, `TileMapLayer`, coyote time and jump buffering.
**Bridge:** an FSM is a Step Functions state machine; a `Resource` is a typed config object, like a CloudFormation parameter set.

### Module 10 · Python: FastAPI + SQLite Personal Dashboard
FastAPI, Pydantic models, `sqlite3` (raw SQL first, then a light abstraction), REST design, dependency injection, and a small HTML front end (ties back to Odin).
**Project:** a self-hosted tracker (habits, homelab inventory, or game-session log) with a REST API and a dashboard page, run under systemd.

### Module 11 · Godot: Top-Down RPG Slice
`NavigationAgent2D` enemies with simple AI behaviours, an inventory built from `Resource`s, a dialogue system loaded from JSON, save/load serialization, scene transitions.

### Module 12 · Python: Asset & Data Pipeline for Godot
`watchdog` file watching, a sprite/asset organizer, a dialogue/item database linter for Module 11's data, and a Godot export automated in CI (headless Godot export in a GitHub Actions or local pipeline).
**Bridge:** this is a build pipeline, your home turf, aimed at your own game.

---

## Phase 3: Advanced (Modules 13+)
The goal is multi-system games built by hand, and knowing the architecture well enough to direct AI on large projects outside this repo.

### Module 13 · Godot: Networked Multiplayer
High-level multiplayer (`ENetMultiplayerPeer`, `MultiplayerSpawner`, `MultiplayerSynchronizer`), RPCs, authority, client-side prediction basics, lag and jitter. Probably a 2-player networked version of an earlier game.
**Bridge:** your CCNA pays off here. UDP vs. reliable channels, NAT, latency budgets, and authoritative servers as a single source of truth.

### Module 14 · Python: Discord Bot / Ops Capstone
A Discord bot (`discord.py`) that ties together Module 8 (health checks), Module 10 (API), and Module 12 (build triggers): ChatOps for your home lab and your game builds.

### Module 15 · Godot: Capstone Game
Write a design doc first, then the architecture: event bus, composition over inheritance, scene management, data-driven content. You plan it, build it by hand, and finish with a retrospective called "how I would brief an AI to build this at 10× scale."

---

## How a module works
1. Read `modules/NN-*/README.md` for the goal, the final spec, and the session plan.
2. Work through each lesson in order. Every lesson has: concepts → spec → milestones → hints → docs → stretch goals.
3. Write all code yourself in `projects/NN-*`. Use the docs, not AI. Asking Claude **conceptual** questions is fine ("what's the difference between `_process` and `_physics_process`?"). Asking for implementations isn't.
4. Tick boxes in `PROGRESS.md` and commit as you go.
5. When the module's final spec works, ask: *"Review my code for Module N."*
