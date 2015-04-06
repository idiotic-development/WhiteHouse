public class WhiteHouse.Tab : GLib.Object
{
	// Size and posistion
	public double x
	{
		get
		{
			if (property == "west" || "northwest" || "southwest")
				return parent.x;
			else if (property == "north" || "south")
				return parent.x + parent.width/2;
			else if (property == "up")
				return parent.x + parent.width/5;
			else if (property == "down")
				return parent.x + (parent.width/5)*4;
			else
				return parent.x + parent.width;
		}
	}

	public double y
	{
		get
		{
			if (property == "northwest" || "north" || "northeast")
				return parent.y;
			else if (property == "west" || "east")
				return parent.y + parent.height/2;
			else if (property == "up")
				return parent.y - size/2;
			else if (property == "down")
				return parent.y + parent.height + size/2;
			else
				return parent.y + parent.height;
		}
	}
	public double size { get; set; default = 0.25; }

	Room parent;
	string property;
	Map map;

	public Tab (Map map, string property, Room parent)
	{
		this.property = property;
		this.parent = parent;
		this.map = map;
	}

	public bool contains (double x, double y)
	{
		return x >= this.x - size/2
				&& y >= this.y - size/2
				&& x <= this.x + size/2
				&& y <= this.y + size/2;

	}

	public void mouse_down (double x, double y, int b)
	{
		var val = GLib.Value (typeof(Passage));
		parent.get_property (property, ref val);
		var p_val = (Passage)val;
		if (p_val != null)
		{
			if (p_val.end != parent && p_val.start != null)
			{
				p_val.flip ();
				p_val.start = parent;
			}

			p_val.end = null;
			map.drag_target = p_val;
		}else
		{
			if (property == "up")
				map.z_level += 1;
			else if (property == "down")
				map.z_level -= 1;

			var passage = map.new_passage (parent, null);
			map.drag_target = passage;
			Value in_val = passage;
			parent.set_property (property, in_val);
		}
	}

	public void mouse_up (double x, double y, int b)
	{
		if (!(map.drag_target is Passage))
			return;

		var val = GLib.Value (typeof(Passage));
		parent.get_property (property, ref val);
		if ((Passage)val != null)
			return;

		Passage passage = (Passage) map.drag_target;
		val = passage;
		passage.end = parent;
		parent.set_property (property, val);
	}

	public void draw (Cairo.Context ctx, double scale)
	{
		var x = this.x;
		var y = this.y;
		map.map_to_viewport (ref x, ref y);

		ctx.set_line_width (1);

		var color = Gdk.RGBA ();
		if (property == "up")
		{
			color.parse (SETTINGS.get_string ("room-detail"));
			ctx.set_source_rgb (color.red, color.green, color.blue);
			Cairo.TextExtents ext;
			ctx.text_extents ("\u2191", out ext);
			ctx.move_to (x-ext.width/2-ext.x_bearing, y+ext.height/2-2);
			ctx.show_text ("\u2191");
		} else if (property == "down")
		{
			color.parse (SETTINGS.get_string ("room-detail"));
			ctx.set_source_rgb (color.red, color.green, color.blue);
			Cairo.TextExtents ext;
			ctx.text_extents ("\u2193", out ext);
			ctx.move_to (x-ext.width/2-ext.x_bearing, y+ext.height/2+2);
			ctx.show_text ("\u2193");
		} else
		{
			color.parse (SETTINGS.get_string ("room-background"));
			ctx.set_source_rgb (color.red, color.green, color.blue);
			ctx.rectangle (x-size/2*scale, y-size/2*scale, size*scale, size*scale);
			ctx.fill ();

			color.parse (SETTINGS.get_string ("room-detail"));
			ctx.set_source_rgb (color.red, color.green, color.blue);
			ctx.rectangle (x-size/2*scale, y-size/2*scale, size*scale, size*scale);
			ctx.stroke ();
		}
	}
}