using Gtk;

class WhiteHouse.AboutDialog : Dialog
{
	public AboutDialog (Window? parent)
	{
		set_default_size (350, 200);
		set_modal (true);
		
		var vbox = get_content_area () as Gtk.Box;
		var hbox = new Box (Orientation.HORIZONTAL, 0);
		vbox.add (hbox);

		var icon = new Image.from_icon_name ("white-house", IconSize.DIALOG);
		icon.margin = 20;
		hbox.pack_start (icon, true, false);
		var label = new Label ("<span size=\"xx-large\">White House</span>");
		label.use_markup = true;
		label.margin = 20;
		hbox.pack_start (label, true, false);

		vbox.add (new Label ("Idiotic Development and Design\nReleased under the GPL version 3.\n"));

		hbox = new Box (Orientation.HORIZONTAL, 0);
		vbox.add (hbox);
		hbox.pack_start (new Label (""), true, false);
		hbox.pack_start (new LinkButton.with_label ("http://whitehouse.idioticdev.com", "Website"), false, false);
		hbox.pack_start (new Label (" . "), false, false);
		hbox.pack_start (new LinkButton.with_label ("http://github.com/idiotic-development/WhiteHouse", "Source"), false, false);
		hbox.pack_start (new Label (" . "), false, false);
		hbox.pack_start (new LinkButton.with_label ("http://idioticdev.com", "Idiotic"), false, false);
		hbox.pack_start (new Label (""), true, false);

		// The buttons
		add_button ("Close", ResponseType.ACCEPT);
	}

	public override void response (int id)
	{
		destroy ();
	}
}