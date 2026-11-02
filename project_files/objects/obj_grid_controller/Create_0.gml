// CONSTRUCTOR CLASS FOR GENERATING A 2D GRID

/// @description Singleton guard
// FIRST thing in Create, so a duplicate controller exits before it can touch any globals below.

if (variable_global_exists("controller") && instance_exists(global.controller))
{
	show_debug_message("A singleton pattern has been implemented for this object. Please don't call me again!");
    instance_destroy();	// Cleanup instance from memory.
    exit;				// Stop the rest of Create from running
}

global.controller = id;

/// @description Generate 2D grid

global.grid_list = [];			 // Stores array of grid structs
global.grid_vformat = undefined; // Shared vertex format for all grid instances

// SOFT LIMITS

#macro  LIMIT_CELL_WIDTH_MIN 8
#macro  LIMIT_CELL_WIDTH_MAX 256
#macro  LIMIT_CELL_HEIGHT_MIN 8
#macro  LIMIT_CELL_HEIGHT_MAX 256

#macro  LIMIT_ROW_QTY_MIN 1
#macro  LIMIT_ROW_QTY_MAX 128
#macro  LIMIT_COLUMN_QTY_MIN 1
#macro  LIMIT_COLUMN_QTY_MAX 128

#macro LIMIT_ROW_SHIFT_MIN 0
#macro LIMIT_ROW_SHIFT_MAX 99
#macro LIMIT_COLUMN_SHIFT_MIN 0
#macro LIMIT_COLUMN_SHIFT_MAX 99

#macro LIMIT_X_SCALE_MIN 0.25
#macro LIMIT_Y_SCALE_MIN 0.25
#macro LIMIT_X_SCALE_MAX 2
#macro LIMIT_Y_SCALE_MAX 2

/**
 * @function grid()
 * @constructor
 * @description Generates a 2D grid based on parameters.
 * @since v0.1.0
 * @param	{Real}				[_x_offset]					Offset draw position (horizontal).
 * @param	{Real}				[_y_offset]					Offset draw position (vertical).
 * @param	{Real}				[_cell_width]				Width of an individual grid cell in pixels or units.
 * @param	{Real}				[_cell_height]				Height of an individual grid cell in pixels or units.
 * @param	{Real}				[_row_qty]					Number of rows to draw.
 * @param	{Real}				[_column_qty]				Number of columns to draw.
 * @param	{Bool}				[_label_text_type_row]		Whether row labels are rendered as letters (true) or numbers (false).
 * @param	{Bool}				[_label_text_type_column]	Whether column labels are rendered as letters (true) or numbers (false).
 * @param	{Constant.Colour}	[_grid_colour]				Colour of the grid lines.
 * @param	{Constant.Colour}	[_text_colour]				Colour of unselected label text.
 * @param	{Constant.Colour}	[_text_colour_selected]		Colour of selected label text.
 * @param	{Array}				[_tile_data]				A 2D array of structs, indexed [row][column]. Each struct needs: sprite, index, angle, alpha.
 * @returns {Struct}										A new grid struct.
 */

function grid
(
_x_offset = 32, _y_offset = 32, 
_cell_width = 256, _cell_height = 256, 
_row_qty = 4, _column_qty = 6, 
_label_text_type_row = false, _label_text_type_column = false,
_grid_colour = c_white, _text_colour = c_white, _text_colour_selected = c_red,
_tile_data = undefined
)

constructor
{
	// CALCULATION VARIABLES
	
	is_destroyed = false; // Set true by destroy() - guarded methods check this before running.
	
	x_scale = 1;
	y_scale = 1;
		
	x_shift = 0;
	y_shift = 0;
	
	row_qty = _row_qty;
	column_qty = _column_qty;
	
	label_text_grid_gap_column = 6;
	label_text_grid_gap_row = 12;

	vbuff = -1;
	cache_cursor = window_get_cursor();
	
	cell_data = [];

	// Header labels. Only the left column / top row have labels, so they are stored once per
	// row and once per column here (rebuilt by set_grid) rather than on every cell.

	row_labels = [];
	column_labels = [];

	// Vertex boundary cache (populated by set_grid), declared here for discoverability.

	grid_x1 = 0;
	grid_y1 = 0;
	grid_x2 = 0;
	grid_y2 = 0;

	/**
	 * @function is_finite_real()
	 * @description True only for real numbers that are neither NaN nor +/- infinity.
	 * is_real(NaN) is true and every NaN comparison is false, so range checks alone never reject it.
	 * @since v0.1.1.
	 * @param {Any} _value Value to test.
	 * @returns {Bool}
	 * @pure
	 */

	static is_finite_real = function(_value)
	{
		// is_infinity() only reports positive infinity, so -infinity is compared explicitly.
		return is_real(_value) && !is_nan(_value) && (_value != infinity) && (_value != -infinity);
	};

	/**
	 * @function validate_tile()
	 * @description Validates a single tile entry. Checks it is a struct with every required field BEFORE
	 * any field is read, and that the sprite is a real/handle BEFORE it reaches spt_get_asset_type_as_string.
	 * @since v0.1.1.
	 * @param {Any}  _tile   The tile entry.
	 * @param {Real} _row    Row index (for error messages).
	 * @param {Real} _column Column index (for error messages).
	 */

	static validate_tile = function(_tile, _row, _column)
	{
		var _at = " @ row " + string(_row) + " column " + string(_column);

		// Container / field existence checks.

		if !is_struct(_tile) then throw "BAD_TILE (NOT A STRUCT)" + _at;

		var _fields = ["sprite", "index", "angle", "alpha"];

		for (var _i = 0; _i < array_length(_fields); ++_i)
		{
			if !variable_struct_exists(_tile, _fields[_i]) then throw "BAD_TILE (MISSING FIELD '" + _fields[_i] + "')" + _at;
		}

		var _sprite	= _tile.sprite;
		var _index	= _tile.index;
		var _angle	= _tile.angle;
		var _alpha	= _tile.alpha;

		// Datatype checks.

		// Guard BEFORE calling the external helper, so a string/struct/undefined can't crash inside it.
		// (is_handle covers runtimes where asset references are a distinct "ref" type.)

		if !(is_real(_sprite) || is_handle(_sprite))		then throw "BAD SPRITE (NOT AN ASSET)" + _at;
		if !sprite_exists(_sprite)							then throw "BAD SPRITE (DOES NOT EXIST)" + _at;
		if spt_get_asset_type_as_string(_sprite) != "sprite" then throw "BAD SPRITE" + _at;

		if !is_finite_real(_index)							then throw "BAD_INDEX" + _at;
		if !is_finite_real(_angle)							then throw "BAD_ANGLE" + _at;
		if !is_finite_real(_alpha)							then throw "BAD_ALPHA" + _at;

		// Whole number checks.

		if frac(_index) != 0								then throw "TILE INDEX MUST BE A WHOLE NUMBER" + _at;
		if frac(_angle) != 0								then throw "TILE ANGLE MUST BE A WHOLE NUMBER" + _at;

		// Range checks. Index is zero-based, so it must be strictly LESS than the subimage count.

		var _subimages = sprite_get_number(_sprite);

		if _index < 0 || _index >= _subimages	then throw "BAD_INDEX" + _at + " (index=" + string(_index) + ", valid range 0.." + string(_subimages - 1) + ", sprite=" + sprite_get_name(_sprite) + ")";
		if _angle < 0 || _angle > 359			then throw "BAD_ANGLE" + _at + " (angle=" + string(_angle) + ", valid range 0..359)";
		if _alpha < 0 || _alpha > 1				then throw "BAD_ALPHA" + _at + " (alpha=" + string(_alpha) + ", valid range 0..1)";
	};

	/**
	 * @function validate_input()
	 * @description Validates arguments and throws on the first invalid one.
	 * @since v0.1.0.
	 * @param {Real}	[_x_offset]					Horizontal starting position (origin, top-left) of the grid.
	 * @param {Real}	[_y_offset]					Vertical starting position (origin, top-left) of the grid.
	 * @param {Real}	[_cell_width]				Width of an individual grid cell in pixels or units.
	 * @param {Real}	[_cell_height]				Height of an individual grid cell in pixels or units.
	 * @param {Real}	[_row_qty]					Number of rows.
	 * @param {Real}	[_column_qty]				Number of columns.
	 * @param {Bool}	[_label_text_type_row]		If row labels are rendered as letters (true) or numbers (false).
	 * @param {Bool}	[_label_text_type_column]	If column labels are rendered as letters (true) or numbers (false).
	 * @param {Real}	[_grid_colour]				Colour of the grid lines.
	 * @param {Real}	[_text_colour]				Default label text colour.
	 * @param {real}	[_text_colour_selected]		Label text colour when the row/column is under the cursor.
	 * @param {Array}	[_tile_data]				A 2D array of structs, indexed [row][column]. (sprite, index, angle, alpha).
	 */

	static validate_input = function
	(
	_x_offset, _y_offset, 
	_cell_width, _cell_height, 
	_row_qty, _column_qty, 
	_label_text_type_row, _label_text_type_column,
	_grid_colour, _text_colour, _text_colour_selected,
	_tile_data
	)
	{ 
		// CELL DATA CHECKS
		
		// Data type checks (finite reals only - NaN and +/- infinity are rejected).
		
		if !is_finite_real(_x_offset)				then throw"X_OFFSET MUST BE A FINITE NUMBER";
		if !is_finite_real(_y_offset)				then throw"Y_OFFSET MUST BE A FINITE NUMBER";
		
		if !is_finite_real(_cell_width)				then throw"CELL_WIDTH MUST BE A FINITE NUMBER";
		if !is_finite_real(_cell_height)			then throw"CELL_HEIGHT MUST BE A FINITE NUMBER";
		
		if !is_finite_real(_row_qty)				then throw"ROW_QTY MUST BE A FINITE NUMBER";
		if !is_finite_real(_column_qty)				then throw"COLUMN_QTY MUST BE A FINITE NUMBER";
		
		if !is_bool(_label_text_type_row)			then throw"LABEL TEXT TYPE ROW MUST BE A BOOLEAN";
		if !is_bool(_label_text_type_column)		then throw"LABEL TEXT TYPE COLUMN MUST BE A BOOLEAN";
		
		if !is_finite_real(_grid_colour)			then throw"GRID COLOUR MUST BE A COLOUR";
		if !is_finite_real(_text_colour)			then throw"TEXT COLOUR MUST BE A COLOUR";
		if !is_finite_real(_text_colour_selected)	then throw"TEXT COLOUR SELECTED MUST BE A COLOUR";
		
		// Whole number checks
		
		if frac(_cell_width)	!= 0				then throw"_CELL_WIDTH MUST BE A WHOLE NUMBER";
		if frac(_cell_height)	!= 0				then throw"_CELL_HEIGHT MUST BE A WHOLE NUMBER";
		
		if frac(_row_qty)		!= 0				then throw"_ROW_QTY MUST BE A WHOLE NUMBER";
		if frac(_column_qty)	!= 0				then throw"_COLUMN_QTY MUST BE A WHOLE NUMBER";
		
		if frac(_grid_colour)			!= 0		then throw"_GRID_COLOUR MUST BE A WHOLE NUMBER";
		if frac(_text_colour)			!= 0		then throw"_TEXT_COLOUR MUST BE A WHOLE NUMBER";
		if frac(_text_colour_selected)	!= 0		then throw"_TEXT_COLOUR_SELECTED MUST BE A WHOLE NUMBER";
		
		// Range checks
		
		if _cell_width				< LIMIT_CELL_WIDTH_MIN		||	_cell_width				>  LIMIT_CELL_WIDTH_MAX		then throw"_CELL_WIDTH";
		if _cell_height				< LIMIT_CELL_HEIGHT_MIN		||	 _cell_height			>  LIMIT_CELL_HEIGHT_MAX	then throw"_CELL_HEIGHT";
		
		if _row_qty					< LIMIT_ROW_QTY_MIN			||	_row_qty				>  LIMIT_ROW_QTY_MAX		then throw"_ROW_QTY";
		if _column_qty				< LIMIT_COLUMN_QTY_MIN		||	_column_qty				>  LIMIT_COLUMN_QTY_MAX		then throw"_COLUMN_QTY";
		
		if _grid_colour				< 0							||	_grid_colour			> 16777215					then throw"_GRID_COLOUR";
		if _text_colour				< 0							||	_text_colour			> 16777215					then throw"_TEXT_COLOUR";
		if _text_colour_selected	< 0							||	_text_colour_selected	> 16777215					then throw"_TEXT_COLOUR_SELECTED";
		
		// TILE DATA CHECKS
		
		if _tile_data != undefined
		{
			// Check the container is an array BEFORE indexing into it below.

			if !is_array(_tile_data) then throw"_TILE_DATA MUST BE AN ARRAY";

			// _tile_data is indexed [row][column], matching cell_data and draw().

			var _tile_data_row_qty = array_length(_tile_data);

			// Guard against an empty top-level array before indexing _tile_data[0] anywhere.

			if _tile_data_row_qty == 0 then throw"_TILE_DATA MUST NOT BE EMPTY";

			// The supplied grid must not be larger than the tile data backing it.

			if _row_qty > _tile_data_row_qty			then throw"BAD_GRID_SIZE, GRID MUST NOT HAVE MORE ROWS THAN TILE DATA ARRAY";
		
			/*
			// EVERY row and EVERY tile is validated, not just the top-left grid-sized region.
			// shift_x/shift_y/zoom(false) all let draw() read tiles outside the initial
			// row_qty x column_qty area, so anything unvalidated there would crash at draw time.
			// Column count is read per row since rows are not guaranteed to be the same length.
			*/

			for (var _row = 0; _row < _tile_data_row_qty; ++_row) 
			{
				if !is_array(_tile_data[_row]) then throw string("BAD_TILE_DATA_ROW @ row " + string(_row) + " (not an array)");

				var _tile_data_column_qty = array_length(_tile_data[_row]);

				if _tile_data_column_qty == 0 then throw string("BAD_TILE_DATA_ROW @ row " + string(_row) + " (empty)");

				// Rows the initial grid actually covers must be wide enough for it.

				if _row < _row_qty && _column_qty > _tile_data_column_qty then throw string("BAD_GRID_SIZE, ROW " + string(_row) + " HAS FEWER COLUMNS THAN GRID REQUIRES");

				for (var _column = 0; _column < _tile_data_column_qty; ++_column)
				{
					validate_tile(_tile_data[_row][_column], _row, _column);
				}
			}
		}
	};
	
	// Validate raw arguments BEFORE anything (including clamp()) touches them.
	
	validate_input(_x_offset, _y_offset, _cell_width, _cell_height, _row_qty, _column_qty, _label_text_type_row, _label_text_type_column, _grid_colour, _text_colour, _text_colour_selected, _tile_data);

	// IMPORTED VARIABLES
	
	x_offset				= 	_x_offset;
	y_offset				= 	_y_offset;
	
	cell_width				= 	_cell_width;
	cell_height				= 	_cell_height;
	
	row_qty					= 	_row_qty;
	column_qty				= 	_column_qty;
	
	label_text_type_row		= 	_label_text_type_row;
	label_text_type_column	= 	_label_text_type_column;
	
	grid_colour				= 	_grid_colour;
	text_colour				= 	_text_colour;
	text_colour_selected	= 	_text_colour_selected;
	
	tile_data				= 	_tile_data;
		
	// Build the shared vertex format once, the first time any grid is created.
	
	if (is_undefined(global.grid_vformat))
	{
		vertex_format_begin();
		vertex_format_add_position();
		vertex_format_add_colour();
		
		global.grid_vformat = vertex_format_end();
	};

	/**
	 * @function guard_alive()
	 * @description Throws if this instance has already been destroyed. Single source of truth for the
	 * use-after-destroy check - call at the top of any method that reads cell_data/vbuff or mutates grid state.
	 * @since v0.1.0.
	 */

	static guard_alive = function()
	{
		if (is_destroyed) then throw"GRID INSTANCE HAS BEEN DESTROYED";
	};

	/**
	 * @function clamp_shifts()
	 * @description Single place that re-clamps x_shift/y_shift against the current column_qty/row_qty.
	 * max() guards against the quantity exceeding (1 + LIMIT_*_SHIFT_MAX), which would otherwise
	 * invert clamp()'s min/max and leave the shift negative (negative labels / negative array indices).
	 * @since v0.1.1.
	 */

	static clamp_shifts = function()
	{
		x_shift = clamp(x_shift, LIMIT_COLUMN_SHIFT_MIN, max(LIMIT_COLUMN_SHIFT_MIN, 1 + LIMIT_COLUMN_SHIFT_MAX - column_qty));
		y_shift = clamp(y_shift, LIMIT_ROW_SHIFT_MIN,	 max(LIMIT_ROW_SHIFT_MIN,	 1 + LIMIT_ROW_SHIFT_MAX	- row_qty));
	};

	/**
	 * @function snapshot_state()
	 * @description Captures the mutable layout state so a failed rebuild can be rolled back.
	 * @since v0.1.1.
	 * @returns {Struct}
	 */

	static snapshot_state = function()
	{
		return
		{
			row_qty		: row_qty,
			column_qty	: column_qty,
			x_scale		: x_scale,
			y_scale		: y_scale,
			x_shift		: x_shift,
			y_shift		: y_shift,
		};
	};

	/**
	 * @function commit_state()
	 * @description Re-clamps the shifts and rebuilds the grid. If the rebuild throws, the previous
	 * state is restored (set_grid() is itself atomic, so the old buffer/cell_data are still valid)
	 * and the error is rethrown. The grid is therefore never left half-updated.
	 * @since v0.1.1.
	 * @param {Struct} _snapshot Result of snapshot_state() taken before the mutation.
	 */

	static commit_state = function(_snapshot)
	{
		try
		{
			clamp_shifts();
			set_grid();
		}
		catch (_error)
		{
			row_qty		= _snapshot.row_qty;
			column_qty	= _snapshot.column_qty;
			x_scale		= _snapshot.x_scale;
			y_scale		= _snapshot.y_scale;
			x_shift		= _snapshot.x_shift;
			y_shift		= _snapshot.y_shift;

			throw _error;
		}
	};
    
	/**
	 * @function set_grid()
	 * @description Rebuilds the grid's vertex buffer and cell data from the current parameters.
	 * ATOMIC: everything that can throw (labels) is computed BEFORE any buffer is opened, and the new
	 * buffer/cell_data/bounds are only swapped in once everything succeeded.
	 * @since v0.1.0.
	 */

	static set_grid = function()
	{
		guard_alive();

		// Calculate vertex boundaries into locals (assigned only on success).
		
		var _gx1 = x_offset;
		var _gy1 = y_offset;
		var _gx2 = x_offset + (column_qty	* cell_width	* x_scale);
		var _gy2 = y_offset + (row_qty		* cell_height	* y_scale);

		// Build labels and cell geometry FIRST (convert_letters() can throw here, before any buffer is opened).
		// Labels exist only on the left column / top row, so they are built once per row and once
		// per column instead of being stored on (and drawn for) every cell.

		var _new_row_labels		= [];
		var _new_column_labels	= [];

		for (var _row = 0; _row < row_qty; ++_row)
		{
			var _row_string = label_text_type_row ? convert_letters(_row + y_shift) : string(_row + y_shift);
			var _row_y1		= y_offset + (_row * cell_height * y_scale);

			array_push(_new_row_labels,
			{
				text	: _row_string,
				x		: (x_offset - string_width(_row_string)) - label_text_grid_gap_row,
				y		: _row_y1 + (cell_height * y_scale) / 2 - string_height(_row_string) / 2,
				colour	: text_colour,
				alpha	: 1,
			});
		}

		for (var _column = 0; _column < column_qty; ++_column)
		{
			var _column_string	= label_text_type_column ? convert_letters(_column + x_shift) : string(_column + x_shift);
			var _column_x1		= x_offset + (_column * cell_width * x_scale);

			array_push(_new_column_labels,
			{
				text	: _column_string,
				x		: _column_x1 + (cell_width * x_scale) / 2 - string_width(_column_string) / 2,
				y		: (y_offset - string_height(_column_string)) - label_text_grid_gap_column,
				colour	: text_colour,
				alpha	: 1,
			});
		}

		var _new_cell_data = [];

		for (var _row = 0; _row < row_qty; ++_row)
		{
			var _row_cells = [];

			for (var _column = 0; _column < column_qty; ++_column)
			{
				var _x1 = x_offset + (_column	* cell_width	* x_scale);
				var _y1 = y_offset + (_row		* cell_height	* y_scale);

				array_push(_row_cells,
				{
					x1 : _x1,
					y1 : _y1,
					x2 : _x1 + (cell_width	* x_scale),
					y2 : _y1 + (cell_height	* y_scale),
					outline : true,
				});
			}

			array_push(_new_cell_data, _row_cells);
		}

		// Nothing below can throw. Build the new buffer.

		var _new_vbuff = vertex_create_buffer();
		vertex_begin(_new_vbuff, global.grid_vformat);

		// Horizontal lines.

		for (var _row = 0; _row <= row_qty; ++_row)
		{
			var _y = y_offset + (_row * cell_height * y_scale);

			vertex_position(_new_vbuff, _gx1, _y); vertex_colour(_new_vbuff, grid_colour, 1);
			vertex_position(_new_vbuff, _gx2, _y); vertex_colour(_new_vbuff, grid_colour, 1);
		};

		// Vertical lines.

		for (var _column = 0; _column <= column_qty; ++_column)
		{
			var _x = x_offset + (_column * cell_width * x_scale);

			vertex_position(_new_vbuff, _x, _gy1); vertex_colour(_new_vbuff, grid_colour, 1);
			vertex_position(_new_vbuff, _x, _gy2); vertex_colour(_new_vbuff, grid_colour, 1);
		};

		vertex_end(_new_vbuff);
		vertex_freeze(_new_vbuff); // Static geometry until the next set_grid() call, so freezing is safe and gives a GPU-side speed boost.

		// Swap in the new state, freeing the previous buffer (otherwise each call leaks a buffer).

		if (vbuff != -1) { vertex_delete_buffer(vbuff); };

		vbuff		= _new_vbuff;
		cell_data	= _new_cell_data;
		row_labels	= _new_row_labels;
		column_labels	= _new_column_labels;
		grid_x1		= _gx1;
		grid_y1		= _gy1;
		grid_x2		= _gx2;
		grid_y2		= _gy2;
	}
	
	// NOTE: set_grid() is called at the bottom of the constructor, after every static method
	// it depends on (e.g. convert_letters) has been defined.
	
	/**
	 * @function get_x()
	 * @description Gets the column index under the given X coordinate.
	 * @since v0.1.0.
	 * @param {Real} [_x] X coordinate to check (mouse pointer by default).
	 * @returns {Real} Column index, clamped to a valid range.
	 * @self {struct.grid}
	 */

	static get_x = function(_x = mouse_x) 
	{
		guard_alive();

		if !is_finite_real(_x) then throw"_X MUST BE A FINITE NUMBER";

		return clamp(floor((_x - x_offset) / (cell_width * x_scale)), 0, floor(column_qty) - 1);
	}
	
	/**
	 * @function get_y()
	 * @description Gets the row index under the given Y coordinate.
	 * @since v0.1.0.
	 * @param {Real} [_y] Y coordinate to check (mouse pointer by default).
	 * @returns {Real} Row index, clamped to a valid range.
	 * @self {struct.grid}
	 */
	
	static get_y = function(_y = mouse_y) 
	{
		guard_alive();

		if !is_finite_real(_y) then throw"_Y MUST BE A FINITE NUMBER";

		return clamp(floor((_y - y_offset) / (cell_height * y_scale)), 0, floor(row_qty) - 1);
	}
	
	/**
	 * @function shift_x()
	 * @description Shifts columns. (Negative values shift left.)
	 * @since v0.1.0.
	 * @param {Real} _value Amount to add to the current column shift.
	 * @self {struct.grid}
	 */

	static shift_x = function(_value) 
	{
		guard_alive();

		if !is_finite_real(_value)	then throw"_VALUE MUST BE A FINITE NUMBER";
		if frac(_value) != 0		then throw"_VALUE MUST BE A WHOLE NUMBER";

		var _snapshot = snapshot_state();

		x_shift += _value; // commit_state() clamps this (with the max() guard) via clamp_shifts().

		commit_state(_snapshot);
	}
	
	/**
	 * @function shift_y()
	 * @description Shifts rows. (Negative values shift up.)
	 * @since v0.1.0.
	 * @param {Real} _value Amount to add to the current row shift.
	 * @self {struct.grid}
	 */
	
	static shift_y = function(_value) 
	{
		guard_alive();

		if !is_finite_real(_value)	then throw"_VALUE MUST BE A FINITE NUMBER";
		if frac(_value) != 0		then throw"_VALUE MUST BE A WHOLE NUMBER";

		var _snapshot = snapshot_state();

		y_shift += _value;

		commit_state(_snapshot);
	}
	
	/**
	 * @function set_coords()
	 * @description Highlights the row/column labels under the current mouse position.
	 * Nothing is highlighted while the mouse is outside the grid (get_x/get_y clamp to the edge,
	 * so without this check the edge row/column would light up from anywhere on screen).
	 * @since v0.1.0.
	 */

	static set_coords = function() 
	{
		guard_alive();

		var _inside = point_in_rectangle(mouse_x, mouse_y, grid_x1, grid_y1, grid_x2, grid_y2);

		var _select_x = _inside ? get_x() : -1;
		var _select_y = _inside ? get_y() : -1;

		for (var _row = 0; _row < row_qty; ++_row)
		{
			row_labels[_row].colour = (_row == _select_y) ? text_colour_selected : text_colour;
		}

		for (var _column = 0; _column < column_qty; ++_column)
		{
			column_labels[_column].colour = (_column == _select_x) ? text_colour_selected : text_colour;
		}
	}
	
	/**
	 * @function update_row()
	 * @description Changes the number of rows.
	 * @since v0.1.0.
	 * @param {Real} _value Number of rows in the new grid.
	 */

	static update_row = function(_value)
	{
		guard_alive();

		if !is_finite_real(_value)	then throw"_VALUE MUST BE A FINITE NUMBER";
		if frac(_value) != 0		then throw"_VALUE MUST BE A WHOLE NUMBER";

		var _snapshot = snapshot_state();

		row_qty = clamp(_value, LIMIT_ROW_QTY_MIN, LIMIT_ROW_QTY_MAX);

		commit_state(_snapshot);
	}
	
	/**
	 * @function update_column()
	 * @description Changes the number of columns.
	 * @since v0.1.0.
	 * @param {Real} _value Number of columns in the new grid.
	 */

	static update_column = function(_value)
	{
		guard_alive();

		if !is_finite_real(_value)	then throw"_VALUE MUST BE A FINITE NUMBER";
		if frac(_value) != 0		then throw"_VALUE MUST BE A WHOLE NUMBER";

		var _snapshot = snapshot_state();

		column_qty = clamp(_value, LIMIT_COLUMN_QTY_MIN, LIMIT_COLUMN_QTY_MAX);
	
		commit_state(_snapshot);
	}

	/**
	 * @function zoom()
	 * @description Zooms in/out while preserving the grid's total on-screen size.
	 * @since v0.1.0.
	 * @param {Bool} [_zoom_direction] True to zoom in, false to zoom out.
	 * @self {struct.grid}
	 */

	static zoom = function(_zoom_direction = true)
	{
		guard_alive();

		var _snapshot = snapshot_state();

		if is_bool(_zoom_direction) // Sanitise input to prevent an error.
		{
			if _zoom_direction == false
			{
				// Zooming out: halve the scale, double the row/column quantities.
				
				var _new_x_scale	= x_scale			/ 2;
				var _new_y_scale	= y_scale			/ 2;
				var _new_col		= column_qty		* 2;
				var _new_row		= row_qty			* 2;
            
				// Check if the new state respects the absolute limits.
				
				if (_new_x_scale >= LIMIT_X_SCALE_MIN && _new_y_scale >= LIMIT_Y_SCALE_MIN &&
				    _new_col <= LIMIT_COLUMN_QTY_MAX && _new_row <= LIMIT_ROW_QTY_MAX)
				{
				    x_scale		= _new_x_scale;
				    y_scale		= _new_y_scale;
				    column_qty	= _new_col;
				    row_qty		= _new_row;
				}
			}
				else
			{
				// Zooming in: double the scale, halve the row/column quantities.
				
				var _new_x_scale	= x_scale			* 2;
				var _new_y_scale	= y_scale			* 2;
				var _new_col		= round(column_qty	/ 2);
				var _new_row		= round(row_qty		/ 2);
            
				// Check if the new state respects the absolute limits and won't hit zero cells.
				
				if (_new_x_scale <= LIMIT_X_SCALE_MAX && _new_y_scale <= LIMIT_Y_SCALE_MAX &&
				    _new_col >= LIMIT_COLUMN_QTY_MIN && _new_row >= LIMIT_ROW_QTY_MIN)
				{
				    x_scale		= _new_x_scale;
				    y_scale		= _new_y_scale;
				    column_qty	= _new_col;
				    row_qty		= _new_row;
				}
			}
		}
       
		// Re-clamp both shifts (with the max() guard) and rebuild the grid geometry.

		commit_state(_snapshot);
	}

	/**
	 * @function set_cursor()
	 * @description Sets the mouse pointer graphic depending on whether the cursor is over the grid.
	 * @since v0.1.0.
	 */

	static set_cursor = function() 
	{
		guard_alive();

		if point_in_rectangle(mouse_x, mouse_y, grid_x1, grid_y1, grid_x2, grid_y2)
		{
			// Remember whatever cursor was active immediately before we override it,
			// rather than whatever was active back at construction time - otherwise
			// this would restore a stale cursor if something else changes the global
			// cursor while this grid instance is alive.

			if window_get_cursor() != cr_handpoint then cache_cursor = window_get_cursor();

			window_set_cursor(cr_handpoint) ;
		}
			else
		{
			window_set_cursor(cache_cursor);
		}
	}

	/**
	 * @function convert_letters()
	 * @description Converts number to a letter the same way as you would see on an atlas or a spreadsheet.
	 * @since v0.1.0.
	 * @param {Real} _number The number to convert to a letter(s).
	 * @return {String} Return letter.
	 * @pure
	 */

	static convert_letters = function(_number)
	{
		if (!is_finite_real(_number)) throw"PROVIDED PARAMETER IS NOT A FINITE REAL";
		if (_number < 0) throw"PROVIDED PARAMETER MUST NOT BE NEGATIVE";

		var _val = floor(_number);
		var _num = _val;
	
		if _number > 0 then _num ++;

		var _string = "";
	
		while (_num > 0)
		{
		    _num --; 
		    _string = chr((_num mod 26) + 65) + _string;
		    _num = _num div 26;
		}

		return (_string == "" ? "A" : _string);
	}

	/**
	 * @function step()
	 * @description Executes the step logic for this grid instance (input handling and state updates).
	 * @since v0.1.0.
	 */

	static step = function() 
	{
		with self
		{
			guard_alive();

			if mouse_wheel_down()
			{
				zoom(true);
			}
		
			if mouse_wheel_up()
			{
				zoom(false);
			}
		
			if keyboard_check_pressed(vk_left)	then shift_x(-1);
			if keyboard_check_pressed(vk_right)	then shift_x(1);
			if keyboard_check_pressed(vk_up)	then shift_y(-1);
			if keyboard_check_pressed(vk_down)	then shift_y(1);
		}
		
		set_coords();
	}
	
	/**
	 * @function draw()
	 * @description Executes the draw logic for this grid instance (grid lines and labels).
	 * @since v0.1.0.
	 */

	static draw = function() 
	{
		with self
		{
			guard_alive();
		
			// Header labels: one draw call per row/column label, not per cell.

			for (var _i = 0; _i < row_qty; ++_i)
			{
				var _row_label = row_labels[_i];
				draw_text_colour(_row_label.x, _row_label.y, _row_label.text, _row_label.colour, _row_label.colour, _row_label.colour, _row_label.colour, _row_label.alpha);
			}

			for (var _i = 0; _i < column_qty; ++_i)
			{
				var _column_label = column_labels[_i];
				draw_text_colour(_column_label.x, _column_label.y, _column_label.text, _column_label.colour, _column_label.colour, _column_label.colour, _column_label.colour, _column_label.alpha);
			}

			// Tiles (only if tile data was supplied). Every tile was validated at construction, so reads are safe.

			if tile_data != undefined
			{
				var _tile_data_row_qty = array_length(tile_data);

				for (var _row = 0; _row < row_qty; ++_row)
				{
					var _tile_row = _row + y_shift;

					if _tile_row < 0 || _tile_row >= _tile_data_row_qty then continue; // Out of tile data range.

					// Column count is read per-row since tile_data rows are not guaranteed to be the same length.

					var _tile_data_column_qty = array_length(tile_data[_tile_row]);

					for (var _column = 0; _column < column_qty; ++_column)
					{
						var _tile_column = _column + x_shift;

						if _tile_column < 0 || _tile_column >= _tile_data_column_qty then continue;

						var _cell = cell_data[_row][_column];
						var _tile = tile_data[_tile_row][_tile_column];

						draw_sprite_ext(_tile.sprite, _tile.index, _cell.x1, _cell.y1, x_scale, y_scale, _tile.angle, c_white, _tile.alpha);
					}
				}
			}
		
			vertex_submit(vbuff, pr_linelist, -1); // Effectively draw grid.
		}
	}
	
	/**
	 * @function destroy()
	 * @description Removes this instance from the global grid list, frees GPU resources, restores the cursor, and wipes all instance data.
	 * @since v0.1.0.
	 * @self {struct.grid}
	 */

	static destroy = function() 
	{
		if (is_destroyed) then return; // Already destroyed - safe no-op.

		// Find the current instance's index in the global array.
		
		var _index = array_get_index(global.grid_list, self);
    
		// Only remove if it actually exists in the array.
		
		if (_index != -1) { array_delete(global.grid_list, _index, 1); };

		// Free the vertex buffer - otherwise this leaks GPU memory every time a grid is destroyed.
		
		if (vbuff != -1)
		{
			vertex_delete_buffer(vbuff);
			vbuff = -1;
		}

		// If we're being destroyed while hovered, don't leave the hand cursor stuck on screen.

		if (window_get_cursor() == cr_handpoint) then window_set_cursor(cache_cursor);

		is_destroyed = true; // Set before the generic wipe below, since the wipe would otherwise erase it too.
			
		var _names = variable_struct_get_names(self);

		for (var _i = 0; _i < array_length(_names); ++_i)
		{
			var _name = _names[_i];

			if (_name == "is_destroyed")						continue;
			if (is_method(variable_struct_get(self, _name)))	continue;

			variable_struct_set(self, _name, undefined);
		}
	}
	
	set_grid();
	
	array_push(global.grid_list, self); // Add this instance to the global grid list.
}