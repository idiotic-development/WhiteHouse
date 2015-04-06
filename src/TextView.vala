using Cairo;

public class WhiteHouse.TextView : Gtk.TextView
{
	public string placeholder_text { get; set; }

	public override bool draw (Context ctx)
	{
		if (!has_focus && buffer.text == "")
		{
			ctx.set_source_rgb (0.5, 0.5, 0.5);
	        ctx.set_font_size (14);
	        ctx.move_to (10, 20);
			ctx.show_text (placeholder_text);
		}

		base.draw (ctx);

		return false;
	}
}