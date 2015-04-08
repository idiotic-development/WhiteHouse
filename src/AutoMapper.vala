public class WhiteHouse.AutoMapper : Object
{
	Room _position;
	public Room position
	{
		get {return _position;}
		set
		{
			if (_position != null)
				_position.highlighted = false;

			value.highlighted = true;

			_position = value;
		}
	}

	public bool verbose { get; set; default = true; }

	int64 pos = 0;
	uint64 last_modified;

	FileMonitor watch;
	Window window;
	Map map;

	public AutoMapper (Window window, Map map, File transcript, bool verbose, bool skip_to_end)
	{
		this.map = map;
		this.verbose = verbose;
		this.window = window;

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

			if (SETTINGS.get_boolean ("automap-polling"))
			{
				last_modified = transcript.query_info(FileAttribute.TIME_MODIFIED, 0)
									.get_attribute_uint64(FileAttribute.TIME_MODIFIED);
				GLib.Timeout.add (SETTINGS.get_int ("automap-rate"), () =>
				{
					uint64 time = transcript.query_info(FileAttribute.TIME_MODIFIED, 0)
									.get_attribute_uint64(FileAttribute.TIME_MODIFIED);
					if (time > last_modified)
					{
						read (transcript);
						last_modified = time;
					}

					return true;
				});
			} else
			{
				watch = transcript.monitor (FileMonitorFlags.NONE, null);
				watch.changed.connect ((src) => read (src));
			}
		}  catch (Error e)
		{
			stderr.puts (@"Error in AutoMapper.vala:Constructor - $(e.message)\n");
		}


	}

	private void read (File src)
	{
		stdout.puts ("Reading changes...\n");

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
			var regex_str = (verbose) ? SETTINGS.get_string ("automap-regex-verbose") : SETTINGS.get_string ("automap-regex-terse");
			var regex = new Regex (regex_str, RegexCompileFlags.MULTILINE, 0);

			MatchInfo info;
			if (regex.match (str, 0, out info))
			do
			{
				var name = info.fetch_named ("name");
				var desc = info.fetch_named ("desc");
				var cmd = " " + info.fetch_named ("cmd") + " ";

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

	public void guess_exits (Room room)
	{
		if (/\bnorth\b/.match (room.desc, 0, null) && room.north == null)
			room.north = map.new_passage (room, null);
		
		if (/\bnortheast\b/.match (room.desc, 0, null) && room.northeast == null)
			room.northeast = map.new_passage (room, null);
		
		if (/\beast\b/.match (room.desc, 0, null) && room.east == null)
			room.east = map.new_passage (room, null);
		
		if (/\bsoutheast\b/.match (room.desc, 0, null) && room.southeast == null)
			room.southeast = map.new_passage (room, null);
		
		if (/\bsouth\b/.match (room.desc, 0, null) && room.south == null)
			room.south = map.new_passage (room, null);
		
		if (/\bsouthwest\b/.match (room.desc, 0, null) && room.southwest == null)
			room.southwest = map.new_passage (room, null);
		
		if (/\bwest\b/.match (room.desc, 0, null) && room.west == null)
			room.west = map.new_passage (room, null);
		
		if (/\bnorthwest\b/.match (room.desc, 0, null) && room.northwest == null)
			room.northwest = map.new_passage (room, null);

		if (/\bup\b/.match (room.desc, 0, null) && room.up == null)
		{
			room.up = map.new_passage (room, null);
			room.up.z += 0.5;
		}

		if (/\bdown\b/.match (room.desc, 0, null) && room.down == null)
		{
			room.down = map.new_passage (room, null);
			room.down.z -= 0.5;
		}
	}

	public void go (string direction, string name, string? desc)
	{
		Room room = null;

		foreach (var drawable in map.drawable_list)
			if (drawable is Room && (drawable as Room).name == name)
				if ((drawable as Room).desc == desc || !verbose)
					room = drawable as Room;

		if (room == null)
		{
			room = map.new_room (name, desc);
			if (position != null && direction != "")
				map.connect_rooms (position, room, direction);

			guess_exits (room);
		} else if (position != null && direction != "")
		{
			var val = GLib.Value (typeof(Passage));
			position.get_property (direction, ref val);
			var p_val = val as Passage;
			if (p_val == null)
				map.connect_rooms (position, room, direction);
			else if (p_val.start != room && p_val.end != room)
				map.connect_rooms (position, room, direction);
		}
		
		position = room;
		window.center_room (position);

		map.queue_draw ();
	}
}