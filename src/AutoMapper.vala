public class WhiteHouse.AutoMapper : Object
{
	Room _position;
	public Room position
	{
		get {return _position;}
		set
		{
			value.highlighted = true;
			if (_position != null)
				_position.highlighted = false;

			_position = value;
		}
	}

	public bool verbose { get; set; default = true; }

	int64 pos = 0;

	public AutoMapper (File transcript, bool verbose, bool skip_to_end)
	{
		this.verbose = verbose;

		try
		{
			if (skip_to_end)
			{
				// Find end of file
				var is1 = new BufferedInputStream (transcript.read ());
				uint8 buffer[100];
				while (is1.read (buffer) > 0)
					continue;

				pos = is1.tell ();
			} else
			{
				pos = 0;
				read (transcript);
			}
		}  catch (Error e)
		{
			stderr.puts (@"Error in AutoMapper.vala:Constructor - $(e.message)\n");
		}


		// Setup watcher
		new Thread<int> ("Watcher", () =>
		{
			try
			{
				var watch = transcript.monitor (FileMonitorFlags.NONE, null);
				watch.changed.connect ((src) => read (src));
			}  catch (Error e)
			{
				stderr.puts (@"Error in AutoMapper.vala:Watcher thread - $(e.message)\n");
			}

			Gtk.main ();
			return 0;
		});
	}

	private void read (File src)
	{
		try
		{
			// Read changes
			var bis = new BufferedInputStream (src.read ());
			bis.seek (pos, SeekType.SET);

			var builder = new StringBuilder ();
			ssize_t size;

			uint8 buffer[100];
			while ((size = bis.read (buffer)) > 0)
				builder.append_len ((string) buffer, size);

			pos = bis.tell ();

			// Process changes
			process (builder.str);

			bis.close ();
		}  catch (Error e)
		{
			stderr.puts (@"Error in AutoMapper.vala:read - $(e.message)\n");
		}
	}

	private void process (string text)
	{

		var str = text.chug();
		str = (str[str.length-1] == '>') ? " >" + text : text;
		
		try
		{
			var regex_str = (verbose) ? Window.SETTINGS.get_string ("automap-regex-verbose") : Window.SETTINGS.get_string ("automap-regex-terse");
			var regex = new Regex (regex_str, RegexCompileFlags.MULTILINE, 0);

			MatchInfo info;
			if (regex.match (str, 0, out info))
			do
			{
				var name = info.fetch_named ("name");
				var desc = info.fetch_named ("desc");
				var cmd = " " + info.fetch_named ("cmd") + " ";

				// stdout.puts (name+" "+desc+"\n");

				if (name == null || (desc == null && verbose))
					continue;

				if (cmd.index_of (" north ") != -1 || cmd.index_of (" n ") != -1)
					cmd = "north";
				else if (cmd.index_of (" northeast ") != -1 || cmd.index_of (" ne ") != -1)
					cmd = "northeast";
				else if (cmd.index_of (" east ") != -1 || cmd.index_of (" e ") != -1)
					cmd = "east";
				else if (cmd.index_of (" southeast ") != -1 || cmd.index_of (" se ") != -1)
					cmd = "southeast";
				else if (cmd.index_of (" south ") != -1 || cmd.index_of (" s ") != -1)
					cmd = "south";
				else if (cmd.index_of (" southwest ") != -1 || cmd.index_of (" sw ") != -1)
					cmd = "southwest";
				else if (cmd.index_of (" west ") != -1 || cmd.index_of (" w ") != -1)
					cmd = "west";
				else if (cmd.index_of (" northwest ") != -1 || cmd.index_of (" nw ") != -1)
					cmd = "northwest";
				else if (cmd.index_of (" up ") != -1 || cmd.index_of (" u ") != -1)
					cmd = "up";
				else if (cmd.index_of (" down ") != -1 || cmd.index_of (" d ") != -1)
					cmd = "down";
				else
					cmd = "";
				
				go (cmd, name, desc);
			} while (info.next ());
		}  catch (RegexError e)
		{
			stderr.puts (@"RegexError in AutoMapper.vala:process - $(e.message)\n");
		}
	}

	public void go (string direction, string name, string? desc)
	{
		Room room = null;
		foreach (var drawable in Map.map.drawable_list)
			if (drawable is Room && (drawable as Room).name == name)
				if ((drawable as Room).desc == desc || !verbose)
					room = drawable as Room;

		if (room == null)
		{
			room = Map.map.new_room (name, desc);
			if (position != null && direction != "")
				Map.map.connect_rooms (position, room, direction);
		} else if (position != null && direction != "")
		{
			var val = GLib.Value (typeof(Passage));
			position.get_property (direction, ref val);
			var p_val = val as Passage;
			if (p_val == null)
				Map.map.connect_rooms (position, room, direction);
			else if (p_val.start != room && p_val.end != room)
				Map.map.connect_rooms (position, room, direction);
		}
		
		position = room;

		Map.map.queue_draw ();
	}
}