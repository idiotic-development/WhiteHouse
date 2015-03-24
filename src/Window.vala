using Gtk;

public class WhiteHouse.Window : Gtk.Window
{
	public static GLib.Settings SETTINGS;

	new Map map;

	public Window ()
	{
		SETTINGS = new GLib.Settings ("com.idioticdev.whitehouse");
		// set_default_icon_from_file ("white-house.svg");

		title = "White House";
		destroy.connect (main_quit);
		window_position = Gtk.WindowPosition.CENTER;
		var box = new Box (Orientation.VERTICAL, 0);
		add (box);
		var layout = new Overlay ();
		
		box.add (layout);
		ScrolledWindow scrolled = new Gtk.ScrolledWindow (null, null);
		layout.add (scrolled);

		map = new Map ();

		var last_x = 0.0;
		var last_y = 0.0;
		var last_time = 0.0;
		motion_notify_event.connect ((e) =>
		{
			if ((e.state & Gdk.ModifierType.BUTTON1_MASK) != Gdk.ModifierType.BUTTON1_MASK
				|| map.drag_target != null)
				return false;

			if (e.time - last_time > 50)
			{
				last_x = e.x_root;
				last_y = e.y_root;
			}

			scrolled.vadjustment.value += (last_y - e.y_root);
			scrolled.hadjustment.value += (last_x - e.x_root);

			last_x = e.x_root;
			last_y = e.y_root;
			last_time = e.time;

			return false;
		});

		var v_upper = 0.0;
		var h_upper = 0.0;
		scrolled.vadjustment.notify["upper"].connect ((obj, prop) =>
		{
			((Adjustment)obj).value += (((Adjustment)obj).upper - v_upper) / 2;
			v_upper = ((Adjustment)obj).upper;
		});
		scrolled.hadjustment.notify["upper"].connect ((obj, prop) =>
		{
			((Adjustment)obj).value += (((Adjustment)obj).upper - h_upper) / 2;
			h_upper = ((Adjustment)obj).upper;
		});
		scrolled.add (map);
		layout.get_child_position.connect ((widget, out allocation) =>
		{
			if (widget is Scale)
			{
				int natural;
				widget.get_preferred_height (null, out natural);
				layout.get_allocation (out allocation);
				allocation.x = 100;
				allocation.y = allocation.height - natural - 25;
				allocation.width = 150;
				allocation.height = natural;
				return true;
			}

			return false;
		});
		var slider = new Scale.with_range (Orientation.HORIZONTAL, 20, 100, 5);
		layout.add_overlay (slider);
		slider.set_value (Map.GRID_SIZE);
		slider.value_changed.connect (() =>
		{
			Map.GRID_SIZE = (int)slider.get_value ();
			Allocation size;
			layout.get_allocation (out size);
			if (Map.GRID_SIZE*map.width < size.width)
				map.width = size.width/Map.GRID_SIZE;

			if (Map.GRID_SIZE*map.height < size.height)
				map.height = size.height/Map.GRID_SIZE;

			map.queue_draw ();
			map.queue_resize ();
		});
		slider.draw_value = false;
		slider.has_origin = false;
		slider.valign = Align.END;

		Button up = new Button.with_label ("\u2191");
		layout.add_overlay (up);
		up.clicked.connect (up_a_level);
		up.margin = 20;
		up.valign = Align.END;
		up.halign = Align.START;

		Button down = new Button.with_label ("\u2193");
		layout.add_overlay (down);
		down.clicked.connect (down_a_level);
		down.margin = 20;
		down.margin_start = 60;
		down.valign = Align.END;
		down.halign = Align.START;

		var label = new Label (null);
		layout.add_overlay (label);
		label.margin = 10;
		label.valign = Align.END;
		label.halign = Align.END;
		map.motion_notify_event.connect ((e) =>
		{
			var x = e.x;
			var y = e.y;
			map.viewport_to_map (ref x, ref y);
			label.label = "Level: %- 3d   X: %- 3.0f   Y: %- 3.0f".printf (map.z_level, x, y);

			return false;
		});

		set_default_size (960, 800);

		var accel_group = new Gtk.AccelGroup();
		add_accel_group(accel_group);

		var bar = new Gtk.MenuBar ();
		box.pack_start (bar, false, false);

		var item = new Gtk.MenuItem.with_mnemonic ("_File");
		bar.add (item);

		var menu = new Gtk.Menu ();
		item.set_submenu (menu);

		item = new Gtk.MenuItem.with_label ("New");
		item.add_accelerator("activate", accel_group, 'n', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
		item.activate.connect (new_map);
		menu.add (item);

		item = new Gtk.SeparatorMenuItem ();
		menu.add (item);

		item = new Gtk.MenuItem.with_label ("Open...");
		item.add_accelerator("activate", accel_group, 'o', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
		item.activate.connect (open_map);
		menu.add (item);

		item = new Gtk.MenuItem.with_label ("Open Recent");
		var rc = new RecentChooserMenu ();
		var filter = new RecentFilter ();
		filter.add_application ("White_House");
		rc.filter = filter;
		item.set_submenu (rc);
		menu.add (item);

		item = new Gtk.SeparatorMenuItem ();
		menu.add (item);

		item = new Gtk.MenuItem.with_label ("Save");
		item.add_accelerator("activate", accel_group, 's', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
		item.activate.connect (save_map);
		menu.add (item);

		item = new Gtk.MenuItem.with_label ("Save As...");
		item.add_accelerator("activate", accel_group, 's', Gdk.ModifierType.CONTROL_MASK|Gdk.ModifierType.SHIFT_MASK, AccelFlags.VISIBLE);
		item.activate.connect (save_map_as);
		menu.add (item);

		item = new Gtk.SeparatorMenuItem ();
		menu.add (item);

		item = new Gtk.MenuItem.with_label ("Exit");
		item.add_accelerator("activate", accel_group, 'q', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
		item.activate.connect (Gtk.main_quit);
		menu.add (item);

		item = new Gtk.MenuItem.with_mnemonic ("_Edit");
		bar.add (item);

		menu = new Gtk.Menu ();
		item.set_submenu (menu);

		item = new Gtk.MenuItem.with_label ("Add a Room");
		item.add_accelerator("activate", accel_group, 'r', 0, Gtk.AccelFlags.VISIBLE);
		item.activate.connect (new_room);
		menu.add (item);

		item = new Gtk.MenuItem.with_label ("Add a Room...");
		menu.add (item);

		var room_menu = new Gtk.Menu ();
		item.set_submenu (room_menu);

		Gtk.MenuItem[] room_items = new Gtk.MenuItem[10];

		room_items[0] = new Gtk.MenuItem.with_label ("To the North");
		room_items[0].add_accelerator("activate", accel_group, 'w', 0, Gtk.AccelFlags.VISIBLE);
		room_items[0].activate.connect (() => map.move_selection ("north"));
		room_menu.add (room_items[0]);

		room_items[1] = new Gtk.MenuItem.with_label ("To the Northeast");
		room_items[1].add_accelerator("activate", accel_group, 'e', 0, Gtk.AccelFlags.VISIBLE);
		room_items[1].activate.connect (() => map.move_selection ("northeast"));
		room_menu.add (room_items[1]);

		room_items[2] = new Gtk.MenuItem.with_label ("To the East");
		room_items[2].add_accelerator("activate", accel_group, 'd', 0, Gtk.AccelFlags.VISIBLE);
		room_items[2].activate.connect (() => map.move_selection ("east"));
		room_menu.add (room_items[2]);

		room_items[3] = new Gtk.MenuItem.with_label ("To the Southeast");
		room_items[3].add_accelerator("activate", accel_group, 'c', 0, Gtk.AccelFlags.VISIBLE);
		room_items[3].activate.connect (() => map.move_selection ("southeast"));
		room_menu.add (room_items[3]);

		room_items[4] = new Gtk.MenuItem.with_label ("To the South");
		room_items[4].add_accelerator("activate", accel_group, 'x', 0, Gtk.AccelFlags.VISIBLE);
		room_items[4].activate.connect (() => map.move_selection ("south"));
		room_menu.add (room_items[4]);

		room_items[5] = new Gtk.MenuItem.with_label ("To the Southwest");
		room_items[5].add_accelerator("activate", accel_group, 'z', 0, Gtk.AccelFlags.VISIBLE);
		room_items[5].activate.connect (() => map.move_selection ("southwest"));
		room_menu.add (room_items[5]);

		room_items[6] = new Gtk.MenuItem.with_label ("To the West");
		room_items[6].add_accelerator("activate", accel_group, 'a', 0, Gtk.AccelFlags.VISIBLE);
		room_items[6].activate.connect (() => map.move_selection ("west"));
		room_menu.add (room_items[6]);

		room_items[7] = new Gtk.MenuItem.with_label ("To the Northwest");
		room_items[7].add_accelerator("activate", accel_group, 'q', 0, Gtk.AccelFlags.VISIBLE);
		room_items[7].activate.connect (() => map.move_selection ("northwest"));
		room_menu.add (room_items[7]);

		room_items[8] = new Gtk.MenuItem.with_label ("Above");
		room_items[8].add_accelerator("activate", accel_group, 'f', 0, Gtk.AccelFlags.VISIBLE);
		room_items[8].activate.connect (() => map.move_selection ("up"));
		room_menu.add (room_items[8]);

		room_items[9] = new Gtk.MenuItem.with_label ("Below");
		room_items[9].add_accelerator("activate", accel_group, 'v', 0, Gtk.AccelFlags.VISIBLE);
		room_items[9].activate.connect (() => map.move_selection ("down"));
		room_menu.add (room_items[9]);

		item = new Gtk.SeparatorMenuItem ();
		menu.add (item);

		var delete_item = new Gtk.MenuItem.with_label ("Delete");
		delete_item.add_accelerator("activate", accel_group, Gdk.Key.Delete, 0, Gtk.AccelFlags.VISIBLE);
		delete_item.activate.connect (delete_room);
		menu.add (delete_item);

		var edit_item = new Gtk.MenuItem.with_label ("Edit");
		edit_item.add_accelerator("activate", accel_group, Gdk.Key.Return, 0, Gtk.AccelFlags.VISIBLE);
		edit_item.activate.connect (edit_room);
		menu.add (edit_item);

		item = new Gtk.SeparatorMenuItem ();
		menu.add (item);

		item = new Gtk.MenuItem.with_label ("Select All");
		item.add_accelerator("activate", accel_group, 'a', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
		item.activate.connect (() =>
		{
			foreach (var drawable in map.drawable_list)
				if (drawable is Room)
					map.add_selection (drawable as Room);
		});
		menu.add (item);

		item = new Gtk.MenuItem.with_label ("Select None");
		item.add_accelerator("activate", accel_group, Gdk.Key.Escape, 0, Gtk.AccelFlags.VISIBLE);
		item.activate.connect (map.clear_selection);
		menu.add (item);

		foreach (var room_item in room_items)
			room_item.sensitive = false;

		delete_item.sensitive = false;
		edit_item.sensitive = false;

		map.selection_changed.connect (() =>
		{
			Room[] selection = map.get_selection ();

			if (selection.length < 1)
			{
				foreach (var room_item in room_items)
					room_item.sensitive = false;

				delete_item.sensitive = false;
				edit_item.sensitive = false;
			} else if (selection.length == 1)
			{
				foreach (var room_item in room_items)
					room_item.sensitive = true;

				delete_item.sensitive = true;
				edit_item.sensitive = true;
			} else
			{
				foreach (var room_item in room_items)
					item.sensitive = false;

				delete_item.sensitive = true;
				edit_item.sensitive = false;
			}

		});

		item = new Gtk.SeparatorMenuItem ();
		menu.add (item);

		item = new Gtk.MenuItem.with_label ("Preferences");
		item.add_accelerator("activate", accel_group, 'p', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
		item.activate.connect (() => new Preferences ().show_all ());
		menu.add (item);

		item = new Gtk.MenuItem.with_mnemonic ("_Tools");
		bar.add (item);

		menu = new Gtk.Menu ();
		item.set_submenu (menu);

		var automaping = false;
		AutoMapper mapper = null;		
		var pos_item = new Gtk.MenuItem.with_label ("Set Position");
		pos_item.activate.connect (() =>
		{
			var selection = map.get_selection ();
			if (selection.length == 1)
				mapper.position = selection[0];
		});

		var auto_item = new Gtk.MenuItem.with_label ("Start Automaping...");
		auto_item.add_accelerator("activate", accel_group, 'o', Gdk.ModifierType.CONTROL_MASK|Gdk.ModifierType.SHIFT_MASK, Gtk.AccelFlags.VISIBLE);
		auto_item.activate.connect (() =>
		{
			if (automaping)
			{
				Gtk.main_quit ();
				automaping = false;
				auto_item.label = "Start Automaping...";
				pos_item.sensitive = false;
			} else
			{
				var dialog = new AutomapDialog (this);
				dialog.show_all ();
				if (dialog.run () == ResponseType.ACCEPT)
				{
					mapper = dialog.mapper;
					automaping = true;
					auto_item.label = "Stop Automaping";
					pos_item.sensitive = true;
				}
				dialog.destroy ();
			}
		});
		menu.add (auto_item);
		menu.add (pos_item);

		item = new Gtk.MenuItem.with_mnemonic ("_View");
		bar.add (item);

		menu = new Gtk.Menu ();
		item.set_submenu (menu);

		item = new Gtk.MenuItem.with_label ("Zoom In");
		item.add_accelerator("activate", accel_group, '+', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
		item.activate.connect (() => slider.adjustment.value += slider.adjustment.step_increment);
		menu.add (item);

		item = new Gtk.MenuItem.with_label ("Zoom Out");
		item.add_accelerator("activate", accel_group, '-', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
		item.activate.connect (() => slider.adjustment.value -= slider.adjustment.step_increment);
		menu.add (item);

		item = new Gtk.MenuItem.with_label ("Reset");
		item.add_accelerator("activate", accel_group, Gdk.Key.Home, 0, Gtk.AccelFlags.VISIBLE);
		item.activate.connect (() => 
		{
			slider.adjustment.value = 30;
			map.z_level = 0;
			Allocation size;
			layout.get_allocation (out size);
			scrolled.hadjustment.value = (scrolled.hadjustment.upper-size.width)/2;
			scrolled.vadjustment.value = (scrolled.vadjustment.upper-size.height)/2;
		});
		menu.add (item);

		item = new Gtk.SeparatorMenuItem ();
		menu.add (item);

		var grid_item = new Gtk.CheckMenuItem.with_label ("Show Grid");
		grid_item.active = true;
		menu.add (grid_item);
		grid_item.toggled.connect (() => map.show_grid = grid_item.active);

		item = new Gtk.MenuItem.with_label ("Down a level");
		item.add_accelerator("activate", accel_group, '-', Gdk.ModifierType.SHIFT_MASK, Gtk.AccelFlags.VISIBLE);
		item.activate.connect (down_a_level);
		menu.add (item);

		item = new Gtk.MenuItem.with_label ("Up a level");
		item.add_accelerator("activate", accel_group, '+', Gdk.ModifierType.SHIFT_MASK, Gtk.AccelFlags.VISIBLE);
		item.activate.connect (up_a_level);
		menu.add (item);
	}

	/* File menu */

	private void open_map ()
	{
		var dialog = new FileChooserDialog ("Open Map", this, FileChooserAction.OPEN,
									"Cancel", ResponseType.CANCEL,
									"Open", ResponseType.ACCEPT,  null);

		if (dialog.run () == ResponseType.ACCEPT)
			try
			{
				map_file = dialog.get_file ();
				var path = map_file.get_parse_name ();
				RecentManager.get_default ().add_item (path);
				var parser = new Json.Parser ();
				parser.load_from_file (path);
				map.deserialize (parser.get_root ());
			} catch (Error e)
			{
				stderr.puts (@"Error in Window.vala:open_map - $(e.message)\n");
			}

		dialog.destroy ();
	}

	private void new_map ()
	{
		if (map.drawable_list.size < 1)
			return;

		var msg = new Gtk.MessageDialog (this, Gtk.DialogFlags.MODAL,
												Gtk.MessageType.QUESTION,
												Gtk.ButtonsType.NONE,
												"Save or discard changes?");
		msg.add_button ("Save", Gtk.ResponseType.YES);
		msg.add_button ("Discard", Gtk.ResponseType.NO);
		msg.add_button ("Cancel", Gtk.ResponseType.CANCEL);
		msg.response.connect ((id) =>
		{
			switch (id)
			{
				case Gtk.ResponseType.YES:
					save_map ();
					map.drawable_list = new Gee.ArrayList<Drawable> ();
					map_file = null;
					break;
				case Gtk.ResponseType.NO:
					map_file = null;
					map.drawable_list = new Gee.ArrayList<Drawable> ();
					break;
			}

			msg.destroy();
		});
		msg.show ();
	}

	File map_file = null;
	private void save_map ()
	{
		if (map_file == null)
		{
			var dialog = new FileChooserDialog ("Save Map", this, FileChooserAction.SAVE,
												"Cancel", ResponseType.CANCEL,
												"Save", ResponseType.ACCEPT,  null);
			dialog.do_overwrite_confirmation = true;

			if (dialog.run () == ResponseType.ACCEPT)
				map_file = dialog.get_file ();

			RecentManager.get_default ().add_item (map_file.get_parse_name ());

			dialog.destroy ();
		}

		if (map_file == null)
			return;

		try
		{
			var os = map_file.replace (null, true, FileCreateFlags.NONE);
			var generator = new Json.Generator ();
			generator.set_root (map.serialize ());
			size_t written;
			os.write_all (generator.to_data (null).data, out written);
			os.close ();

			title = "White House - "+map_file.get_parse_name ();
		} catch (Error e)
		{
			stderr.puts (@"Error in Window.vala:save_map - $(e.message)\n");
		}
	}

	private void save_map_as ()
	{
		var dialog = new FileChooserDialog ("Save Map", this, FileChooserAction.SAVE,
											"Cancel", ResponseType.CANCEL,
											"Save", ResponseType.ACCEPT,  null);
		dialog.do_overwrite_confirmation = true;

		if (dialog.run () == ResponseType.ACCEPT)
			try
			{
				var file = dialog.get_file ();
				RecentManager.get_default ().add_item (file.get_parse_name ());
				var os = file.replace (null, true, FileCreateFlags.NONE);
				var generator = new Json.Generator ();
				generator.set_root (map.serialize ());
				size_t written;
				os.write_all (generator.to_data (null).data, out written);
				os.close ();
			} catch (Error e)
			{
				stderr.puts (@"Error in Window.vala:save_map - $(e.message)\n");
			}

		dialog.destroy ();
	}

	private void up_a_level ()
	{
		map.z_level += 1;
		map.queue_draw ();
	}

	private void down_a_level ()
	{
		map.z_level -= 1;
		map.queue_draw ();
	}

	/* Edit menu */

	private void new_room ()
	{
		var room = map.room_dialog (null);
		if (room != null)
		{
			room.x = 0;
			room.y = 0;
			room.selected = true;
		}
	}

	private void edit_room ()
	{
		map.room_dialog (map.get_selection ()[0]);
	}

	private void delete_room ()
	{
		foreach (var room in map.get_selection ())
			room.delete ();

		map.queue_draw ();
	}

	static int main (string[] args) {
		Gtk.init (ref args);

		new Window ().show_all ();

		Gtk.main ();

		return 0;
	}
}