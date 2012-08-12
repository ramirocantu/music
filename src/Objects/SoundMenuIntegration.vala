/*-Original Authors: Andreas Obergrusberger
 *                   Jörn Magens
 *
 * Edited by: Scott Ringwelski
 * 
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

#if HAVE_INDICATE
using Indicate;

public class Noise.SoundMenuIntegration : GLib.Object {
	private LibraryWindow library_window;

	private uint watch;
	private Indicate.Server server;
	
	public SoundMenuIntegration(LibraryWindow library_window) {
		this.library_window = library_window;
	}
	
	public void initialize() {
		watch = Bus.watch_name(BusType.SESSION,
		                      "org.ayatana.indicator.sound",
		                      BusNameWatcherFlags.NONE,
		                      on_name_appeared,
		                      on_name_vanished);
	}

	private void on_name_appeared(DBusConnection conn, string name) {
		/* set up the server to connect to music.noise dbus */
		server = Indicate.Server.ref_default();
		server.set ("type", "music" + "." + App.instance.get_id ());
		var desktop_file_path = GLib.Path.build_filename (Build.DATADIR, "applications",
		                                                  App.instance.get_desktop_file_name ());
		server.set_desktop_file (desktop_file_path);
		server.show ();
	}

	private void on_name_vanished(DBusConnection conn, string name) {
		if(server != null)
			server.hide();
	}
}
#endif
