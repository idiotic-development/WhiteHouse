public class WhiteHouse.Handle
{
	public double x
	{
		get
		{
			if (corner == 3 || 4)
				return parent.x - size*2;
			else
				return parent.x + parent.width + size;
		}
	}

	public double y
	{
		get
		{
			if (corner == 1 || 4)
				return parent.y - size*2;
			else
				return parent.y + parent.height + size;
		}
	}


	int corner;
	double size = 0.25;
	Room parent;
	bool drag = false;

	public Handle (Room parent, int corner)
	{
		this.parent = parent;
		this.corner = corner;
	}

	public bool contains (double x, double y)
	{
		// return x >= this.x - size/2
		// 		&& y >= this.y - size/2
		// 		&& x <= this.x + size/2
		// 		&& y <= this.y + size/2;
		return x >= this.x && x <= this.x + size 
			&& y >= this.y && y <= this.y + size;
	}

	public void mouse_down (double x, double y)
	{
		drag = true;
	}

	public void mouse_up (double x, double y)
	{
		drag = false;
		parent.width = Math.round (parent.width);
		parent.height = Math.round (parent.height);
		parent.x = Math.round (parent.x);
		parent.y = Math.round (parent.y);
	}

	public void mouse_move (double x, double y)
	{
		if (!drag)
			return;

		if (corner == 1 || 2)
			parent.width += (x - this.x);
		else
		{
			parent.width += (this.x - x);
			parent.x -= (this.x - x);
		}

		if (corner == 2 || 3)
			parent.height += (y - this.y);
		else
		{
			parent.height += (this.y - y);
			parent.y -= (this.y - y);
		}
	}

	public void draw (Cairo.Context ctx, double scale)
	{
		// var x = this.x;
		// var y = this.y;
		// Map.map.map_to_viewport (ref x, ref y);

		ctx.set_line_width (2);

		Gdk.RGBA color = Gdk.RGBA ();

		// color.parse (Window.SETTINGS.get_string ("room-background"));
		// ctx.set_source_rgb (color.red, color.green, color.blue);
		// ctx.rectangle (x-size/2*scale, y-size/2*scale, size*scale, size*scale);
		// ctx.fill ();

		color.parse (Window.SETTINGS.get_string ("room-detail"));
		ctx.set_source_rgb (color.red, color.green, color.blue);
		// ctx.rectangle (x-size/2*scale, y-size/2*scale, size*scale, size*scale);
		// ctx.stroke ();

		var x = parent.x;
		var y = parent.y;
		var width = parent.width*scale;
		var height = parent.height*scale;
		var size = this.size*scale;
		Map.map.map_to_viewport (ref x, ref y);

		switch (corner)
		{
			case 1:
				ctx.move_to (x + width + size, y - size*2);
				ctx.line_to (x + width + size*2, y - size*2);
				ctx.line_to (x + width + size*2, y - size);
				break;
			case 2:
				ctx.move_to (x + width + size, y + height + size*2);
				ctx.line_to (x + width + size*2, y + height + size*2);
				ctx.line_to (x + width + size*2, y + height + size);
				break;
			case 3:
				ctx.move_to (x - size, y + height + size*2);
				ctx.line_to (x - size*2, y + height + size*2);
				ctx.line_to (x - size*2, y + height + size);
				break;
			case 4:
				ctx.move_to (x - size, y - size*2);
				ctx.line_to (x - size*2, y - size*2);
				ctx.line_to (x - size*2, y - size);
				break;
		}

		ctx.stroke ();
	}
}