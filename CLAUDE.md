# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

A classic Tetris implementation in vanilla JavaScript (ES6+), HTML5 Canvas, and CSS. No dependencies, no build step, no package.json — the entire game is three files.

## Running the game

There is no build/lint/test tooling. To run it, just serve/open `index.html`:

```bash
# Open directly
start index.html          # Windows
open index.html           # macOS

# Or serve locally (needed if testing anything that requires http:// origin)
python3 -m http.server 8000
npx serve .
```

There are no automated tests. Verify changes by playing the game in a browser and exercising the controls (arrows to move, `↑`/`X` to rotate, `↓` soft drop, `Space` hard drop, `P` pause).

## Architecture

Three files, each with a single responsibility:

- **`index.html`** — DOM structure: the main `#board` canvas (300×600, i.e. `COLS×BLOCK` by `ROWS×BLOCK`), the `#next-canvas` preview, HUD elements (`#score`, `#lines`, `#level`), and the pause/game-over `#overlay`.
- **`style.css`** — dark/retro arcade visual styling only.
- **`game.js`** — all game logic. No modules/classes; a flat set of top-level functions and mutable module-level state (`board`, `current`, `next`, `score`, `lines`, `level`, `paused`, `gameOver`, `dropInterval`, etc.).

### Core model

- The board is a `ROWS × COLS` matrix (`createBoard`) where each cell is `0` (empty) or a color index `1–7` identifying which piece locked there.
- Pieces (`PIECES`) are defined as square matrices; `COLORS[i]` maps a piece's color index to its hex color.
- Rotation (`rotateCW`) is a transpose + row-reverse of the shape matrix.
- `tryRotate` implements basic wall kicks: after rotating, it tries offsets `[0, -1, 1, -2, 2]` until one doesn't collide, otherwise the rotation is discarded.
- `collide(shape, ox, oy)` is the single collision check used everywhere (movement, rotation, ghost projection, spawn validity).

### Game loop

`loop(ts)`, driven by `requestAnimationFrame`, accumulates elapsed time (`dropAccum`) and drops the current piece one row once `dropAccum >= dropInterval`; if it can't drop, it calls `lockPiece()` (merge into board → `clearLines()` → `spawn()` next piece).

Keyboard input is handled by a single `keydown` listener that dispatches on `e.code` (movement/rotate/soft-drop/hard-drop) plus a separate `P` handler for `togglePause()`.

### Scoring & leveling

- `LINE_SCORES = [0, 100, 300, 500, 800]` indexed by number of lines cleared at once, multiplied by `level`.
- Hard drop awards 2 points per cell dropped; soft drop awards 1 point per row.
- `level` increases every 10 lines; `dropInterval = max(100, 1000 - (level-1)*90)` ms.

### Rendering

`draw()` clears and redraws the grid, locked board cells, the ghost piece (projected via `ghostY()`, drawn at `globalAlpha = 0.2`), and the current piece, in that order, every frame. `drawNext()` renders the next-piece preview on its own small canvas/context.

## Tunable constants (in `game.js`)

`COLS`, `ROWS`, `BLOCK`, `COLORS`, `LINE_SCORES`, initial `dropInterval`. If `COLS`/`ROWS`/`BLOCK` change, update the `#board` canvas `width`/`height` in `index.html` to match (`COLS×BLOCK` and `ROWS×BLOCK`).

## Issue automation

`.github/workflows/claude-issue-triage.yml` runs Claude on every issue `opened`/`edited` (skipped when the issue mentions `@claude`, which `claude.yml` already handles, or when the sender is a bot). It:

1. Syncs the project's label taxonomy from `.github/labels.json` via `scripts/sync-labels.sh` (`type:*`, `area:*` mapped to the architecture above, `prio:P1-P3`, `needs-info`, `triaged`, `duplicate`).
2. Runs the `/triage-issue` slash command (`.claude/commands/triage-issue.md`), which classifies the issue, applies labels through `scripts/edit-issue-labels.sh`, and posts a Spanish-language technical diagnosis (root cause, affected functions/`game.js:NN` references, proposed fix, manual verification steps) as a single sticky comment via `scripts/upsert-triage-comment.sh`.

Both scripts read the issue number from `$GITHUB_EVENT_PATH` rather than an argument, so Claude can only act on the issue that triggered the run. This is separate from `claude.yml` (interactive `@claude` mentions) and `claude-code-review.yml` (PR code review).
