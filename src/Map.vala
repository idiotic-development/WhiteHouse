using Gtk;
using Gdk;
using Cairo;

public class WhiteHouse.Map : DrawingArea
{
	public signal void selection_changed ();

	public static int DEFAULT_GRID_SIZE = 30; // In pixels
	public static int GRID_SIZE = DEFAULT_GRID_SIZE;
	public static double FLOOR_OFFSET_X = 0.2; // In map coords
	public static double FLOOR_OFFSET_Y = 0.3;

	bool _show_grid = true;
	public bool show_grid
	{
		get { return _show_grid; }
		set
		{
			_show_grid = value;
			queue_draw ();
		}
	}

	double _width;
	public double width
	{
		get
		{
			return _width;
		}

		set
		{
			_width = value;
			queue_resize ();
		}
	}

	double _height;
	public double height
	{
		get
		{
			return _height;
		}

		set
		{
			_height = value;
			queue_resize ();
		}
	}

	public double x
	{
		get {return (int)width/2;}
	}

	public double y
	{
		get {return (int)height/2;}
	}

	/*
	 *	This Drawable will receive all mouse move events regardless of position.
	 *  Should be used to implement dragging so as to overcome fast mouse movement.
	 */
	public Drawable drag_target { get; set; }

	int _z_level = 0;
	public int z_level
	{ 
		get { return _z_level; }
		set
		{
			_z_level = value;
			queue_draw ();
		}
	}

	public void clear_selection ()
	{
		foreach (var selection in get_selection ())
			selection.selected = false;

		selection_changed ();
	}

	public Room[] get_selection ()
	{
		Gee.List<Room> list = new Gee.ArrayList<Room>();

		foreach (var drawable in drawable_list)
			if (drawable is Room && (drawable as Room).selected)
				list.add (drawable as Room);

		return list.to_array ();
	}

	public void set_selection (Room room)
	{
		clear_selection ();
		add_selection (room);
	}

	public void add_selection (Room room)
	{
		room.selected = true;

		selection_changed ();
	}

	/*
	 *	List of all Drawables to be managed.
	 */
	public Gee.List<Drawable> drawable_list = new Gee.ArrayList<Drawable> ();

	public Map ()
	{
		expand = true;

		selection_changed ();

		// Respond to click and mouse move events
		add_events (EventMask.POINTER_MOTION_MASK|EventMask.BUTTON_PRESS_MASK|EventMask.BUTTON_RELEASE_MASK);
	}

	public Room? move_selection (string direction)
	{
		var room = room_dialog (null);
		if (room == null)
			return null;

		var selected = get_selection ()[0];
		selected.selected = false;

		connect_rooms (selected, room, direction);

		room.selected = true;
	
		return room;
	}

	public Passage connect_rooms (Room start, Room end, string direction)
	{
		var passage = new_passage (start, end);
		switch (direction)
		{
			case "north":
				end.x = start.x;
				end.y = start.y - end.height - 2;
				end.south = passage;
				start.north = passage;
				if (overlaps (end))
					shift (end.x, end.y + end.height, 0, - end.height - 2, end);
				break;
			case "northeast":
				end.x = start.x + start.width + 2;
				end.y = start.y - end.height - 2;
				end.southwest = passage;
				start.northeast = passage;
				if (overlaps (end))
					shift (end.x, end.y + end.height, end.width + 2, - end.height - 2, end);
				break;
			case "east":
				end.x = start.x + start.width + 2;
				end.y = start.y;
				end.west = passage;
				start.east = passage;
				if (overlaps (end))
					shift (end.x, end.y, end.width + 2, 0, end);
				break;
			case "southeast":
				end.x = start.x + start.width + 2;
				end.y = start.y + start.height + 2;
				end.northwest = passage;
				start.southeast = passage;
				if (overlaps (end))
					shift (end.x, end.y, end.width + 2, end.height + 2, end);
				break;
			case "south":
				end.x = start.x;
				end.y = start.y + start.height + 2;
				end.north = passage;
				start.south = passage;
				if (overlaps (end))
					shift (end.x, end.y, 0, end.height + 2, end);
				break;
			case "southwest":
				end.x = start.x - end.width - 2;
				end.y = start.y + start.height + 2;
				end.northeast = passage;
				start.southwest = passage;
				if (overlaps (end))
					shift (end.x, end.y + end.width, - end.width - 2, end.height + 2, end);
				break;
			case "west":
				end.x = start.x - end.width - 2;
				end.y = start.y;
				end.east = passage;
				start.west = passage;
				if (overlaps (end))
					shift (end.x + end.width, end.y, - end.width - 2, 0, end);
				break;
			case "northwest":
				end.x = start.x - end.width - 2;
				end.y = start.y - end.height - 2;
				end.southeast = passage;
				start.northwest = passage;
				if (overlaps (end))
					shift (end.x + end.width, end.y + end.height, - end.width - 2, 0, end);
				break;
			case "down":
				z_level -= 1;
				end.z = z_level;
				end.x = start.x;
				end.y = start.y;
				end.up = passage;
				start.down = passage;
				if (overlaps (end))
					shift (end.x, end.y, - end.height - 2, 0, end);
				break;
			case "up":
				z_level += 1;
				end.z = z_level;
				end.x = start.x;
				end.y = start.y;
				end.down = passage;
				start.up = passage;
				if (overlaps (end))
					shift (end.x, end.y, - end.height - 2, 0, end);
				break;
		}

		return passage;
	}

	public void shift (double x_origin, double y_origin, double x_shift, double y_shift, Room exclude)
	{
		foreach (var drawable in drawable_list)
		{

			if (!(drawable is Room) || drawable == exclude || drawable.z != z_level)
				continue;

			var r_drawable = drawable as Room;

			if ((x_shift > 0 && r_drawable.x >= x_origin) ||
				(x_shift < 0 && r_drawable.x <= x_origin))
				r_drawable.x += x_shift;

			if ((y_shift > 0 && r_drawable.y >= y_origin) ||
				(y_shift < 0 && r_drawable.y <= y_origin))
				r_drawable.y += y_shift;
		}
	}

	public void place (Room room)
	{
		var @break = false;
		for (var x = 0.0; !break; x = (x > 0) ? -x : -x + room.width + 2)
		{
			room.x = x;
			room.y = 0;

			@break = true;
			foreach (var drawable in drawable_list)
				if (drawable is Room && overlaps (drawable as Room))
					@break = false;
		}
	}

	public bool overlaps (Room room)
	{
		var x1 = room.x - 1;
		var x2 = room.x + room.width + 1;
		var y1 = room.y - 1;
		var y2 = room.y + room.height + 1;

		foreach (var drawable in drawable_list)
		{
			if (!(drawable is Room) || drawable == room || drawable.z != z_level)
				continue;

			var r_drawable = drawable as Room;
			var x3 = r_drawable.x;
			var x4 = r_drawable.x + r_drawable.width;
			var y3 = r_drawable.y;
			var y4 = r_drawable.y + r_drawable.height;

			if (x1 < x4 && x2 > x3 &&
				y1 < y4 && y2 > y3) 
				return true;
		}

		return false;
	}

	/*
	 *	Create new room with the given name and description (possibly none).
	 */
	public Room new_room (string name, string? desc)
	{		
		var room = new Room (this, name, desc);
		drawable_list.add (room);

		return room;
	}

	public Passage new_passage (Room start, Room? end)
	{
		Passage passage;
		if (end == null)
			passage = new Passage (this, start);
		else
			passage = new Passage.with_end (this, start, end);
		drawable_list.add (passage);

		return passage;
	}

	public Room? room_dialog (Room? room)
	{
		RoomDialog dialog;

		if (room == null)
			dialog = new RoomDialog (null);
		else
			dialog = new RoomDialog.with_presets (null, room.name, room.desc);

		dialog.show_all ();
		string name, desc;
		dialog.run (out name, out desc);
		if (name != null)
		{
			if (room == null)
				return new_room (name, desc);
			else
			{
				room.name = name;
				room.desc = desc;
				return room;
			}
		}

		return null;
	}

	/*
	 *	Search for a room or passage containing the point x,y.
	 */
	// Does not work well when Drawable overlap
	public Drawable get_drawable (double x, double y)
	{
		Drawable return_val = null;
		for (var i = drawable_list.size-1; i >= 0; i--)
			if (drawable_list[i].z == z_level && drawable_list[i].contains (x, y))
			{
				return_val = drawable_list[i];
				if (return_val is Room) // Rooms have precedence
					break;
			}

		return return_val;
	}

	/* Event overrides */

	public override void size_allocate (Allocation allocation)
	{
		if (allocation.width > width*GRID_SIZE)
			width = (double)allocation.width/GRID_SIZE;

		if (allocation.height > height*GRID_SIZE)
			height = (double)allocation.height/GRID_SIZE;

		base.size_allocate (allocation);
	}

	/*
	 *	Draw the grid, then delegate to each drawable.
	 */
	static int num = 0;
	public override bool draw (Context ctx)
	{
		var color = Gdk.RGBA ();
		color.parse (SETTINGS.get_string ("background-color"));
		ctx.set_source_rgb (color.red, color.green, color.blue);
		ctx.paint ();

		if (show_grid)
		{
			color.parse (SETTINGS.get_string ("background-grid"));
			ctx.set_source_rgb (color.red, color.green, color.blue);
			ctx.set_line_width (1);
			
			for (var x = 0; x < width; x++)
			{
				ctx.move_to (x*GRID_SIZE, 0);
				ctx.line_to (x*GRID_SIZE, height*GRID_SIZE);
				ctx.stroke ();
			}

			for (var y = 0; y < height; y++)
			{
				ctx.move_to (0, y*GRID_SIZE);
				ctx.line_to (width*GRID_SIZE, y*GRID_SIZE);
				ctx.stroke ();
			}

			// Draw a cross at center
			ctx.set_source_rgb (color.red-0.1, color.green-0.1, color.blue-0.1);

			// ctx.set_source_rgb (0.7, 0.7, 0.7); // Dark gray
			ctx.move_to ((x - 1) * GRID_SIZE, y * GRID_SIZE);
			ctx.line_to ((x + 1) * GRID_SIZE, y * GRID_SIZE);
			ctx.stroke ();
			ctx.move_to (x*GRID_SIZE, (y - 1) * GRID_SIZE);
			ctx.line_to (x*GRID_SIZE, (y + 1) * GRID_SIZE);
			ctx.stroke ();
		}

		foreach (var drawable in drawable_list)
			if (drawable.z <= z_level - 0.5 && drawable.z >= z_level - 1.5)
				drawable.draw (ctx, GRID_SIZE);

		foreach (var drawable in drawable_list)
			if (drawable.z <= z_level + 0.5 && drawable.z >= z_level - 0.5)
				drawable.draw (ctx, GRID_SIZE);

		return false;
	}

	/*
	 *	Set drawable under mouse as drag_target and pass it the event.
	 */
	public override bool button_press_event (EventButton e)
	{
		var x = e.x;
		var y = e.y;
		viewport_to_map (ref x, ref y);

		drag_target = get_drawable (x, y);
		if (drag_target != null)
			drag_target.mouse_down (x, y, (int)e.button);
		else if (e.type == EventType.2BUTTON_PRESS)
		{
			var room = room_dialog (null);
			if (room != null)
			{
				set_selection (room);
				room.x = (int)(x - room.width/2);
				room.y = (int)(y - room.height/2);
			}
		}

		queue_draw ();

		return false;
	}

	/*
	 *	Pass drawable under mouse and drag_target the event. Unset drag_target.
	 */
	public override bool button_release_event (EventButton e)
	{
		var x = e.x;
		var y = e.y;
		viewport_to_map (ref x, ref y);

		var drawable = get_drawable (x, y);
		if (drawable != null && drawable != drag_target)
			drawable.mouse_up (x, y, (int)e.button);

		if (drag_target != null)
		{
			drag_target.mouse_up (x, y, (int)e.button);

			if (drag_target is Room)
			{
				if ((e.state & ModifierType.SHIFT_MASK) == ModifierType.SHIFT_MASK)
					add_selection (drag_target as Room);
				else
					set_selection (drag_target as Room);
			}

			drag_target = null;
		} else
			clear_selection ();

		queue_draw ();

		return false;
	}

	private Drawable hover;
	public override bool motion_notify_event (EventMotion e)
	{
		var x = e.x;
		var y = e.y;
		viewport_to_map (ref x, ref y);

		var drawable = get_drawable (x, y);

		if (drag_target != null)
			drag_target.mouse_move (x, y);

		if (drawable != null)
			drawable.mouse_move (x, y);

		if (hover != drawable)
		{
			if (hover != null)
			{
				hover.mouse_leave ();
				hover = null;
			}

			if (drawable != null)
			{
				hover = drawable;
				hover.mouse_enter ();
			}
		}

		queue_draw ();

		return false;
	}

	public static void rectangle (Context ctx, uint32[] seed, double x, double y, double width, double height)
	{
		ctx.move_to (x, y);
		line_to (ctx, seed[0], x + width, y);
		line_to (ctx, seed[1], x + width, y + height);
		line_to (ctx, seed[2], x, y + height);
		line_to (ctx, seed[3], x, y);
	}

	/* Crazyline. By Steve Hanov, 2008
	 * Released to the public domain.
	 *
	 * The idea is to draw a curve, setting two control points at random 
	 * close to each side of the line. The longer the line, the sloppier it's drawn.
	 */
	public static void line_to (Context ctx, uint32 seed, double toX, double toY)
	{
		double fromX;
		double fromY;

		ctx.get_current_point (out fromX, out fromY);

		// stdout.puts (@"$fromX, $fromY, $toX, $toY\n");

		double control1X;
		double control1Y;
		double control2X;
		double control2Y;

		// calculate the length of the line.
		double length = Math.sqrt( (toX-fromX)*(toX-fromX) + (toY-fromY)*(toY-fromY));
		
		// This offset determines how sloppy the line is drawn. It depends on the 
		// length, but maxes out at 20.
		double offset = length/20;
		if ( offset > 20 ) offset = 20;

		var rand = new Rand.with_seed (seed);
		// var rand = new Rand ();

		// Overshoot the destination a little, as one might if drawing with a pen.
		toX += rand.next_double ()*offset/4;
		toY += rand.next_double ()*offset/4;

		double t1X = fromX;
		double t1Y = fromY;
		double t2X = toX;
		double t2Y = toY;

		// t1 and t2 are coordinates of a line shifted under or to the right of 
		// our original.
		t1X += offset;
		t2X += offset;
		t1Y += offset;
		t2Y += offset;

		// create a control point at random along our shifted line.
		double r = rand.next_double ();
		control1X = t1X + r * (t2X-t1X);
		control1Y = t1Y + r * (t2Y-t1Y);

		// now make t1 and t2 the coordinates of our line shifted above 
		// and to the left of the original.

		t1X = fromX - offset;
		t2X = toX - offset;
		t1Y = fromY - offset;
		t2Y = toY - offset;

		// create a second control point at random along the shifted line.
		r = rand.next_double ();
		control2X = t1X + r * (t2X-t1X);
		control2Y = t1Y + r * (t2Y-t1Y);

		// draw the line!
		ctx.move_to(fromX, fromY);
		ctx.curve_to(control1X, control1Y, control2X, control2Y, toX, toY);
	}

	public override void get_preferred_width (out int minimum_width, out int natural_width)
	{
		minimum_width = (int)width*GRID_SIZE;
		natural_width = (int)width*GRID_SIZE;
	}

	public override void get_preferred_height (out int minimum_height, out int natural_height)
	{
		minimum_height = (int)height*GRID_SIZE;
		natural_height = (int)height*GRID_SIZE;
	}

	public void viewport_to_map (ref double x, ref double y)
	{
		// stdout.puts (@"x:$x, y:$y, new x: $((x-this.x)/GRID_SIZE), $((y-this.y)/GRID_SIZE)\n");
		x = x/GRID_SIZE - this.x;
		y = y/GRID_SIZE - this.y;
	}

	public void map_to_viewport (ref double x, ref double y)
	{
		x = (this.x + x) * GRID_SIZE;
		y = (this.y + y) * GRID_SIZE;
	}

	public Json.Node serialize ()
	{
		Json.Builder builder = new Json.Builder ();

		builder.begin_object ();
		builder.set_member_name ("room_list");
		builder.begin_array ();

		foreach (var drawable in drawable_list)
			if (drawable is Room)
				drawable.serialize (builder);

		builder.end_array ();

		builder.set_member_name ("passage_list");
		builder.begin_array ();
		foreach (var drawable in drawable_list)
			if (drawable is Passage)
				drawable.serialize (builder);

		builder.end_array ();
		builder.end_object ();

		return builder.get_root ();
	}

	public void deserialize (Json.Node node)
	{
		drawable_list = new Gee.ArrayList<Drawable> ();

		Gee.Map<uint, Room> rooms = new Gee.HashMap<uint, Room> ();
		var obj = node.get_object ();
		var room_list = obj.get_array_member ("room_list");
		room_list.foreach_element ((a, i, node) =>
		{
			var room = Room.deserialize (this, node);
			drawable_list.add (room);
			rooms.set ((uint)node.get_object ().get_int_member ("hash"), room);
		});

		Gee.Map<uint, Passage> passages = new Gee.HashMap<uint, Passage> ();
		var array = obj.get_array_member ("passage_list");
		array.foreach_element ((a, i, node) =>
		{
			var passage = Passage.deserialize (this, node, rooms);
			drawable_list.add (passage);
			passages.set ((uint)node.get_object ().get_int_member ("hash"), passage);
		});

		room_list.foreach_element ((a, i, node) => rooms.get ((uint)node.get_object ().get_int_member ("hash")).read_passages (node, passages));
	}
}