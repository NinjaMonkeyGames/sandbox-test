# DEVELOPER

- [DEVELOPER](#developer)
  - [Developer Documentation](#developer-documentation)
  - [How to Use This Guide](#how-to-use-this-guide)
  - [HIGH LEVEL OVERVIEW](#high-level-overview)
  - [1. Architecture Overview](#1-architecture-overview)
    - [Event wiring](#event-wiring)
  - [2. Creating a Grid](#2-creating-a-grid)
    - [Constructor parameters](#constructor-parameters)
  - [3. Public API (Instance Methods)](#3-public-api-instance-methods)
    - [Default input bindings (inside `step()`)](#default-input-bindings-inside-step)
  - [4. Data Layout](#4-data-layout)
    - [`cell_data[row][column]` struct](#cell_datarowcolumn-struct)
    - [Vertex buffer (`vbuff`)](#vertex-buffer-vbuff)
  - [5. Limits \& Macros](#5-limits--macros)
  - [6. Label Text Conversion](#6-label-text-conversion)
  - [7. Zoom Behaviour](#7-zoom-behaviour)
  - [8. Typical Lifecycle](#8-typical-lifecycle)
  - [9. Known Quirks / Things to Watch](#9-known-quirks--things-to-watch)
  - [10. Extending the System](#10-extending-the-system)
  - [CONTACT INFORMATION](#contact-information)
  - [COPYRIGHT](#copyright)

## Developer Documentation

This document serves as the **technical blueprint for this project**. While `CONTRIBUTING.md` outlines the *how-to* for
processes and standards, this guide focuses on the *why* and *what* of the system architecture, internal logic, and
codebase organisation.

*Note: Please refer to the **[CONTRIBUTING.md](CONTRIBUTING.md)** for information regarding coding style, pull request
processes, and commit message conventions.*

## How to Use This Guide

PLACEHOLDER

## HIGH LEVEL OVERVIEW

All `new` instances of 'grid' are generated with the grid controller object 'obj_grid_controller'. To generate an
instance simply use the following syntax:

```gml
example_variable = grid(arguments);
```

A GameMaker Language (GML) system for rendering and interacting with a 2D reference grid (rows,
columns, spreadsheet/atlas-style labels, mouse picking, zoom, and panning). Built around a
`grid()` constructor struct so any number of independent grid instances can exist at once.

---

## 1. Architecture Overview

The system has two moving parts:

| Piece                 | Role                                                                                      |
| --------------------- | ----------------------------------------------------------------------------------------- |
| `obj_grid_controller` | Single controller instance in the room; its Step/Draw/Clean Up events iterate every grid. |
| `grid()` constructor  | A struct (not an instance) for one grid: geometry, vertex buffer, cell data, input state. |

Grids register themselves in a global array on creation and deregister on destruction:

```gml
global.grid_list        // array of live grid structs
global.grid_controller  // the single obj_grid_controller instance
global.grid_vformat     // vertex format shared by ALL grid instances (built once, lazily)
```

**Important:** a `grid()` struct is inert on its own — nothing calls its `step()`/`draw()` unless
it is present in `global.grid_list`. The constructor pushes `self` into that array automatically,
so you never need to do this manually; you only need `obj_grid_controller` to exist somewhere in
the room.

### Event wiring

| Event               | Source                | What it does                                                           |
| ------------------- | --------------------- | ---------------------------------------------------------------------- |
| Room / Create       | "INITIALISE PROJECT"  | Sets window caption; creates the controller and one example `grid()`.  |
| Controller Create   | "the create"          | Declares `grid_list` / `grid_vformat`; defines the `grid` constructor. |
| Controller Step     | "is the step"         | Calls `.step()` on every entry in `global.grid_list`.                  |
| Controller Draw     | "is draw"             | Calls `.draw()` on every entry in `global.grid_list`.                  |
| Controller Clean Up | "is the cleanup step" | Calls `.destroy()` on every entry in `global.grid_list`.               |

⚠️ **Order-of-operations gotcha:** the `grid` constructor function is *defined* inside
`obj_grid_controller`'s Create event. Any code calling `new obj_grid_controller.grid()` must run
**after** that instance exists — e.g. the room-start code creates the controller first, then the
example grid. Reversing this order means the constructor doesn't exist yet.

---

## 2. Creating a Grid

```gml
my_grid = new obj_grid_controller.grid(
    x_offset, y_offset,
    cell_width, cell_height,
    row_qty, column_qty,
    label_text_type_row, label_text_type_column,
    grid_colour, text_colour, text_colour_selected
);
```

All parameters are optional and default to a 24×18 letter/number labelled grid at `(32, 32)` with
64×64 cells.

### Constructor parameters

| Param                     | Default   | Description                                                   |
| ------------------------- | --------- | ------------------------------------------------------------- |
| `_x_offset`               | `32`      | Top-left X origin of the grid, in room/GUI pixels.            |
| `_y_offset`               | `32`      | Top-left Y origin.                                            |
| `_cell_width`             | `64`      | Width of one cell (clamped 8–512).                            |
| `_cell_height`            | `64`      | Height of one cell (clamped 8–512).                           |
| `_row_qty`                | `18`      | Number of rows (clamped 1–128).                               |
| `_column_qty`             | `24`      | Number of columns (clamped 1–128).                            |
| `_label_text_type_row`    | `false`   | `true` = row labels as letters (A, B, C…), `false` = numbers. |
| `_label_text_type_column` | `true`    | Same, for column labels.                                      |
| `_grid_colour`            | `c_white` | Line colour.                                                  |
| `_text_colour`            | `c_white` | Default label colour.                                         |
| `_text_colour_selected`   | `c_red`   | Label colour when the row/column is under the mouse.          |

Row labels are drawn to the **left** of column 0; column labels are drawn **above** row 0
(spreadsheet/atlas convention).

---

## 3. Public API (Instance Methods)

| Method                  | Signature                | Description                                                     |
| ----------------------- | ------------------------ | --------------------------------------------------------------- |
| `set_grid()`            | `()`                     | Rebuilds the vertex buffer and `cell_data` array.               |
| `get_x(_x)`             | `_x = mouse_x`           | Column index under a given X, clamped to a valid range.         |
| `get_y(_y)`             | `_y = mouse_y`           | Row index under a given Y, clamped to a valid range.            |
| `shift_x(_value)`       | `_value: Real`           | Pans columns (negative = left), clamps, rebuilds grid.          |
| `shift_y(_value)`       | `_value: Real`           | Pans rows (negative = up), clamps, rebuilds grid.               |
| `set_coords()`          | `()`                     | Recolours row/column labels based on mouse position.            |
| `update_row(_value)`    | `_value: Real`           | Changes row count, revalidates shift, rebuilds grid.            |
| `update_column(_value)` | `_value: Real`           | Changes column count, revalidates shift, rebuilds grid.         |
| `zoom(_zoom_direction)` | `_zoom_direction = true` | `true` zooms in, `false` zooms out. No-ops past limits.         |
| `set_cursor()`          | `()`                     | Swaps cursor to `cr_handpoint` over the grid, restores default. |
| `step()`                | `()`                     | Per-frame update: wheel zoom, arrow-key panning, hover state.   |
| `draw()`                | `()`                     | Submits the vertex buffer and draws every cell's labels.        |
| `destroy()`             | `()`                     | Removes struct from `global.grid_list`, frees its buffer.       |

`destroy()` **must** be called when a grid is no longer needed, or its vertex buffer leaks GPU
memory.

### Default input bindings (inside `step()`)

| Input            | Effect                       |
| ---------------- | ---------------------------- |
| Mouse wheel down | `zoom(true)` — zoom in       |
| Mouse wheel up   | `zoom(false)` — zoom out     |
| ← / → arrow keys | `shift_x(-1)` / `shift_x(1)` |
| ↑ / ↓ arrow keys | `shift_y(-1)` / `shift_y(1)` |

There is no built-in way to disable these bindings per-instance. If you need a non-interactive
grid, don't call `step()` for it — keep it out of `global.grid_list`, or fork the method.

---

## 4. Data Layout

### `cell_data[row][column]` struct

Rebuilt in full on every `set_grid()` call:

```gml
{
    x1, y1, x2, y2,                           // cell bounding box (world/GUI space)
    label_row_text,      label_column_text,   // "" unless this cell is on the left/top edge
    label_row_x, label_row_y,                 // row label draw position (left edge only)
    label_column_x, label_column_y,           // column label draw position (top edge only)
    label_text_colour_x, label_text_colour_y, // current highlight colour for each label
    label_text_x_alpha, label_text_y_alpha,   // currently always 1 (reserved)
    outline                                   // currently always true (reserved, unused)
}
```

Only cells in column 0 get a populated `label_row_text`; only cells in row 0 get a populated
`label_column_text`. Every other cell has empty strings for both.

### Vertex buffer (`vbuff`)

- Format: position + colour, shared globally as `global.grid_vformat` (built once, on the first
  grid's construction).
- Contains only the grid line geometry (`pr_linelist`), rebuilt and re-frozen on every `set_grid()`
  call.
- **Frozen** (`vertex_freeze`) immediately after building for a GPU-side speed win — safe because
  the buffer is fully rebuilt, not partially updated, on every change.
- Always deleted before a rebuild and on `destroy()`. Bypassing `set_grid()`/`destroy()` and
  nullifying a grid struct directly will leak the buffer.

---

## 5. Limits & Macros

| Macro                            | Value        | Applies to    |
| -------------------------------- | ------------ | ------------- |
| `LIMIT_CELL_WIDTH_MIN` / `MAX`   | 8 / 512      | `cell_width`  |
| `LIMIT_CELL_HEIGHT_MIN` / `MAX`  | 8 / 512      | `cell_height` |
| `LIMIT_ROW_QTY_MIN` / `MAX`      | 1 / 128      | `row_qty`     |
| `LIMIT_COLUMN_QTY_MIN` / `MAX`   | 1 / 128      | `column_qty`  |
| `LIMIT_ROW_SHIFT_MIN` / `MAX`    | -9999 / 9999 | `y_shift`     |
| `LIMIT_COLUMN_SHIFT_MIN` / `MAX` | -9999 / 9999 | `x_shift`     |
| `LIMIT_X_SCALE_MIN` / `MAX`      | 0.25 / 2     | `x_scale`     |
| `LIMIT_Y_SCALE_MIN` / `MAX`      | 0.25 / 2     | `y_scale`     |

All of the above are enforced with `clamp()` wherever the relevant value is set. Direct property
assignment (e.g. `my_grid.row_qty = 999`) **bypasses these limits** and does not call `set_grid()`
automatically. Always use the setter methods (`update_row`, `update_column`, `shift_x`, `shift_y`,
`zoom`) instead of writing to properties directly.

`clamp_shifts()` is an internal helper — not listed in §3 since it's a support function, not a
public entry point — that re-derives shift bounds from the *current* `row_qty`/`column_qty`. It
runs automatically whenever row/column count changes, so panning offsets don't go stale relative
to a resized grid.

---

## 6. Label Text Conversion

`spt_convert_letters(_number)` converts a zero-based (plus shift) index into a spreadsheet-style
letter label (0→A, 1→B, …, 25→Z, 26→AA, …), including negative-number handling (prefixes `-`).
Used internally whenever `label_text_type_row` / `label_text_type_column` is `true`. It's a pure
function and can be called standalone for other UI needs, e.g.:

```gml
example_grid.spt_convert_letters(27); // "AB"
```

---

## 7. Zoom Behaviour

`zoom()` preserves total on-screen grid size by trading scale for cell count:

- **Zoom in** (`true`): `x_scale`/`y_scale` ×2, `row_qty`/`column_qty` ÷2 (rounded).
- **Zoom out** (`false`): `x_scale`/`y_scale` ÷2, `row_qty`/`column_qty` ×2.

Each direction is validated against the absolute scale and row/column-quantity macros **before**
being applied. If the resulting state would breach a limit, the call is silently ignored (state
unchanged) and `set_grid()` still runs as a harmless no-op rebuild. This means zoom is
lossy/asymmetric at odd row/column counts (`round()` on zoom-in), so repeated in/out cycles are
not guaranteed to return to the exact original `row_qty`/`column_qty`.

---

## 8. Typical Lifecycle

```gml
// --- Create ---
my_grid = new obj_grid_controller.grid(0, 0, 32, 32, 20, 20);

// --- Step (if managing manually, outside global.grid_list) ---
my_grid.step();

// --- Draw ---
my_grid.draw();

// --- Resize on the fly ---
my_grid.update_column(30);
my_grid.update_row(15);

// --- Query mouse cell ---
var _col = my_grid.get_x();
var _row = my_grid.get_y();

// --- Cleanup ---
my_grid.destroy();
my_grid = undefined;
```

Since the constructor auto-registers into `global.grid_list`, in the common case you don't call
`step()`/`draw()`/`destroy()` yourself — `obj_grid_controller` does it for every grid each frame.
Manual calls are only needed for a grid you deliberately keep **out** of that list.

---

## 9. Known Quirks / Things to Watch

- **Draw call reuses one colour across all four channels.** `draw_text_ext_colour()` is called
  with `label_text_colour_x` repeated for all four corner-colour arguments (and again for
  `label_text_colour_y`). This is intentional flat colour, not a bug, but worth knowing before
  adding gradient labels.
- **`outline` and the alpha fields in `cell_data` are currently unused** by `draw()`. They're
  reserved for future per-cell styling (selective outlines, fade transitions) but have no effect
  today.
- **Direct property mutation bypasses clamping and doesn't trigger a rebuild.** Always go through
  the setter methods listed in §3.
- **`set_grid()` is O(rows × columns).** It fully rebuilds `cell_data` and the vertex buffer from
  scratch on every parameter change — including every `shift_x`/`shift_y` call, i.e. every
  arrow-key press during `step()`. Fine at the documented 128×128 max, not designed for continuous
  per-frame mutation beyond that.
- **`global.grid_vformat` is built once and shared.** All grids must use the same vertex layout
  (position + colour); there's no per-grid vertex-format override.
- **Forgetting `destroy()` leaks a vertex buffer per grid.** The room's Clean Up event only covers
  grids still in `global.grid_list` when the room ends — grids you manually removed from that list
  must be destroyed by your own code.

---

## 10. Extending the System

Reasonable extension points if you're modifying this code:

- **Custom cursor per grid**: `set_cursor()` currently hardcodes `cr_handpoint`; parameterize this
  if different grids need different cursors.
- **Per-cell data payloads**: `cell_data[row][column]` is a plain struct, so adding your own
  fields (e.g. `value`, `occupied`, `entity_id`) is safe if they don't collide with existing
  names. Note `set_grid()` fully overwrites the struct on rebuild, so persist/restore any custom
  fields around `set_grid()` calls yourself.
- **Alternate label schemes**: swap the `spt_convert_letters` calls in `set_grid()` for any other
  formatter taking a `Real` and returning a `String`.
- **Disabling default input**: fork `step()` for a grid that shouldn't respond to mouse wheel or
  arrow keys (e.g. a display-only minimap grid).

## CONTACT INFORMATION

Author: Daniel Mallett (Monkey Knuckles)

If you have any problems with the repository or have any suggestions please contact us at <info@ninjamonkeygames.com>.

You may also contact us via our [website](https://ninjamonkeygames.com).

Any bugs should be raised as an [issue](https://github.com/NinjaMonkeyGames/project-name-here/issues) on GitHub.

---

## COPYRIGHT

*NinjaMonkeyGames™ Copyright © 2026 All rights reserved.*
