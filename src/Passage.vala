using Cairo;

public class WhiteHouse.Passage : GLib.Object, Drawable
{
	public enum State
	{
		CLICK,
		DRAG,
		NONE
	}
	private State state { get; set; default = State.NONE; }

	public bool locked { get; private set; default = false; }
	public bool one_way { get; private set; default = false; }
	double _z;
	public double z
	{
		get
		{
			if (end == null || start.z == end.z)
				return _z;
			else if (start.z > end.z)
				return start.z - 0.5;
			else
				return start.z + 0.5;
		}

		set { _z = value; }
	}

	Gee.List<double?> x_list = new Gee.ArrayList<double?> ();
	Gee.List<double?> y_list = new Gee.ArrayList<double?> ();
	Gee.List<uint32?> seed_list = new Gee.ArrayList<uint32?> ();
	int list_index = -1;
	public Room end { get; set; }
	public Room start { get; set; }

	public double x { get; private set; }
	public double y { get; private set; }

	private double x1
	{
		get
		{
			if (start == null)
				return -1;
			else if (this == start.west || start.northwest || start.southwest)
				return start.x;
			else if (this == start.north || start.south || start.up || start.down)
				return start.x + start.width/2;
			else
				return start.x + start.width;
		}
	}

	private double y1
	{
		get
		{
			if (start == null)
				return -1;
			else if (this == start.northwest || start.north || start.northeast)
				return start.y;
			else if (this == start.west || start.east || start.up || start.down)
				return start.y + start.height/2;
			else
				return start.y + start.height;
		}
	}

	private double x2
	{
		get
		{
			if (end == null)
			{
				if (this == start.west || start.northwest || start.southwest)
					return start.x - 0.5;
				else if (this == start.north || start.south || start.up || start.down)
					return start.x + start.width/2;
				else
					return start.x + start.width + 0.5;
			} else if (this == end.west || end.northwest || end.southwest)
				return end.x;
			else if (this == end.north || end.south || end.up || end.down)
				return end.x + end.width/2;
			else
				return end.x + end.width;
		}
	}

	private double y2
	{
		get
		{
			if (end == null)
			{
				if (this == start.northwest || start.north || start.northeast)
					return start.y - 0.5;
				else if (this == start.west || start.east || start.up || start.down)
					return start.y + start.height/2;
				else
					return start.y + start.height + 0.5;
			} else if (this == end.northwest || end.north || end.northeast)
				return end.y;
			else if (this == end.west || end.east || end.up || end.down)
				return end.y + end.height/2;
			else
				return end.y + end.height;
		}
	}

	Map map;

	public Passage (Map map, Room start)
	{
		this.map = map;
		this.start = start;
		x = x1;
		y = y1;
		z = map.z_level;
		var rand = new Rand ();
		seed_list.add (rand.next_int ());
	}

	public Passage.with_end (Map map, Room start, Room end)
	{
		this (map, start);
		this.end = end;
	}

	public void flip ()
	{
		var tmp = start;
		_start = end;
		_end = tmp;

		for (var i = 0; i < x_list.size/2; i++)
		{
			var tmp_n = x_list[i];
			x_list[i] = x_list[x_list.size-1-i];
			x_list[x_list.size-1-i] = tmp_n;

			tmp_n = y_list[i];
			y_list[i] = y_list[y_list.size-1-i];
			y_list[y_list.size-1-i] = tmp_n;
		}
	}

	private double x_list_get (int i)
	{
		if (i == 0)
			return x1;
		else if (i == x_list.size+1)
			return x2;
		else
			return x_list.get (i-1);
	}

	private double y_list_get (int i)
	{
		if (i == 0)
			return y1;
		else if (i == y_list.size+1)
			return y2;
		else
			return y_list.get (i-1);
	}

	public bool contains (double x, double y)
	{
		for (var i = 1; i < x_list.size+2; i++)
			if (segment_contains (x_list_get (i-1), y_list_get (i-1), x_list_get (i), y_list_get (i), x, y) < 0.5)
				return true;

		return false;
	}

	private double segment_contains (double x1, double y1, double x2, double y2, double x, double y)
	{
		if (Math.fabs (y2-y1) > Math.fabs (y2-y)
			&& Math.fabs (y2-y1) > Math.fabs (y1-y)
			&& Math.fabs (x2-x1) > Math.fabs (x2-x)
			&& Math.fabs (x2-x1) > Math.fabs (x1-x))
		{
			return Math.fabs ((y2-y1)*x-(x2-x1)*y+x2*y1-y2*x1)
				/Math.sqrt ((y2-y1)*(y2-y1)+(x2-x1)*(x2-x1));
		}
		else
		{
			var dst2 = Math.sqrt ((y2-y)*(y2-y)+(x2-x)*(x2-x));
			var dst1 = Math.sqrt ((y1-y)*(y1-y)+(x1-x)*(x1-x));
			return (dst1 < dst2) ? dst1 : dst2;
		}
	}

	public void delete ()
	{
		map.drawable_list.remove (this);
	}

	public void mouse_down (double x, double y, int b)
	{
		state = State.CLICK;

		for (var i = 0; i < x_list.size; i++)
			if (Math.sqrt ((y-y_list[i])*(y-y_list[i])+(x-x_list[i])*(x-x_list[i])) < 0.5)
				list_index = i;
	}

	public void mouse_up (double x, double y, int b)
	{
		State tmp_state = state;
		state = State.NONE;

		if (list_index > -1)
		{
			var x_val = x_list[list_index];
			var y_val = y_list[list_index];
			if (Math.fabs (x_val - Math.round (x_val)) < 0.3)
				x_list[list_index] = Math.round (x_val);

			if (Math.fabs (y_val - Math.round (y_val)) < 0.3)
				y_list[list_index] = Math.round (y_val);
		}

		list_index = -1;

		if (tmp_state != State.CLICK)
			return;

		if (b == 3)
		{
			for (var i = 0; i < x_list.size; i++)
				if (Math.sqrt ((y-y_list[i])*(y-y_list[i])+(x-x_list[i])*(x-x_list[i])) < 0.5)
				{
					seed_list.remove_at (i+1);
					x_list.remove_at (i);
					y_list.remove_at (i);
					return;
				}

			this.delete ();
		} else if (Math.sqrt ((y-y1)*(y-y1)+(x-x1)*(x-x1)) < 2)
			one_way = !one_way;
		else if (Math.sqrt ((y2-y)*(y2-y)+(x2-x)*(x2-x)) < 2)
		{
			flip ();
			one_way = true;
		} else
			locked = !locked;
	}

	public void mouse_move (double x, double y)
	{
		if (state == State.CLICK)
		{
			map.drag_target = this;
			state = State.DRAG;
		} else if (map.drag_target != this)
			return;

		if (end == null)
		{
			this.x = x;
			this.y = y;			
		} else if (list_index < 0)
		{
			for (var i = 1; i < x_list.size+2; i++)
				if (segment_contains (x_list_get (i-1), y_list_get (i-1), x_list_get (i), y_list_get (i), x, y) < 0.5)
				{
					var rand = new Rand ();
					seed_list.insert (i, rand.next_int ());
					x_list.insert (i-1, x);
					y_list.insert (i-1, y);
					list_index = i-1;
					break;
				}
		} else
		{
			x_list[list_index] = x;
			y_list[list_index] = y;
		}

	}

	public void mouse_enter () {}
	public void mouse_leave () {}

	public void draw (Context ctx, double scale)
	{
		if (Math.fabs (z - start.z) == 0.5)
		{
			var color = Gdk.RGBA ();
			color.parse (SETTINGS.get_string ("passage-line"));
			ctx.set_source_rgb (color.red, color.green, color.blue);

			ctx.set_font_size (scale/2);

			var visable = (start.z == map.z_level) ? start : end;
			var name = (start.z == map.z_level) ? end.name : start.name;

			var x = visable.x;
			var width = visable.width*scale;
			var y = visable.y;
			var height = visable.height*scale;
			map.map_to_viewport (ref x, ref y);

			if (this == visable.up)
			{
				Cairo.TextExtents ext;
				ctx.text_extents ("\u2191", out ext);
				ctx.move_to (x+width/5-ext.width/2-ext.x_bearing, y-0.125*scale+ext.height/2-2);
				ctx.show_text ("\u2191");
				ctx.move_to (x+width/5-ext.width/2-ext.x_bearing, y-0.125*scale-ext.height);
		        ctx.set_font_size (scale/3);
		        ctx.show_text (name);
			} else 
			{
				Cairo.TextExtents ext;
				ctx.text_extents ("\u2193", out ext);
				ctx.move_to (x+width/5*4-ext.width/2-ext.x_bearing, y+height+0.125*scale+ext.height/2+2);
				ctx.show_text ("\u2193");
				ctx.move_to (x+width/5*4-ext.width/2-ext.x_bearing, y+height+0.125*scale+ext.height*2);
		        ctx.set_font_size (scale/3);
		        ctx.show_text (name);
			}

			return;
		}

		var color = Gdk.RGBA ();

		if (z == map.z_level)
			color.parse (SETTINGS.get_string ("passage-line"));
		else
			color.parse (SETTINGS.get_string ("room-inactive"));

		ctx.set_source_rgb (color.red, color.green, color.blue);

		var hand_drawn = WhiteHouse.SETTINGS.get_boolean ("passage-drawn");

		double x1 = this.x1;
		double y1 = this.y1;
		double x2 = this.x2;
		double y2 = this.y2;
		map.map_to_viewport (ref x1, ref y1);
		map.map_to_viewport (ref x2, ref y2);

		if (locked)
			ctx.set_dash ({8, 5}, 0);
		else
			ctx.set_dash ({1, 0}, 0);

		ctx.set_line_width (2);
		ctx.move_to (x1, y1);
		for (var i = 0; i < x_list.size; i++)
		{
			double x = x_list[i];
			double y = y_list[i];
			map.map_to_viewport (ref x, ref y);
			if (hand_drawn)
				Map.line_to (ctx, seed_list[i+1], x, y);
			else
				ctx.line_to (x, y);
		}
		
		if (map.drag_target == this)
		{
			double x = this.x;
			double y = this.y;
			map.map_to_viewport (ref x, ref y);
			if (hand_drawn)
				Map.line_to (ctx, seed_list[0], x, y);
			else
				ctx.line_to (x, y);
		}
		else
		{
			if (hand_drawn)
				Map.line_to (ctx, seed_list[0], x2, y2);
			else
				ctx.line_to (x2, y2);
		}

		ctx.stroke ();

		if (one_way)
		{
			color.parse (SETTINGS.get_string ("passage-detail"));
			ctx.set_source_rgb (color.red, color.green, color.blue);

			var gap = 3.0;
			for (var i = x_list.size+1; i > 0; i--)
			{
				var dst = Math.sqrt ((y_list_get (i)-y_list_get (i-1))*(y_list_get (i)-y_list_get (i-1))+(x_list_get (i)-x_list_get (i-1))*(x_list_get (i)-x_list_get (i-1)));
				while (dst > 3)
				{
					dst -= gap;
					gap = 3;
					draw_arrow (ctx, x_list_get (i-1), y_list_get (i-1), x_list_get (i), y_list_get (i), dst*scale);
				}

				gap = 3 - dst;
			}
		}
	}

	private void draw_arrow (Context ctx, double x1, double y1, double x2, double y2, double dst)
	{
		map.map_to_viewport (ref x1, ref y1);
		map.map_to_viewport (ref x2, ref y2);

		var m = (y1 - y2) / (x1 - x2);
		var x = dst / Math.sqrt (m * m + 1);
		var y = (x1 == x2) ? (y1 < y2) ? dst : -dst : x*m;
		if (x1 > x2)
		{
			x = x1 - x;
			y = y1 - y;
		} else
		{
			x = x1 + x;
			y = y1 + y;
		}

		var angle = Math.atan (m) + Math.PI/2; // Angle to rotate
		if (x1 < x2)
			angle += Math.PI;

		var size = 15;

		// Vertex's coordinates before rotating
		var ax1 = x - size / 2;
		var ay1 = y + size / 2;
		var ax2 = x;
		var ay2 = y - size / 2;
		var ax3 = x + size / 2;
		var ay3 = ay1;

		// Rotating
		var x1r = (ax1 - x) * Math.cos(angle) - (ay1 - y) * Math.sin(angle) + x;
		var y1r = (ax1 - x) * Math.sin(angle) + (ay1 - y) * Math.cos(angle) + y;

		var x2r = (ax2 - x) * Math.cos(angle) - (ay2 - y) * Math.sin(angle) + x;
		var y2r = (ax2 - x) * Math.sin(angle) + (ay2 - y) * Math.cos(angle) + y;

		var x3r = (ax3 - x) * Math.cos(angle) - (ay3 - y) * Math.sin(angle) + x;
		var y3r = (ax3 - x) * Math.sin(angle) + (ay3 - y) * Math.cos(angle) + y;

		// Drawing
		ctx.move_to(x1r, y1r);
		ctx.line_to(x2r, y2r);
		ctx.line_to(x3r, y3r);
		ctx.line_to(x1r, y1r);
		ctx.fill ();

	}

	public uint hash ()
	{
		var s = @"$x1$y1$x2$y2$_z$locked$one_way";

		foreach (var x in x_list)
			s += x.to_string ();

		foreach (var y in y_list)
			s += y.to_string ();

		return s.hash ();
	}

	public void serialize (Json.Builder builder)
	{
		builder.begin_object ();
		builder.set_member_name ("start");
		builder.add_int_value (start.hash ());
		builder.set_member_name ("end");
		builder.add_int_value (end.hash ());
		builder.set_member_name ("hash");
		builder.add_int_value (hash ());
		
		if (x_list.size > 0)
		{
			builder.set_member_name ("x_list");
			builder.begin_array ();

			foreach (var x in x_list)
				builder.add_double_value (x);

			builder.end_array ();
			builder.set_member_name ("y_list");
			builder.begin_array ();

			foreach (var y in y_list)
				builder.add_double_value (y);

			builder.end_array ();
		}

		if (locked)
		{
			builder.set_member_name ("locked");
			builder.add_boolean_value (locked);
		}

		if (one_way)
		{
			builder.set_member_name ("one_way");
			builder.add_boolean_value (one_way);
		}

		builder.end_object ();
	}

	public static Passage deserialize (Map map, Json.Node node, Gee.Map<uint, Room> rooms)
	{
		var obj = node.get_object ();
		var start = rooms.get ((uint)obj.get_int_member ("start"));
		var end = rooms.get ((uint)obj.get_int_member ("end"));
		var passage = map.new_passage (start, end);

		if (obj.has_member ("locked"))
			passage.locked = obj.get_boolean_member ("locked");

		if (obj.has_member ("one_way"))
			passage.one_way = obj.get_boolean_member ("one_way");

		if (obj.has_member ("x_list"))
		{
			var array = obj.get_array_member ("x_list");
			array.foreach_element ((a, i, node) => passage.x_list.add (node.get_double ()));

			array = obj.get_array_member ("y_list");
			array.foreach_element ((a, i, node) => passage.y_list.add (node.get_double ()));
		}

		return passage;
	}
}