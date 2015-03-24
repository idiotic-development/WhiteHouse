public interface WhiteHouse.Drawable : GLib.Object
{
	public abstract double z { get; set; }
	public abstract void delete ();
	public abstract bool contains (double x, double y);
	public abstract void mouse_down (double x, double y, int b);
	public abstract void mouse_up (double x, double y, int b);
	public abstract void mouse_move (double x, double y);
	public abstract void mouse_enter ();
	public abstract void mouse_leave ();
	public abstract void draw (Cairo.Context ctx, double scale);
	public abstract void serialize (Json.Builder builder);
}