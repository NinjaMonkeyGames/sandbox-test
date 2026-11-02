// INITIALISE PROJECT

global.debug_enabled = environment_get_variable("CI") != "";

window_set_caption("Grid Utility Professional v" + GM_version);							// Set window caption text.
global.grid_controller = instance_create_layer(0, 0, "lyr_gui", obj_grid_controller);	// Generate instance of grid controller object.

// GENERATE EXAMPLE TILEMAP (30 rows x 33 columns, indexed [row][column])

var _frames    = sprite_get_number(spr_jungle_temple);	// Number of subimages (valid indices are 0 .. _frames - 1).
var _tile_data = [];

repeat (30) // Rows.
{
	var _row_tiles = [];

	repeat (33) // Columns.
	{
		array_push(_row_tiles,
		{
			sprite	: spr_jungle_temple,
			index	: irandom(_frames - 1),	// irandom() is inclusive, so subtract 1. (round(random(30)) could return 30.)
			angle	: 0,					// Degrees, 0-359. draw() now applies this, so 0 = unrotated.
			alpha	: 1
		});
	}

	array_push(_tile_data, _row_tiles);
}

example_grid = new obj_grid_controller.grid(,,,,,,,,,,,_tile_data);	// Generate example grid instance (all other arguments use the constructor defaults).

// Generate unit test object.

if global.debug_enabled == true then global.unit_test = instance_create_layer(0, 0, "lyr_gui", obj_unit_test);