using Gtk;

public class WhiteHouse.Preferences : Dialog
{
	public Preferences ()
	{
		title = "Preferences";
		window_position = Gtk.WindowPosition.CENTER;
		set_modal (true);

		var top_box = get_content_area () as Gtk.Box;

		// The Notebook
		var notebook = new Gtk.Notebook ();
		top_box.add (notebook);
		notebook.margin = 13;

		add_button ("Close", Gtk.ResponseType.CLOSE);

		var title = new Gtk.Label ("Style");
		var style_box = new Box (Orientation.VERTICAL, 0);
		notebook.append_page (style_box, title);

		// Background
		var frame = new Gtk.Frame ("<b>Background</b>");
		style_box.add (frame);
		(frame.label_widget as Gtk.Label).use_markup = true;
		frame.shadow_type = ShadowType.NONE;
		frame.margin = 10;
		var box = new Box (Orientation.HORIZONTAL, 10);
		box.margin = 10;
		frame.add (box);

		var label = new Label ("Color");
		box.add (label);
		var color = Gdk.RGBA ();
		color.parse (SETTINGS.get_string ("background-color"));
		var button = new ColorButton.with_rgba (color);
		button.color_set.connect (() => SETTINGS.set_string ("background-color", button.rgba.to_string ()));
		box.add (button);

		label = new Label ("Grid");
		box.add (label);
		color = Gdk.RGBA ();
		color.parse (SETTINGS.get_string ("background-grid"));
		var button2 = new ColorButton.with_rgba (color);
		button2.color_set.connect (() => SETTINGS.set_string ("background-grid", button2.rgba.to_string ()));
		box.add (button2);

		frame = new Gtk.Frame ("<b>Room</b>");
		style_box.add (frame);
		(frame.label_widget as Gtk.Label).use_markup = true;
		frame.shadow_type = ShadowType.NONE;
		frame.margin = 10;
		var grid = new Grid ();
		grid.column_spacing = 10;
		grid.margin = 10;
		frame.add (grid);

		label = new Label ("Background");
		label.halign = Align.END;
		grid.add (label);
		color = Gdk.RGBA ();
		color.parse (SETTINGS.get_string ("room-background"));
		var button3 = new ColorButton.with_rgba (color);
		button3.color_set.connect (() => SETTINGS.set_string ("room-background", button3.rgba.to_string ()));
		button3.margin_end = 10;
		grid.add (button3);

		label = new Label ("Outline");
		label.halign = Align.END;
		grid.add (label);
		color = Gdk.RGBA ();
		color.parse (SETTINGS.get_string ("room-outline"));
		var button4 = new ColorButton.with_rgba (color);
		button4.margin_end = 10;
		button4.color_set.connect (() => SETTINGS.set_string ("room-outline", button4.rgba.to_string ()));
		grid.add (button4);

		label = new Label ("Text");
		label.halign = Align.END;
		grid.add (label);
		color = Gdk.RGBA ();
		color.parse (SETTINGS.get_string ("room-text"));
		var button5 = new ColorButton.with_rgba (color);
		button5.color_set.connect (() => SETTINGS.set_string ("room-text", button5.rgba.to_string ()));
		button5.margin_end = 10;
		grid.add (button5);

		label = new Label ("Detail");
		label.halign = Align.END;
		grid.attach (label, 0, 1, 1, 1);
		color = Gdk.RGBA ();
		color.parse (SETTINGS.get_string ("room-detail"));
		var button6 = new ColorButton.with_rgba (color);
		button6.color_set.connect (() => SETTINGS.set_string ("room-detail", button6.rgba.to_string ()));
		button6.margin_end = 10;
		grid.attach (button6, 1, 1, 1, 1);

		label = new Label ("Inactive");
		label.halign = Align.END;
		grid.attach (label, 2, 1, 1, 1);
		color = Gdk.RGBA ();
		color.parse (SETTINGS.get_string ("room-inactive"));
		var button7 = new ColorButton.with_rgba (color);
		button7.color_set.connect (() => SETTINGS.set_string ("room-inactive", button7.rgba.to_string ()));
		button7.margin_end = 10;
		grid.attach (button7, 3, 1, 1, 1);

		var font_box = new Box (Orientation.HORIZONTAL, 10);
		grid.attach (font_box, 0, 2, 6, 1);

		label = new Label ("Font");
		label.halign = Align.END;
		font_box.add (label);
		Gtk.FontButton font = new Gtk.FontButton.with_font (SETTINGS.get_string ("room-font"));
		font_box.add (font);
		font.use_font = true;
		font.set_title ("Room Font");
		SETTINGS.bind ("room-font", font, "font_name", SettingsBindFlags.SET);


		var room_check = new Gtk.CheckButton.with_label ("Hand drawn");
		font_box.add (room_check);
		SETTINGS.bind ("room-drawn", room_check, "active", SettingsBindFlags.DEFAULT);

		frame = new Gtk.Frame ("<b>Passage</b>");
		style_box.add (frame);
		(frame.label_widget as Gtk.Label).use_markup = true;
		frame.shadow_type = ShadowType.NONE;
		frame.margin = 10;
		box = new Box (Orientation.HORIZONTAL, 10);
		box.margin = 10;
		frame.add (box);

		label = new Label ("Line");
		box.add (label);
		color = Gdk.RGBA ();
		color.parse (SETTINGS.get_string ("passage-line"));
		var button8 = new ColorButton.with_rgba (color);
		button8.color_set.connect (() => SETTINGS.set_string ("passage-line", button8.rgba.to_string ()));
		box.add (button8);

		label = new Label ("Detail");
		box.add (label);
		color = Gdk.RGBA ();
		color.parse (SETTINGS.get_string ("passage-detail"));
		var button9 = new ColorButton.with_rgba (color);
		button9.color_set.connect (() => SETTINGS.set_string ("passage-detail", button9.rgba.to_string ()));
		box.add (button9);

		var passage_check = new Gtk.CheckButton.with_label ("Hand drawn");
		box.add (passage_check);
		SETTINGS.bind ("passage-drawn", passage_check, "active", SettingsBindFlags.DEFAULT);

		// Automapping
		title = new Gtk.Label ("Auto Mapping");
		var auto_box = new Box (Orientation.VERTICAL, 0);
		notebook.append_page (auto_box, title);

		frame = new Gtk.Frame ("<b>Patterns</b>");
		auto_box.add (frame);
		(frame.label_widget as Gtk.Label).use_markup = true;
		frame.shadow_type = ShadowType.NONE;
		frame.margin = 10;
		box = new Box (Orientation.VERTICAL, 10);
		box.margin = 10;
		frame.add (box);


		label = new Label ("The regular expression to processes transcript text in <b>verbose</b> mode.");
		label.use_markup = true;
		box.add (label);

		var verbose = new Entry ();
		SETTINGS.bind ("automap-regex-verbose", verbose.buffer, "text", SettingsBindFlags.DEFAULT);
		box.add (verbose);

		label = new Label ("The regular expression to processes transcript text in <b>terse</b> mode.");
		label.use_markup = true;
		box.add (label);

		var terse = new Entry ();
		SETTINGS.bind ("automap-regex-terse", terse.buffer, "text", SettingsBindFlags.DEFAULT);
		box.add (terse);
	}

	public override void response (int id)
	{
		destroy ();
	}
}