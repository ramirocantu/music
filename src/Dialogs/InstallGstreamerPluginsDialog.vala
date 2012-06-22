/*-
 * Copyright (c) 2011-2012       Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originally Written by Scott Ringwelski for BeatBox Music Player
 * BeatBox Music Player: http://www.launchpad.net/beat-box
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

using Gtk;
using Gee;

public class BeatBox.InstallGstreamerPluginsDialog : Window {
	LibraryManager lm;
	LibraryWindow lw;
	Gst.Message message;
	string detail;
	
	private VBox content;
	private HBox padding;
	
	Button installPlugin;
	Button doNothing;
	
	public InstallGstreamerPluginsDialog(LibraryManager lm, LibraryWindow lw, Gst.Message message) {
		this.lm = lm;
		this.lw = lw;
		this.message = message;
		this.detail = Gst.missing_plugin_message_get_description(message);
		
		// set the size based on saved gconf settings
		//this.window_position = WindowPosition.CENTER;
		this.type_hint = Gdk.WindowTypeHint.DIALOG;
		this.set_modal(true);
		this.set_transient_for(lw);
		this.destroy_with_parent = true;
		
		set_default_size(475, -1);
		resizable = false;
		
		content = new VBox(false, 10);
		padding = new HBox(false, 20);
		
		// initialize controls
		Image warning = new Image.from_stock(Gtk.Stock.DIALOG_ERROR, Gtk.IconSize.DIALOG);
		Label title = new Label("");
		Label info = new Label("");
		installPlugin = new Button.with_label(_("Install Plugin"));
		doNothing = new Button.with_label(_("Do Nothing"));
		
		// pretty up labels
		title.xalign = 0.0f;
		title.set_markup("<span weight=\"bold\" size=\"larger\">" + String.escape (_("Required GStreamer plugin not installed")) + "</span>");
		info.xalign = 0.0f;
		info.set_line_wrap(true);
		info.set_markup(_("The plugin for media type %s is not installed.\nWhat would you like to do?").printf ("<b>" + String.escape (detail) + "</b>"));

		
		/* set up controls layout */
		HBox information = new HBox(false, 0);
		VBox information_text = new VBox(false, 0);
		information.pack_start(warning, false, false, 10);
		information_text.pack_start(title, false, true, 10);
		information_text.pack_start(info, false, true, 0);
		information.pack_start(information_text, true, true, 10);
		
		HButtonBox bottomButtons = new HButtonBox();
		bottomButtons.set_layout(ButtonBoxStyle.END);
		bottomButtons.pack_end(installPlugin, false, false, 0);
		bottomButtons.pack_end(doNothing, false, false, 10);
		bottomButtons.set_spacing(10);
		
		content.pack_start(information, false, true, 0);
		content.pack_start(bottomButtons, false, true, 10);
		
		padding.pack_start(content, true, true, 10);
		
		installPlugin.clicked.connect(installPluginClicked);
		doNothing.clicked.connect( () => { this.destroy(); });
		
		add(padding);
		show_all();
	}
	
	public void installPluginClicked() {
		var installer = Gst.missing_plugin_message_get_installer_detail(message);
		var context = new Gst.InstallPluginsContext();
			
		Gst.install_plugins_async({installer}, context, (Gst.InstallPluginsResultFunc)install_plugins_finished);
		
		this.hide();
	}

	public void install_plugins_finished(Gst.InstallPluginsReturn result) {
		stdout.printf ("Install of plugins finished.. updating registry");
		Gst.update_registry();
	}
}
