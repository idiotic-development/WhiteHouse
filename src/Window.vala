using Gtk;

namespace WhiteHouse
{
	public static GLib.Settings SETTINGS;

	public class Window : Gtk.Window
	{
		public static WhiteHouse.Window WINDOW;

		new Map map;
		ScrolledWindow scrolled;
		MenuBar bar;

		public Window ()
		{
			WINDOW = this;

			SETTINGS = new GLib.Settings ("com.idioticdev.whitehouse");

			set_icon_name ("white-house");

			title = "White House";

			maximize ();
			var box = new Box (Orientation.VERTICAL, 0);
			add (box);
			var layout = new Overlay ();
			
			box.pack_end (layout, true, true);
			scrolled = new Gtk.ScrolledWindow (null, null);
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
			scrolled.add_with_viewport (map);
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
			up.clicked.connect (() => map.z_level += 1);
			up.margin = 20;
			up.valign = Align.END;
			up.halign = Align.START;

			Button down = new Button.with_label ("\u2193");
			layout.add_overlay (down);
			down.clicked.connect (() => map.z_level -= 1);
			down.margin = 20;
			down.margin_left = 60;
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

			bar = new MenuBar (this, map, slider, scrolled);
			box.pack_end (bar, false, false);
		}

		public override bool delete_event (Gdk.EventAny event)
		{
			if (map.drawable_list.size == 0)
			{
				Gtk.main_quit ();
				return false;
			}

			var msg = new Gtk.MessageDialog (this, Gtk.DialogFlags.MODAL,
												Gtk.MessageType.QUESTION,
												Gtk.ButtonsType.NONE,
												"Save or discard changes?");
			msg.add_button ("Save", Gtk.ResponseType.YES);
			msg.add_button ("Discard", Gtk.ResponseType.NO);
			msg.add_button ("Cancel", Gtk.ResponseType.CANCEL);
			msg.response.connect ((id) =>
			{
				if (id == Gtk.ResponseType.YES)
					bar.save_map ();

				if (id != Gtk.ResponseType.CANCEL)
					Gtk.main_quit ();
			});
			msg.run ();
			msg.destroy();
			return true;
		}

		public void center_room (Room room)
		{
			map.z_level = (int)room.z;
			var x = room.x;
			var y = room.y;
			map.map_to_viewport (ref x, ref y);

			scrolled.hadjustment.value = x;			
			scrolled.vadjustment.value = y;			
		}

		public void open (File map_file)
		{
			try
			{
				var path = map_file.get_parse_name ();
				RecentManager.get_default ().add_item (path);
				var parser = new Json.Parser ();
				try {
					parser.load_from_file (path);
					map.deserialize (parser.get_root ());
				} catch (Error e)
				{
					var msg = new Gtk.MessageDialog (this,
						Gtk.DialogFlags.MODAL,
						Gtk.MessageType.ERROR,
						Gtk.ButtonsType.CLOSE,
						"Can not open %s. Are you sure it's White House map?", path);
					msg.run ();
					msg.destroy ();
				}
			} catch (Error e)
			{
				stderr.puts (@"Error in Window.vala:open - $(e.message)\n");
			}
		}

		static int main (string[] args)
		{
			Gtk.init (ref args);

			Window window = new Window ();
			window.show_all ();
			if (args.length > 1)
			{
				File file = File.new_for_commandline_arg (args[1]);
				if (file.query_exists ())
					window.open (file);
			}

			Gtk.main ();

			return 0;
		}
	}
}