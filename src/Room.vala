using Cairo;

public class WhiteHouse.Room : GLib.Object, Drawable
{
	public enum State
	{
		NONE,
		HOVER,
		CLICK,
		RESIZE,
		DRAG,
		TAB
	}

	public State state	{ get; private set; default = State.NONE; }

	public bool highlighted { get; set; default = false; }

	bool _selected;
	public bool selected
	{
		get { return _selected; }
		set
		{
			_selected = value;
			if (value)
			{
				trh = new Handle (this, 1);
				tlh = new Handle (this, 2);
				blh = new Handle (this, 3);
				brh = new Handle (this, 4);
			} else
			{
				trh = null;
				tlh = null;
				blh = null;
				brh = null;
			}
		}
	}

	// Size and posistion
	double _x;
	public double x	
	{
		get
		{
			if (z == Map.map.z_level - 1)
				return _x + Map.FLOOR_OFFSET_X;
			else
				return _x;
		} set
		{
			_x = value;
			var x = value;
			var y = 0.0;
			Map.map.map_to_viewport (ref x, ref y);
			x = x / Map.GRID_SIZE;
			if (x < 0)
				Map.map.width += (int)(width*2);

			if (x + width > Map.map.width)
				Map.map.width += (int)(width*2);
		}
	}
	double _y;
	public double y
	{
		get
		{
			if (z == Map.map.z_level - 1)
				return _y + Map.FLOOR_OFFSET_Y;
			else
				return _y;
		} set
		{
			_y = value;
			var x = 0.0;
			var y = value;
			Map.map.map_to_viewport (ref x, ref y);
			y = y / Map.GRID_SIZE;
			if (y < 0)
				Map.map.height += (int)(height*2);
			else if (y + height > Map.map.height)
				Map.map.height += (int)(height*2);
		}
	}
	double _z;
	public double z
	{
		get { return _z; }
		set
		{
			foreach (var item in passages ())
				if (item != null)
					item.z = value;

			_z = value;
		}
	}
	public double width	{ get; set; default = 3; }
	public double height{ get; set; default = 2; }

	// Info
	public string name	{ get; set; }
	public string desc	{ get; set; }

	Passage _north;
	public Passage north
	{
		get {return _north;}
		set { if (_north != null) _north.delete (); _north = value; }
	}
	Passage _northeast;
	public Passage northeast
	{
		get {return _northeast;}
		set { if (_northeast != null) _northeast.delete (); _northeast = value; }
	}
	Passage _east;
	public Passage east
	{
		get {return _east;}
		set { if (_east != null) _east.delete (); _east = value; }
	}
	Passage _southeast;
	public Passage southeast
	{
		get {return _southeast;}
		set { if (_southeast != null) _southeast.delete (); _southeast = value; }
	}
	Passage _south;
	public Passage south
	{
		get {return _south;}
		set { if (_south != null) _south.delete (); _south = value; }
	}
	Passage _southwest;
	public Passage southwest
	{
		get {return _southwest;}
		set { if (_southwest != null) _southwest.delete (); _southwest = value; }
	}
	Passage _west;
	public Passage west
	{
		get {return _west;}
		set { if (_west != null) _west.delete (); _west = value; }
	}
	Passage _northwest;
	public Passage northwest
	{
		get {return _northwest;}
		set { if (_northwest != null) _northwest.delete (); _northwest = value; }
	}
	Passage _up;
	public Passage up
	{
		get {return _up;}
		set { if (_up != null) _up.delete (); _up = value; }
	}
	Passage _down;
	public Passage down
	{
		get {return _down;}
		set { if (_down != null) _down.delete (); _down = value; }
	}

	public Passage[] passages ()
	{
		return new Passage[] { north, east, northeast, southeast,
					south, southwest, west, northwest, up, down };
	}

	private Tab tl;
	private Tab tc;
	private Tab tr;
	private Tab lc;
	private Tab rc;
	private Tab bl;
	private Tab bc;
	private Tab br;
	private Tab d;
	private Tab u;

	public Tab[] tabs ()
	{
		return new Tab[] { tl, tc, tr, lc, rc, bl, bc, br, d, u };
	}

	Handle trh;
	Handle tlh;
	Handle blh;
	Handle brh;
	public Handle[] handles ()
	{
		return new Handle[] { trh, tlh, brh, blh };
	}

	uint32[] seed;

	public Room (string name, string? desc)
	{
		seed = new uint32[4];
		var rand = new Rand ();
		seed[0] = rand.next_int ();
		seed[1] = rand.next_int ();
		seed[2] = rand.next_int ();
		seed[3] = rand.next_int ();

		this.name = name;
		this.desc = desc;
		z = Map.map.z_level;
	}

	public void delete ()
	{
		Map.map.drawable_list.remove (this);

		foreach (var item in passages ())
			if (item != null)
				item.delete ();
	}

	public bool contains (double x, double y)
	{
		var return_val = false;
		foreach (var t in tabs ())
			if (t != null)
				return_val = return_val || t.contains (x, y);

		foreach (var h in handles ())
			if (h != null)
				return_val = return_val || h.contains (x, y);

		return (x >= this.x
				&& y >= this.y
				&& x < this.x + width
				&& y < this.y + height) || return_val;
	}

	public void mouse_down (double x, double y, int b)
	{
		state = State.CLICK;

		foreach (var tab in tabs ())
			if (tab.contains (x,y))
			{
				state = State.TAB;
				tab.mouse_down (x, y, b);
				break;
			}

		foreach (var item in handles ())
			if (item != null && item.contains (x, y))
			{
				state = State.RESIZE;
				item.mouse_down (x, y);
			}
	}

	public void mouse_up (double x, double y, int b)
	{
		if (Map.map.drag_target is Passage)
		{
			var p_drag = (Passage)Map.map.drag_target;
			if (p_drag.start.z > z)
			{
				up = p_drag;
				p_drag.end = this;
			} else if (p_drag.start.z < z)
			{
				down = p_drag;
				p_drag.end = this;
			} else
			{
				var smallest = width;
				Tab colsest = null;
				foreach (var tab in tabs ())
				{
					var dst = Math.hypot(tab.x-x, tab.y-y);
					if (tab != null && smallest > dst)
					{
						smallest = dst;
						colsest = tab;
					}
				}
				colsest.mouse_up (x, y, b);
			}
		} else if (b == 3)
		{
			this.delete ();
			return;
		} else if (state == State.RESIZE)
		{
			foreach (var item in handles ())
				if (item.contains (x, y))
					item.mouse_up (x, y);
		} else
			foreach (var tab in tabs ())
				if (tab != null && tab.contains (x, y))
				{
					tab.mouse_up (x, y, b);
					break;
				}

		var tmp_state = state;
		if (contains (x, y))
			state = State.HOVER;
		else
			state = State.NONE;

		if (tmp_state == State.DRAG)
		{
			active = false;
			this.x = Math.round (this.x);
			this.y = Math.round (this.y);
		}

		if (selected && tmp_state == State.CLICK)
			Map.map.room_dialog (this);
	}

	double last_x;
	double last_y;
	bool active = false;
	public void mouse_move (double x, double y)
	{
		if (state == State.CLICK)
			state = State.DRAG;
		else if (state == State.RESIZE)
		{
			foreach (var item in handles ())
				item.mouse_move (x, y);

			return;
		} else if (state != State.DRAG)
			return;

		// Set last for first iteration
		if (!active)
		{
			last_x = x;
			last_y = y;
			active = true;
		}

		// Move by difference between old and new x and y
		this.x -= last_x - x;
		this.y -= last_y - y;

		// Record for next iteration
		last_x = x;
		last_y = y;

		// Clear tabs
		tl = null;
		tc = null;
		tr = null;
		lc = null;
		rc = null;
		bl = null;
		bc = null;
		br = null;
		d  = null;
		u  = null;
	}

	public void mouse_enter ()
	{
		if (state == State.NONE &&
			(!(Map.map.drag_target is Passage) || ((Passage)Map.map.drag_target).start.z == z))
			state = State.HOVER;
	}
	public void mouse_leave ()
	{
		if (state == State.HOVER)
			state = State.NONE;
	}

	/*
	 *	Draw the room.
	 *
	 *	ctx:	The canvas to draw on.
	 *	scale:	Grid size.
	 */
	public void draw (Context ctx, double scale)
	{
		var x = this.x;
		var y = this.y;
		Map.map.map_to_viewport (ref x, ref y);
		var color = Gdk.RGBA ();

		if (selected || state == State.RESIZE)
		{
			color.parse (Window.SETTINGS.get_string ("room-outline"));
			ctx.set_source_rgb (color.red, color.green, color.blue);
			ctx.rectangle (x-5, y-5, width*scale+5, height*scale+5);
			ctx.fill ();
			color.parse (Window.SETTINGS.get_string ("background-color"));
			ctx.set_source_rgb (color.red, color.green, color.blue);
			Map.rectangle (ctx, seed, x-5, y-5, width*scale+5, height*scale+5);
			ctx.set_line_width (width*scale/20);
			ctx.stroke ();

			foreach (var item in handles ())
				item.draw (ctx, scale);

			color.parse (Window.SETTINGS.get_string ("room-background"));
			ctx.set_source_rgb (color.red, color.green, color.blue);
		} else if (highlighted)
		{
			color.parse (Window.SETTINGS.get_string ("room-outline"));
			ctx.set_source_rgb (color.red-(1-color.red)/2 , color.green-(1-color.green)/2, color.blue-(1-color.blue)/2);
			ctx.rectangle (x-5, y-5, width*scale+5, height*scale+5);
			ctx.fill ();
			color.parse (Window.SETTINGS.get_string ("background-color"));
			ctx.set_source_rgb (color.red, color.green, color.blue);
			Map.rectangle (ctx, seed, x-5, y-5, width*scale+5, height*scale+5);
			ctx.set_line_width (width*scale/20);
			ctx.stroke ();

			color.parse (Window.SETTINGS.get_string ("room-background"));
			ctx.set_source_rgb (color.red, color.green, color.blue);	
		} else
		{
			// Clear grid
			color.parse (Window.SETTINGS.get_string ("room-background"));
			ctx.set_source_rgb (color.red, color.green, color.blue);
			ctx.rectangle (x, y, width*scale, height*scale);
			ctx.fill ();

			// Square outline
			if (z == Map.map.z_level)
				color.parse (Window.SETTINGS.get_string ("room-outline"));
			else
				color.parse (Window.SETTINGS.get_string ("room-inactive"));

			ctx.set_source_rgb (color.red, color.green, color.blue);

			ctx.set_line_width (2);
			Map.rectangle (ctx, seed, x, y, width*scale, height*scale);
			ctx.stroke ();

			// Name
			if (z == Map.map.z_level)
			{
				color.parse (Window.SETTINGS.get_string ("room-text"));
				ctx.set_source_rgb (color.red, color.green, color.blue);
			}
		}
		ctx.set_font_size (scale/2);
		TextExtents ext;
		ctx.text_extents (name, out ext); // Gets the physical size of the string
		if (ext.x_bearing + ext.width < width*scale)
		{
			ctx.move_to (x + width*scale/2 - (ext.x_bearing + ext.width/2), y + height*scale/2 - (ext.y_bearing + ext.height/2));
			ctx.show_text (name);
		} else
		{
			var text = name;
			Gee.List<string> lines = new Gee.ArrayList<string> ();
			while (text != "")
			{
				var line = "";
				var line_width = 0.0;
				var word = "";
				while (line_width < width*scale && text != "")
				{
					if (word != "")
					{
						line += word;
						text = (text.index_of (" ") == -1) ? "" : text[text.index_of (" ")+1:text.length];
					}

					word = (text.index_of (" ") == -1) ? text : text[0:text.index_of (" ")+1];
					TextExtents size;
					ctx.text_extents (line + word, out size);
					line_width = size.width;
					ctx.text_extents (word, out size);
					if (size.width > width*scale)
					{
						lines.add (word);
						text = (text.index_of (" ") == -1) ? "" : text[text.index_of (" ")+1:text.length];
					}
				}
				lines.add (line);
			}

			for (var i = 0; i < lines.size; i++)
			{
				TextExtents size;
				ctx.text_extents (lines[i], out size);
				ctx.move_to (x + width*scale/2 - size.width/2, y + (height*scale - (size.height+5)*lines.size)/2+size.height + (size.height+5)*i);
				ctx.show_text (lines [i]);
			}
		}

		// Mouseover details
		if (state == State.HOVER)
		{
			// Top left
			tl = tl ?? new Tab ("northwest", this);
			tl.draw (ctx, scale);

			// Top center
			tc = tc ?? new Tab ("north", this);
			tc.draw (ctx, scale);

			// Top right
			tr = tr ?? new Tab ("northeast", this);
			tr.draw (ctx, scale);

			// Left center
			lc = lc ?? new Tab ("west", this);
			lc.draw (ctx, scale);

			// Right center
			rc = rc ?? new Tab ("east", this);
			rc.draw (ctx, scale);

			// Bottom left
			bl = bl ?? new Tab ("southwest", this);
			bl.draw (ctx, scale);

			// Bottom center
			bc = bc ?? new Tab ("south", this);
			bc.draw (ctx, scale);

			// Bottom right
			br = br ?? new Tab ("southeast", this);
			br.draw (ctx, scale);

			d = d ?? new Tab ("down", this);
			d.draw (ctx, scale);

			u = u ?? new Tab ("up", this);
			u.draw (ctx, scale);
		}
	}

	public uint hash ()
	{
		return @"$name$desc$_x$_y$_z$height$width".hash ();
	}

	public void serialize (Json.Builder builder)
	{
		builder.begin_object ();
		builder.set_member_name ("name");
		builder.add_string_value (name);
		builder.set_member_name ("desc");
		builder.add_string_value (desc);
		builder.set_member_name ("width");
		builder.add_double_value (width);
		builder.set_member_name ("height");
		builder.add_double_value (height);
		builder.set_member_name ("x");
		builder.add_double_value (_x);
		builder.set_member_name ("y");
		builder.add_double_value (_y);
		builder.set_member_name ("z");
		builder.add_double_value (_z);
		builder.set_member_name ("hash");
		builder.add_int_value (hash ());

		if (north != null)
		{
			builder.set_member_name ("north");
			builder.add_int_value (north.hash ());
		}

		if (northeast != null)
		{
			builder.set_member_name ("northeast");
			builder.add_int_value (northeast.hash ());
		}

		if (east != null)
		{
			builder.set_member_name ("east");
			builder.add_int_value (east.hash ());
		}

		if (southeast != null)
		{
			builder.set_member_name ("southeast");
			builder.add_int_value (southeast.hash ());
		}

		if (south != null)
		{
			builder.set_member_name ("south");
			builder.add_int_value (south.hash ());
		}

		if (southwest != null)
		{
			builder.set_member_name ("southwest");
			builder.add_int_value (southwest.hash ());
		}

		if (west != null)
		{
			builder.set_member_name ("west");
			builder.add_int_value (west.hash ());
		}

		if (northwest != null)
		{
			builder.set_member_name ("northwest");
			builder.add_int_value (northwest.hash ());
		}

		if (up != null)
		{
			builder.set_member_name ("up");
			builder.add_int_value (up.hash ());
		}

		if (down != null)
		{
			builder.set_member_name ("down");
			builder.add_int_value (down.hash ());
		}

		builder.end_object ();
	}

	public static Room deserialize (Json.Node node)
	{
		var obj = node.get_object ();
		var name = obj.get_string_member ("name");
		var desc = obj.get_string_member ("desc");
		var room = Map.map.new_room (name, desc);
		room.width = obj.get_double_member ("width");
		room.height = obj.get_double_member ("height");
		room.x = obj.get_double_member ("x");
		room.y = obj.get_double_member ("y");
		room.z = obj.get_double_member ("z");

		return room;
	}

	public void read_passages (Json.Node node, Gee.Map<uint, Passage> passages)
	{
		var obj = node.get_object ();
		if (obj.has_member ("north"))
			north = passages.get ((uint)obj.get_int_member ("north"));

		if (obj.has_member ("northeast"))
			northeast = passages.get ((uint)obj.get_int_member ("northeast"));

		if (obj.has_member ("east"))
			east = passages.get ((uint)obj.get_int_member ("east"));

		if (obj.has_member ("southeast"))
			southeast = passages.get ((uint)obj.get_int_member ("southeast"));

		if (obj.has_member ("south"))
			south = passages.get ((uint)obj.get_int_member ("south"));

		if (obj.has_member ("southwest"))
			southwest = passages.get ((uint)obj.get_int_member ("southwest"));

		if (obj.has_member ("west"))
			west = passages.get ((uint)obj.get_int_member ("west"));

		if (obj.has_member ("northwest"))
			northwest = passages.get ((uint)obj.get_int_member ("northwest"));

		if (obj.has_member ("up"))
			up = passages.get ((uint)obj.get_int_member ("up"));

		if (obj.has_member ("down"))
			down = passages.get ((uint)obj.get_int_member ("down"));
	}
}