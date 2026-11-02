// RUNS A SERIES OF UNIT TESTS

global.test_pass = 0;
global.test_fail = 0;

/// @function				test_assert()
/// @description			Records a pass/fail result, logs it, and quits with an error code if failed.
/// @param {Bool}			_condition
/// @param {String}			_label

function test_assert(_condition, _label)
{
	if (_condition)
	{
	    global.test_pass++;
	    show_debug_message("[PASS] " + _label);
	}
		else
	{
	    global.test_fail++;
	    show_debug_message("[FAIL] " + _label);
	    show_debug_message("CRITICAL: Unit test failed. Terminating game.");
	    game_end(1); // Quit the game with a non-zero error status
	}
}

/// @function           test_expect_throw()
/// @description        Runs _callback and asserts that it throws.
/// @param {Function}   _callback
/// @param {String}     _label

function test_expect_throw(_callback, _label)
{
	var _threw = false;

	try
	{
	    _callback();
	}
	
	catch (_err)
	{
	    _threw = true;
	}

	test_assert(_threw, _label + " (expected throw)");
}

/// @function           test_expect_no_throw()
/// @description        Runs _callback and asserts that it does NOT throw. Returns whatever _callback returns.
/// @param {Function}   _callback
/// @param {String}     _label

function test_expect_no_throw(_callback, _label)
{
	var _threw  = false;
	var _result = undefined;

	try
	{
	    _result = _callback();
	}
	
	catch (_err)
	{
	    _threw = true;
	}

	test_assert(!_threw, _label + " (expected no throw)");
	return _result;
}

/// @function           test_make_tile_data()
/// @description        Builds a VALID [row][column] tile array (spr_jungle_temple, index 0, angle 0, alpha 1).
///                     Tests then corrupt one tile to check that it is rejected.
/// @param {Real}       _rows
/// @param {Real}       _columns
/// @returns {Array}

function test_make_tile_data(_rows, _columns)
{
	var _data = [];

	repeat (_rows)
	{
		var _row = [];

		repeat (_columns)
		{
			array_push(_row, { sprite : spr_jungle_temple, index : 0, angle : 0, alpha : 1 });
		}

		array_push(_data, _row);
	}

	return _data;
}


// =========================================================================
// 1. CONSTRUCTOR - TYPE CHECKS
// =========================================================================

// Feather disable GM1029
// Feather disable GM1041
// Feather disable GM1044

test_expect_throw(function()
{
	new obj_grid_controller.grid("32", 32, 64, 64, 12, 16);
}, "Constructor: x_offset as string");

test_expect_throw(function()
{
	new obj_grid_controller.grid(32, "32", 64, 64, 12, 16);
}, "Constructor: y_offset as string (not swapped for default)");

test_expect_throw(function()
{
	
	new obj_grid_controller.grid(32, 32, [64], 64, 12, 16); 
}, "Constructor: cell_width as array");

test_expect_throw(function()
{
	new obj_grid_controller.grid(32, 32, 64, 64, 12, 16, "false", false);
}, "Constructor: label_text_type_row as string instead of bool");

test_expect_throw(function()
{
	new obj_grid_controller.grid(32, 32, 64, 64, 12, 16, false, false, "c_white");
}, "Constructor: grid_colour as string");

// Feather enable GM1029
// Feather enable GM1041
// Feather enable GM1044

// =========================================================================
// 2. CONSTRUCTOR - WHOLE NUMBER CHECKS
// =========================================================================

test_expect_throw(function()
{
	new obj_grid_controller.grid(32, 32, 64.5, 64, 12, 16);
}, "Constructor: cell_width fractional (64.5)");

test_expect_throw(function()
{
	new obj_grid_controller.grid(32, 32, 64, 64.25, 12, 16);
}, "Constructor: cell_height fractional (64.25)");

test_expect_throw(function()
{
	new obj_grid_controller.grid(32, 32, 64, 64, 8.5, 16);
}, "Constructor: row_qty fractional (8.5)");

test_expect_throw(function()
{
	new obj_grid_controller.grid(32, 32, 64, 64, 12, 8.5);
}, "Constructor: column_qty fractional (8.5)");


// =========================================================================
// 3. CONSTRUCTOR - RANGE BOUNDARIES (cell_width / cell_height: 8-256)
// =========================================================================

var _grid_cw_min = test_expect_no_throw(function()
{
	return new obj_grid_controller.grid(32, 32, LIMIT_CELL_WIDTH_MIN, LIMIT_CELL_HEIGHT_MIN, 12, 16);
}, "Constructor: cell_width/height at exact MIN (8)");
if (!is_undefined(_grid_cw_min)) then _grid_cw_min.destroy();

var _grid_cw_max = test_expect_no_throw(function()
{
	return new obj_grid_controller.grid(32, 32, LIMIT_CELL_WIDTH_MAX, LIMIT_CELL_HEIGHT_MAX, 12, 16);
}, "Constructor: cell_width/height at exact MAX (256)");
if (!is_undefined(_grid_cw_max)) then _grid_cw_max.destroy();

test_expect_throw(function()
{
	new obj_grid_controller.grid(32, 32, LIMIT_CELL_WIDTH_MIN - 1, 64, 12, 16);
}, "Constructor: cell_width one below MIN (7)");

test_expect_throw(function()
{
	new obj_grid_controller.grid(32, 32, LIMIT_CELL_WIDTH_MAX + 1, 64, 12, 16);
}, "Constructor: cell_width one above MAX (257)");

test_expect_throw(function()
{
	new obj_grid_controller.grid(32, 32, 64, LIMIT_CELL_HEIGHT_MIN - 1, 12, 16);
}, "Constructor: cell_height one below MIN (7)");

test_expect_throw(function()
{
	new obj_grid_controller.grid(32, 32, 64, LIMIT_CELL_HEIGHT_MAX + 1, 12, 16);
}, "Constructor: cell_height one above MAX (257)");


// =========================================================================
// 4. CONSTRUCTOR - RANGE BOUNDARIES (row_qty / column_qty: 1-128)
// =========================================================================

var _grid_rq_min = test_expect_no_throw(function()
{
	return new obj_grid_controller.grid(32, 32, 64, 64, LIMIT_ROW_QTY_MIN, LIMIT_COLUMN_QTY_MIN);
}, "Constructor: row_qty/column_qty at exact MIN (1)");
if (!is_undefined(_grid_rq_min)) then _grid_rq_min.destroy();

var _grid_rq_max = test_expect_no_throw(function()
{
	return new obj_grid_controller.grid(32, 32, 64, 64, LIMIT_ROW_QTY_MAX, LIMIT_COLUMN_QTY_MAX);
}, "Constructor: row_qty/column_qty at exact MAX (128)");
if (!is_undefined(_grid_rq_max)) then _grid_rq_max.destroy();

test_expect_throw(function()
{
	new obj_grid_controller.grid(32, 32, 64, 64, LIMIT_ROW_QTY_MIN - 1, 16);
}, "Constructor: row_qty one below MIN (0)");

test_expect_throw(function()
{
	new obj_grid_controller.grid(32, 32, 64, 64, LIMIT_ROW_QTY_MAX + 1, 16);
}, "Constructor: row_qty one above MAX (129)");

test_expect_throw(function()
{
	new obj_grid_controller.grid(32, 32, 64, 64, 12, LIMIT_COLUMN_QTY_MIN - 1);
}, "Constructor: column_qty one below MIN (0)");

test_expect_throw(function()
{
	new obj_grid_controller.grid(32, 32, 64, 64, 12, LIMIT_COLUMN_QTY_MAX + 1);
}, "Constructor: column_qty one above MAX (129)");


// =========================================================================
// 5. CONSTRUCTOR - COLOUR BOUNDARIES (0-16777215)
// =========================================================================

// Feather disable GM1029

var _grid_colour_min = test_expect_no_throw(function()
{
	return new obj_grid_controller.grid(32, 32, 64, 64, 12, 16, false, false, 0, 0, 0);
}, "Constructor: colours at exact MIN (0)");
if (!is_undefined(_grid_colour_min)) then _grid_colour_min.destroy();

var _grid_colour_max = test_expect_no_throw(function()
{
	return new obj_grid_controller.grid(32, 32, 64, 64, 12, 16, false, false, 16777215, 16777215, 16777215);
}, "Constructor: colours at exact MAX (16777215)");
if (!is_undefined(_grid_colour_max)) then _grid_colour_max.destroy();

test_expect_throw(function()
{
	new obj_grid_controller.grid(32, 32, 64, 64, 12, 16, false, false, -1);
}, "Constructor: grid_colour below MIN (-1)");

test_expect_throw(function()
{
	new obj_grid_controller.grid(32, 32, 64, 64, 12, 16, false, false, 16777216);
}, "Constructor: grid_colour above MAX (16777216)");

// Feather enable GM1029


// =========================================================================
// 6. shift_x() / shift_y() - TYPE & WHOLE NUMBER GUARDS
// =========================================================================

// Feather disable GM1044

unit_test = new obj_grid_controller.grid(32, 32, 64, 64, 12, 16, true, false, c_white, c_white, c_red);

test_expect_throw(function()
{
	unit_test.shift_x("1");
}, "shift_x: string argument");

test_expect_throw(function()
{
	unit_test.shift_x(1.5);
}, "shift_x: fractional argument");

test_expect_throw(function()
{
	unit_test.shift_y(undefined);
}, "shift_y: undefined argument");

test_expect_throw(function()
{
	unit_test.shift_y(0.1);
}, "shift_y: fractional argument");

// shift_x/shift_y should silently CLAMP large in-range-type values rather than throw

test_expect_no_throw(function()
{
	unit_test.shift_x(999999);
}, "shift_x: huge whole number is clamped, not thrown");

test_assert(unit_test.x_shift <= (1 + LIMIT_COLUMN_SHIFT_MAX - unit_test.column_qty), "shift_x: x_shift correctly clamped to upper bound");

test_expect_no_throw(function()
{
	unit_test.shift_y(-999999);
}, "shift_y: huge negative whole number is clamped, not thrown");

test_assert(unit_test.y_shift >= LIMIT_ROW_SHIFT_MIN, "shift_y: y_shift correctly clamped to lower bound");

// Feather enable GM1044

// =========================================================================
// 7. update_row() / update_column() - TYPE, WHOLE NUMBER & CLAMP BEHAVIOUR
// =========================================================================

test_expect_throw(function()
{
	unit_test.update_row("12");
}, "update_row: string argument");

test_expect_throw(function()
{
	unit_test.update_row(12.5);
}, "update_row: fractional argument");

test_expect_throw(function()
{
	unit_test.update_column(undefined);
}, "update_column: undefined argument");

test_expect_throw(function()
{
	unit_test.update_column(16.25);
}, "update_column: fractional argument");

// update_row/update_column clamp out-of-range whole numbers rather than throwing

test_expect_no_throw(function()
{
	unit_test.update_row(LIMIT_ROW_QTY_MAX + 50);
}, "update_row: value above MAX is clamped, not thrown");

test_assert(unit_test.row_qty == LIMIT_ROW_QTY_MAX, "update_row: row_qty clamped exactly to MAX");

test_expect_no_throw(function()
{
	unit_test.update_column(LIMIT_COLUMN_QTY_MIN - 50);
}, "update_column: value below MIN is clamped, not thrown");

test_assert(unit_test.column_qty == LIMIT_COLUMN_QTY_MIN, "update_column: column_qty clamped exactly to MIN");


// =========================================================================
// 8. get_x() / get_y() - CLAMPING AT SCREEN EXTREMES
// =========================================================================

// Feather disable GM1044

unit_test.destroy();
unit_test = new obj_grid_controller.grid(32, 32, 64, 64, 12, 16, true, false, c_white, c_white, c_red);

test_assert(unit_test.get_x(unit_test.x_offset - 99999) == 0, "get_x: far-left coordinate clamps to column 0");
test_assert(unit_test.get_x(unit_test.x_offset + 99999) == (unit_test.column_qty - 1), "get_x: far-right coordinate clamps to last column");

test_assert(unit_test.get_y(unit_test.y_offset - 99999) == 0, "get_y: far-above coordinate clamps to row 0");
test_assert(unit_test.get_y(unit_test.y_offset + 99999) == (unit_test.row_qty - 1), "get_y: far-below coordinate clamps to last row");

// Feather enable GM1044

// =========================================================================
// 9. zoom() - LIMIT BOUNDARIES
// =========================================================================

// Zoom out repeatedly until column/row qty would exceed LIMIT_*_QTY_MAX - values must stop growing, not overshoot.

unit_test.destroy();
unit_test = new obj_grid_controller.grid(32, 32, 64, 64, LIMIT_ROW_QTY_MAX, LIMIT_COLUMN_QTY_MAX);

test_expect_no_throw(function()
{
	unit_test.zoom(false); // zoom out - doubling would exceed MAX, so this call should be a no-op internally
}, "zoom(false): at MAX row/column qty does not throw");

test_assert(unit_test.row_qty == LIMIT_ROW_QTY_MAX, "zoom(false): row_qty unchanged when doubling would exceed MAX");
test_assert(unit_test.column_qty == LIMIT_COLUMN_QTY_MAX, "zoom(false): column_qty unchanged when doubling would exceed MAX");

unit_test.destroy();
unit_test = new obj_grid_controller.grid(32, 32, 64, 64, LIMIT_ROW_QTY_MIN, LIMIT_COLUMN_QTY_MIN);

test_expect_no_throw(function()
{
	unit_test.zoom(true); // zoom in - halving would go below MIN, so this call should be a no-op internally
}, "zoom(true): at MIN row/column qty does not throw");

test_assert(unit_test.row_qty == LIMIT_ROW_QTY_MIN, "zoom(true): row_qty unchanged when halving would go below MIN");
test_assert(unit_test.column_qty == LIMIT_COLUMN_QTY_MIN, "zoom(true): column_qty unchanged when halving would go below MIN");

// zoom() sanitises its own argument - a non-bool should not crash, just skip the scale change

test_expect_no_throw(function()
{
	unit_test.zoom("true");
}, "zoom: non-bool argument does not throw (silently ignored)");


// =========================================================================
// 10. LIFECYCLE - guard_alive() / destroy()
// =========================================================================

// Feather disable GM1044

unit_test.destroy();
unit_test = new obj_grid_controller.grid(32, 32, 64, 64, 12, 16, true, false, c_white, c_white, c_red);

var _index_before_destroy = array_get_index(global.grid_list, unit_test);
test_assert(_index_before_destroy != -1, "destroy(): instance is present in global.grid_list before destroy");

unit_test.destroy();

var _index_after_destroy = array_get_index(global.grid_list, unit_test);
test_assert(_index_after_destroy == -1, "destroy(): instance removed from global.grid_list after destroy");

test_expect_throw(function()
{
	unit_test.draw();
}, "guard_alive: draw() after destroy() throws instead of crashing on freed vbuff");

test_expect_throw(function()
{
	unit_test.step();
}, "guard_alive: step() after destroy() throws instead of indexing undefined cell_data");

test_expect_throw(function()
{
	unit_test.shift_x(1);
}, "guard_alive: shift_x() after destroy() throws");

test_expect_throw(function()
{
	unit_test.update_row(10);
}, "guard_alive: update_row() after destroy() throws");

test_expect_throw(function()
{
	unit_test.get_x(0);
}, "guard_alive: get_x() after destroy() throws");

test_expect_no_throw(function()
{
	unit_test.destroy(); // second destroy() call must be a safe no-op, not an error
}, "destroy(): calling destroy() twice does not throw");

// Feather enable GM1044

// Feather disable GM1029
// Feather disable GM1041
// Feather disable GM1044

// =========================================================================
// 11. CONSTRUCTOR - NaN / INFINITY (is_real(NaN) is true and NaN fails every comparison)
// =========================================================================

test_expect_throw(function()
{
	new obj_grid_controller.grid(NaN, 32, 64, 64, 12, 16);
}, "Constructor: x_offset NaN");

test_expect_throw(function()
{
	new obj_grid_controller.grid(infinity, 32, 64, 64, 12, 16);
}, "Constructor: x_offset infinity");

test_expect_throw(function()
{
	new obj_grid_controller.grid(32, -infinity, 64, 64, 12, 16);
}, "Constructor: y_offset -infinity");

test_expect_throw(function()
{
	new obj_grid_controller.grid(32, NaN, 64, 64, 12, 16);
}, "Constructor: y_offset NaN");

test_expect_throw(function()
{
	new obj_grid_controller.grid(32, 32, NaN, 64, 12, 16);
}, "Constructor: cell_width NaN");

test_expect_throw(function()
{
	new obj_grid_controller.grid(32, 32, 64, infinity, 12, 16);
}, "Constructor: cell_height infinity");

test_expect_throw(function()
{
	new obj_grid_controller.grid(32, 32, 64, 64, NaN, 16);
}, "Constructor: row_qty NaN");

test_expect_throw(function()
{
	new obj_grid_controller.grid(32, 32, 64, 64, 12, infinity);
}, "Constructor: column_qty infinity");

test_expect_throw(function()
{
	new obj_grid_controller.grid(32, 32, 64, 64, 12, 16, false, false, NaN);
}, "Constructor: grid_colour NaN");

test_expect_throw(function()
{
	new obj_grid_controller.grid(32, 32, 64, 64, 12, 16, false, false, c_white, NaN);
}, "Constructor: text_colour NaN");

test_expect_throw(function()
{
	new obj_grid_controller.grid(32, 32, 64, 64, 12, 16, false, false, c_white, c_white, NaN);
}, "Constructor: text_colour_selected NaN");

test_expect_throw(function()
{
	new obj_grid_controller.grid(32, 32, 64, 64, 12, 16, false, false, 100.5);
}, "Constructor: grid_colour fractional (100.5)");

// Offsets have no range limit, so negative values must still be accepted.

var _grid_negative_offset = test_expect_no_throw(function()
{
	return new obj_grid_controller.grid(-100, -200, 64, 64, 12, 16);
}, "Constructor: negative offsets are valid");
if (!is_undefined(_grid_negative_offset)) then _grid_negative_offset.destroy();


// =========================================================================
// 12. PUBLIC METHODS - NaN / INFINITY / BAD TYPES
// =========================================================================

unit_test = new obj_grid_controller.grid(32, 32, 64, 64, 12, 16, true, false, c_white, c_white, c_red);

test_expect_throw(function()
{
	unit_test.shift_x(NaN);
}, "shift_x: NaN argument");

test_expect_throw(function()
{
	unit_test.shift_y(infinity);
}, "shift_y: infinity argument");

test_expect_throw(function()
{
	unit_test.update_row(NaN);
}, "update_row: NaN argument");

test_expect_throw(function()
{
	unit_test.update_column(-infinity);
}, "update_column: -infinity argument");

test_expect_throw(function()
{
	unit_test.get_x(NaN);
}, "get_x: NaN argument (would otherwise return NaN as a column index)");

test_expect_throw(function()
{
	unit_test.get_y(infinity);
}, "get_y: infinity argument");

test_expect_throw(function()
{
	unit_test.get_x("abc");
}, "get_x: string argument");

test_expect_throw(function()
{
	unit_test.get_y([1]);
}, "get_y: array argument");

test_assert(unit_test.row_qty == 12 && unit_test.column_qty == 16, "Rejected arguments leave row/column quantities untouched");


// =========================================================================
// 13. convert_letters() - SPREADSHEET-STYLE LABELS
// =========================================================================

test_assert(unit_test.convert_letters(0) == "A", "convert_letters: 0 -> A");
test_assert(unit_test.convert_letters(1) == "B", "convert_letters: 1 -> B");
test_assert(unit_test.convert_letters(25) == "Z", "convert_letters: 25 -> Z");
test_assert(unit_test.convert_letters(26) == "AA", "convert_letters: 26 -> AA");
test_assert(unit_test.convert_letters(27) == "AB", "convert_letters: 27 -> AB");
test_assert(unit_test.convert_letters(701) == "ZZ", "convert_letters: 701 -> ZZ");
test_assert(unit_test.convert_letters(702) == "AAA", "convert_letters: 702 -> AAA");

test_expect_throw(function()
{
	unit_test.convert_letters(-1);
}, "convert_letters: negative number");

test_expect_throw(function()
{
	unit_test.convert_letters(NaN);
}, "convert_letters: NaN");

test_expect_throw(function()
{
	unit_test.convert_letters("A");
}, "convert_letters: string");

unit_test.destroy();


// =========================================================================
// 14. TILE DATA - VALID INPUT
// =========================================================================

var _grid_tiles_ok = test_expect_no_throw(function()
{
	var _data = test_make_tile_data(4, 6);
	return new obj_grid_controller.grid(,,,,,,,,,,,_data);
}, "Tile data: valid 4x6 array matching the grid");
if (!is_undefined(_grid_tiles_ok)) then _grid_tiles_ok.destroy();

var _grid_tiles_atlas = test_expect_no_throw(function()
{
	var _data = test_make_tile_data(30, 33);
	return new obj_grid_controller.grid(,,,,,,,,,,,_data);
}, "Tile data: valid 30x33 atlas larger than the grid");
if (!is_undefined(_grid_tiles_atlas)) then _grid_tiles_atlas.destroy();

// Exact boundaries of every tile field must be accepted.

var _grid_tiles_bounds = test_expect_no_throw(function()
{
	var _data = test_make_tile_data(4, 6);
	_data[0][0].index = sprite_get_number(spr_jungle_temple) - 1; // Last valid subimage
	_data[0][1].angle = 359;
	_data[0][2].alpha = 0;
	_data[0][3].alpha = 1;
	return new obj_grid_controller.grid(,,,,,,,,,,,_data);
}, "Tile data: field boundaries (last index, angle 359, alpha 0 and 1)");
if (!is_undefined(_grid_tiles_bounds)) then _grid_tiles_bounds.destroy();

// A row BEYOND the grid's rows may be shorter than the grid is wide (draw() bounds-checks per row).

var _grid_tiles_ragged = test_expect_no_throw(function()
{
	var _data = test_make_tile_data(6, 6);
	_data[5] = [ _data[5][0] ]; // Row 5 is outside the initial 4 rows
	return new obj_grid_controller.grid(,,,,,,,,,,,_data);
}, "Tile data: short row outside the initial grid area is allowed");
if (!is_undefined(_grid_tiles_ragged)) then _grid_tiles_ragged.destroy();


// =========================================================================
// 15. TILE DATA - CONTAINER SHAPE
// =========================================================================

test_expect_throw(function()
{
	new obj_grid_controller.grid(,,,,,,,,,,,"tiles");
}, "Tile data: string instead of array");

test_expect_throw(function()
{
	new obj_grid_controller.grid(,,,,,,,,,,,{});
}, "Tile data: struct instead of array");

test_expect_throw(function()
{
	new obj_grid_controller.grid(,,,,,,,,,,,5);
}, "Tile data: number instead of array");

test_expect_throw(function()
{
	new obj_grid_controller.grid(,,,,,,,,,,,[]);
}, "Tile data: empty array");

test_expect_throw(function()
{
	var _data = test_make_tile_data(2, 6); // Default grid has 4 rows
	new obj_grid_controller.grid(,,,,,,,,,,,_data);
}, "Tile data: fewer rows than the grid");

test_expect_throw(function()
{
	var _data = test_make_tile_data(4, 3); // Default grid has 6 columns
	new obj_grid_controller.grid(,,,,,,,,,,,_data);
}, "Tile data: fewer columns than the grid");

test_expect_throw(function()
{
	var _data = test_make_tile_data(4, 6);
	_data[2] = [ _data[2][0] ]; // Row 2 is inside the grid but too short
	new obj_grid_controller.grid(,,,,,,,,,,,_data);
}, "Tile data: short row inside the grid area");

test_expect_throw(function()
{
	var _data = test_make_tile_data(30, 33);
	_data[25] = 5; // Row outside the initial grid area is not an array
	new obj_grid_controller.grid(,,,,,,,,,,,_data);
}, "Tile data: non-array row outside the initial grid area");

test_expect_throw(function()
{
	var _data = test_make_tile_data(30, 33);
	_data[28] = []; // Empty row outside the initial grid area
	new obj_grid_controller.grid(,,,,,,,,,,,_data);
}, "Tile data: empty row outside the initial grid area");


// =========================================================================
// 16. TILE DATA - MALFORMED TILES (previously crashed inside validate_input)
// =========================================================================

test_expect_throw(function()
{
	var _data = test_make_tile_data(4, 6);
	_data[0][0] = undefined;
	new obj_grid_controller.grid(,,,,,,,,,,,_data);
}, "Tile: undefined instead of struct");

test_expect_throw(function()
{
	var _data = test_make_tile_data(4, 6);
	_data[1][2] = 5;
	new obj_grid_controller.grid(,,,,,,,,,,,_data);
}, "Tile: number instead of struct");

test_expect_throw(function()
{
	var _data = test_make_tile_data(4, 6);
	_data[3][5] = "tile";
	new obj_grid_controller.grid(,,,,,,,,,,,_data);
}, "Tile: string instead of struct");

test_expect_throw(function()
{
	var _data = test_make_tile_data(4, 6);
	_data[0][0] = [1, 2, 3];
	new obj_grid_controller.grid(,,,,,,,,,,,_data);
}, "Tile: array instead of struct");

test_expect_throw(function()
{
	var _data = test_make_tile_data(4, 6);
	variable_struct_remove(_data[1][1], "sprite");
	new obj_grid_controller.grid(,,,,,,,,,,,_data);
}, "Tile: missing sprite field");

test_expect_throw(function()
{
	var _data = test_make_tile_data(4, 6);
	variable_struct_remove(_data[1][1], "index");
	new obj_grid_controller.grid(,,,,,,,,,,,_data);
}, "Tile: missing index field");

test_expect_throw(function()
{
	var _data = test_make_tile_data(4, 6);
	variable_struct_remove(_data[1][1], "angle");
	new obj_grid_controller.grid(,,,,,,,,,,,_data);
}, "Tile: missing angle field");

test_expect_throw(function()
{
	var _data = test_make_tile_data(4, 6);
	variable_struct_remove(_data[1][1], "alpha");
	new obj_grid_controller.grid(,,,,,,,,,,,_data);
}, "Tile: missing alpha field");

test_expect_throw(function()
{
	var _data = test_make_tile_data(4, 6);
	_data[0][0] = {};
	new obj_grid_controller.grid(,,,,,,,,,,,_data);
}, "Tile: empty struct");


// =========================================================================
// 17. TILE DATA - FIELD TYPES AND RANGES
// =========================================================================

// Sprite: wrong type must throw cleanly, before reaching spt_get_asset_type_as_string.

test_expect_throw(function()
{
	var _data = test_make_tile_data(4, 6);
	_data[0][0].sprite = "spr_jungle_temple";
	new obj_grid_controller.grid(,,,,,,,,,,,_data);
}, "Tile sprite: string");

test_expect_throw(function()
{
	var _data = test_make_tile_data(4, 6);
	_data[0][0].sprite = undefined;
	new obj_grid_controller.grid(,,,,,,,,,,,_data);
}, "Tile sprite: undefined");

test_expect_throw(function()
{
	var _data = test_make_tile_data(4, 6);
	_data[0][0].sprite = {};
	new obj_grid_controller.grid(,,,,,,,,,,,_data);
}, "Tile sprite: struct");

test_expect_throw(function()
{
	var _data = test_make_tile_data(4, 6);
	_data[0][0].sprite = 99999999;
	new obj_grid_controller.grid(,,,,,,,,,,,_data);
}, "Tile sprite: id that does not exist");

test_expect_throw(function()
{
	var _data = test_make_tile_data(4, 6);
	_data[0][0].sprite = obj_grid_controller;
	new obj_grid_controller.grid(,,,,,,,,,,,_data);
}, "Tile sprite: asset that is not a sprite");

// Index

test_expect_throw(function()
{
	var _data = test_make_tile_data(4, 6);
	_data[0][0].index = sprite_get_number(spr_jungle_temple); // One past the last subimage (the off-by-one)
	new obj_grid_controller.grid(,,,,,,,,,,,_data);
}, "Tile index: equal to subimage count");

test_expect_throw(function()
{
	var _data = test_make_tile_data(4, 6);
	_data[0][0].index = -1;
	new obj_grid_controller.grid(,,,,,,,,,,,_data);
}, "Tile index: negative");

test_expect_throw(function()
{
	var _data = test_make_tile_data(4, 6);
	_data[0][0].index = 0.5;
	new obj_grid_controller.grid(,,,,,,,,,,,_data);
}, "Tile index: fractional");

test_expect_throw(function()
{
	var _data = test_make_tile_data(4, 6);
	_data[0][0].index = NaN;
	new obj_grid_controller.grid(,,,,,,,,,,,_data);
}, "Tile index: NaN");

test_expect_throw(function()
{
	var _data = test_make_tile_data(4, 6);
	_data[0][0].index = "0";
	new obj_grid_controller.grid(,,,,,,,,,,,_data);
}, "Tile index: string");

// Angle

test_expect_throw(function()
{
	var _data = test_make_tile_data(4, 6);
	_data[0][0].angle = -1;
	new obj_grid_controller.grid(,,,,,,,,,,,_data);
}, "Tile angle: below 0");

test_expect_throw(function()
{
	var _data = test_make_tile_data(4, 6);
	_data[0][0].angle = 360;
	new obj_grid_controller.grid(,,,,,,,,,,,_data);
}, "Tile angle: above 359");

test_expect_throw(function()
{
	var _data = test_make_tile_data(4, 6);
	_data[0][0].angle = 1.5;
	new obj_grid_controller.grid(,,,,,,,,,,,_data);
}, "Tile angle: fractional");

test_expect_throw(function()
{
	var _data = test_make_tile_data(4, 6);
	_data[0][0].angle = NaN;
	new obj_grid_controller.grid(,,,,,,,,,,,_data);
}, "Tile angle: NaN");

// Alpha

test_expect_throw(function()
{
	var _data = test_make_tile_data(4, 6);
	_data[0][0].alpha = -0.1;
	new obj_grid_controller.grid(,,,,,,,,,,,_data);
}, "Tile alpha: below 0");

test_expect_throw(function()
{
	var _data = test_make_tile_data(4, 6);
	_data[0][0].alpha = 1.1;
	new obj_grid_controller.grid(,,,,,,,,,,,_data);
}, "Tile alpha: above 1");

test_expect_throw(function()
{
	var _data = test_make_tile_data(4, 6);
	_data[0][0].alpha = NaN;
	new obj_grid_controller.grid(,,,,,,,,,,,_data);
}, "Tile alpha: NaN");

test_expect_throw(function()
{
	var _data = test_make_tile_data(4, 6);
	_data[0][0].alpha = "1";
	new obj_grid_controller.grid(,,,,,,,,,,,_data);
}, "Tile alpha: string");


// =========================================================================
// 18. TILE DATA - BAD TILES OUTSIDE THE INITIAL GRID AREA
//     (shift_x / shift_y / zoom(false) later expose these to draw(), so they must be caught up front)
// =========================================================================

test_expect_throw(function()
{
	var _data = test_make_tile_data(30, 33);
	_data[20][30] = undefined;
	new obj_grid_controller.grid(,,,,,,,,,,,_data);
}, "Tile outside grid area: non-struct tile at [20][30]");

test_expect_throw(function()
{
	var _data = test_make_tile_data(30, 33);
	_data[10][28].index = sprite_get_number(spr_jungle_temple);
	new obj_grid_controller.grid(,,,,,,,,,,,_data);
}, "Tile outside grid area: out-of-range index at [10][28]");

test_expect_throw(function()
{
	var _data = test_make_tile_data(30, 33);
	_data[29][32].alpha = 2;
	new obj_grid_controller.grid(,,,,,,,,,,,_data);
}, "Tile outside grid area: bad alpha in the very last tile");

test_expect_throw(function()
{
	var _data = test_make_tile_data(30, 33);
	variable_struct_remove(_data[4][0], "sprite"); // First row beyond the default 4 rows
	new obj_grid_controller.grid(,,,,,,,,,,,_data);
}, "Tile outside grid area: missing field in the first row below the grid");


// =========================================================================
// 19. SHIFT / ZOOM WITH TILE DATA, AND SHIFT CLAMPING AFTER zoom(false)
// =========================================================================

var _tile_atlas = test_make_tile_data(30, 33);
unit_test = new obj_grid_controller.grid(,,,,,,,,,,,_tile_atlas);

test_expect_no_throw(function()
{
	unit_test.shift_y(10);
	unit_test.shift_x(10);
}, "Shift: moving into the tile atlas does not throw");

test_expect_no_throw(function()
{
	unit_test.zoom(false);
}, "zoom(false): doubling the visible area over tile data does not throw");

test_assert(unit_test.x_shift >= LIMIT_COLUMN_SHIFT_MIN && unit_test.y_shift >= LIMIT_ROW_SHIFT_MIN, "Shift: never negative after zoom with tile data");

unit_test.destroy();

// Zoom must preserve the grid's physical size when counts are even.

unit_test = new obj_grid_controller.grid(32, 32, 64, 64, 4, 6);

var _width_before	= unit_test.grid_x2 - unit_test.grid_x1;
var _height_before	= unit_test.grid_y2 - unit_test.grid_y1;

unit_test.zoom(false);

test_assert(unit_test.row_qty == 8 && unit_test.column_qty == 12, "zoom(false): 4x6 becomes 8x12");
test_assert((unit_test.grid_x2 - unit_test.grid_x1) == _width_before, "zoom(false): physical width preserved");
test_assert((unit_test.grid_y2 - unit_test.grid_y1) == _height_before, "zoom(false): physical height preserved");

unit_test.zoom(true);

test_assert(unit_test.row_qty == 4 && unit_test.column_qty == 6, "zoom(true): returns to 4x6");
test_assert((unit_test.grid_x2 - unit_test.grid_x1) == _width_before, "zoom(true): physical width preserved");

unit_test.destroy();

// The old zoom() lacked the max() guard: 64 columns -> 128 inverted the clamp and left x_shift negative.

unit_test = new obj_grid_controller.grid(32, 32, 16, 16, 4, 64, false, true, c_white, c_white, c_red);
unit_test.shift_x(10);

test_expect_no_throw(function()
{
	unit_test.zoom(false);
}, "zoom(false): 64 -> 128 columns with letter labels does not throw");

test_assert(unit_test.column_qty == 128, "zoom(false): column_qty is 128");
test_assert(unit_test.x_shift == 0, "zoom(false): x_shift forced to 0, not negative, when no valid shift remains");
unit_test.destroy();

unit_test = new obj_grid_controller.grid(32, 32, 16, 16, 64, 4, true, false, c_white, c_white, c_red);
unit_test.shift_y(10);

test_expect_no_throw(function()
{
	unit_test.zoom(false);
}, "zoom(false): 64 -> 128 rows with letter labels does not throw");

test_assert(unit_test.row_qty == 128, "zoom(false): row_qty is 128");
test_assert(unit_test.y_shift == 0, "zoom(false): y_shift forced to 0, not negative, when no valid shift remains");
unit_test.destroy();

// Shifting down from 0 must stay at 0.

unit_test = new obj_grid_controller.grid(32, 32, 64, 64, 12, 16, true, false, c_white, c_white, c_red);
unit_test.shift_x(-5);
unit_test.shift_y(-5);
test_assert(unit_test.x_shift == 0 && unit_test.y_shift == 0, "Shift: negative shift from 0 stays at 0");
unit_test.destroy();


// =========================================================================
// 20. LABELS (stored once per row / column, not per cell)
// =========================================================================

unit_test = new obj_grid_controller.grid(32, 32, 64, 64, 30, 16, true, false, c_white, c_white, c_red);

test_assert(array_length(unit_test.row_labels) == 30, "Labels: one row label per row");
test_assert(array_length(unit_test.column_labels) == 16, "Labels: one column label per column");

test_assert(unit_test.row_labels[0].text == "A", "Labels: first row label is A (letters)");
test_assert(unit_test.row_labels[1].text == "B", "Labels: second row label is B");
test_assert(unit_test.row_labels[25].text == "Z", "Labels: row 25 is Z");
test_assert(unit_test.row_labels[26].text == "AA", "Labels: row 26 is AA");

test_assert(unit_test.column_labels[0].text == "0", "Labels: first column label is 0 (numbers)");
test_assert(unit_test.column_labels[15].text == "15", "Labels: last column label is 15");

unit_test.shift_y(2);
unit_test.shift_x(3);

test_assert(unit_test.row_labels[0].text == "C", "Labels: shift_y(2) moves first row label to C");
test_assert(unit_test.column_labels[0].text == "3", "Labels: shift_x(3) moves first column label to 3");

unit_test.update_row(10);
unit_test.update_column(5);

test_assert(array_length(unit_test.row_labels) == 10, "Labels: update_row(10) rebuilds row labels");
test_assert(array_length(unit_test.column_labels) == 5, "Labels: update_column(5) rebuilds column labels");

unit_test.destroy();

test_assert(is_undefined(unit_test.row_labels) && is_undefined(unit_test.column_labels), "Labels: wiped by destroy()");


// =========================================================================
// 21. ATOMIC REBUILD AND ROLLBACK (a failure must not leave the grid half-updated)
// =========================================================================

// set_grid() builds labels BEFORE opening a vertex buffer, so a label failure keeps the old buffer and labels.

unit_test = new obj_grid_controller.grid(32, 32, 64, 64, 4, 6, true, true, c_white, c_white, c_red);

var _vbuff_before = unit_test.vbuff;

unit_test.x_shift = -5; // Deliberately invalid: convert_letters() throws part-way through the rebuild.

test_expect_throw(function()
{
	unit_test.set_grid();
}, "set_grid: throws when a label cannot be built");

test_assert(unit_test.vbuff == _vbuff_before, "set_grid: failed rebuild keeps the previous vertex buffer");
test_assert(array_length(unit_test.row_labels) == 4, "set_grid: failed rebuild keeps the previous row labels");
test_assert(array_length(unit_test.column_labels) == 6, "set_grid: failed rebuild keeps the previous column labels");
test_assert(array_length(unit_test.cell_data) == 4, "set_grid: failed rebuild keeps the previous cell data");

unit_test.x_shift = 0;

test_expect_no_throw(function()
{
	unit_test.set_grid();
}, "set_grid: succeeds again once the state is valid");

test_assert(unit_test.vbuff != _vbuff_before, "set_grid: successful rebuild swaps in a new vertex buffer");

unit_test.destroy();

// commit_state() restores the previous layout when the rebuild throws.

unit_test = new obj_grid_controller.grid(32, 32, 64, 64, 12, 16, false, false, c_white, c_white, c_red);

var _vbuff_commit	= unit_test.vbuff;

unit_test.x_offset = "bad"; // Deliberately corrupt state so set_grid() throws on arithmetic.

test_expect_throw(function()
{
	unit_test.update_row(8);
}, "update_row: throws when the rebuild fails");

test_assert(unit_test.row_qty == 12, "update_row: row_qty rolled back after a failed rebuild");
test_assert(unit_test.vbuff == _vbuff_commit, "update_row: vertex buffer untouched after a failed rebuild");
test_assert(array_length(unit_test.cell_data) == 12, "update_row: cell_data untouched after a failed rebuild");

test_expect_throw(function()
{
	unit_test.update_column(4);
}, "update_column: throws when the rebuild fails");

test_assert(unit_test.column_qty == 16, "update_column: column_qty rolled back after a failed rebuild");

test_expect_throw(function()
{
	unit_test.zoom(false);
}, "zoom: throws when the rebuild fails");

test_assert(unit_test.row_qty == 12 && unit_test.column_qty == 16 && unit_test.x_scale == 1 && unit_test.y_scale == 1, "zoom: quantities and scales rolled back after a failed rebuild");

unit_test.x_offset = 32; // Repair the state; the grid must work again.

test_expect_no_throw(function()
{
	unit_test.update_row(8);
}, "update_row: works again after the state is repaired");

test_assert(unit_test.row_qty == 8 && array_length(unit_test.cell_data) == 8, "update_row: row_qty and cell_data updated together");

unit_test.destroy();


// =========================================================================
// 22. global.grid_list INTEGRITY
// =========================================================================

var _list_before = array_length(global.grid_list);

test_expect_throw(function()
{
	new obj_grid_controller.grid(NaN, 32, 64, 64, 12, 16);
}, "grid_list: failed construction");

test_assert(array_length(global.grid_list) == _list_before, "grid_list: a failed construction does not register an instance");

var _list_grid = new obj_grid_controller.grid(32, 32, 64, 64, 12, 16);
test_assert(array_length(global.grid_list) == _list_before + 1, "grid_list: a successful construction registers exactly one instance");

_list_grid.destroy();
test_assert(array_length(global.grid_list) == _list_before, "grid_list: destroy() removes the instance again");

// Feather enable GM1029
// Feather enable GM1041
// Feather enable GM1044

// =========================================================================
// SUMMARY
// =========================================================================

show_debug_message("==============================================");
show_debug_message("UNIT TESTS COMPLETE: " + string(global.test_pass) + " passed, " + string(global.test_fail) + " failed.");
show_debug_message("==============================================");

// If execution reaches this point, all unit tests passed successfully

if global.test_fail > 0 then game_end(1);
game_end(0);