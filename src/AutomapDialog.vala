using Gtk;

public class WhiteHouse.AutomapDialog : Dialog
{
	public AutoMapper mapper { get; private set; }
	FileChooserButton chooser;
	bool verbose = true;
	bool skip_to_end = true;

	public AutomapDialog (Window? parent)
	{
		set_default_size (350, -1);
		set_modal (true);

		var vbox = get_content_area () as Box;
		vbox.spacing = 10;
		vbox.margin = 20;

		var label = new Label ("White House can draw a map for you while you play by reading a transcript file of your game.");
		label.wrap = true;
		vbox.add (label);

		chooser = new FileChooserButton ("Transcript", FileChooserAction.OPEN);
		vbox.pack_start (chooser, false, false, 0);

		var check = new CheckButton.with_label ("Assume game is in VERBOSE mode.");
		vbox.pack_start (check, false, false, 0);
		check.active = verbose;
		check.toggled.connect (() => verbose = check.active);

		var end = new CheckButton.with_label ("Skip to end of file.");
		vbox.pack_start (end, false, false, 0);
		end.active = skip_to_end;
		end.toggled.connect (() => skip_to_end = end.active);

		add_button ("Start", ResponseType.ACCEPT);
		add_button ("Cancel", ResponseType.CANCEL);
	}

	public override void response (int id)
	{
		switch (id)
		{
			case ResponseType.ACCEPT:
				mapper = new AutoMapper (chooser.get_file (), verbose, skip_to_end);
				break;
		}
	}
}