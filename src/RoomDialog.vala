using Gtk;

class WhiteHouse.RoomDialog : Dialog
{
	private Entry entry;
	private TextView text;
	private bool accept = false;

	public RoomDialog (Window? parent)
	{
		set_default_size (350, 200);
		set_modal (true);
		
		// Create inputs
		var vbox = get_content_area () as Gtk.Box;
		entry = new Entry ();
		entry.activate.connect (() => response (ResponseType.ACCEPT));
		entry.activates_default = true;
		entry.placeholder_text = "Name";
		vbox.add (entry);
		text = new TextView ();
		text.left_margin = 5;
		text.right_margin = 5;
		text.expand = true;
		text.placeholder_text = "Description";
		text.wrap_mode = WrapMode.WORD_CHAR;
		vbox.add (text);

		// The buttons
		add_button ("OK", ResponseType.ACCEPT);
		add_button ("Cancel", Gtk.ResponseType.CANCEL);
	}

	public RoomDialog.with_presets (Window? parent, string name, string? desc)
	{
		this (parent);
		entry.text = name;
		if (desc != null)
			text.buffer.text = desc;
	}

	public override void response (int id)
	{
		switch (id)
		{
			case Gtk.ResponseType.ACCEPT:
				accept = true;
				destroy ();
				break;
			case Gtk.ResponseType.CANCEL:
				destroy ();
				break;
		}
	}

	public new void run (out string name, out string desc)
	{
		Gtk.main ();
		if (!accept)
			return;

		name = entry.text;
		desc = text.buffer.text;
	}

	public override void destroy ()
	{
		Gtk.main_quit ();
	}
}