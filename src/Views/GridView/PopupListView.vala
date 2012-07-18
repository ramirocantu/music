// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012 Noise Developers (http://launchpad.net/noise)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Victor Eduardo <victoreduardm@gmail.com>
 *              Scott Ringwelski <sgringwe@mtu.edu>
 */

using Gee;
using Gtk;

#if USE_GRANITE_DECORATED_WINDOW
public class BeatBox.PopupListView : Granite.Widgets.DecoratedWindow {
#else
public class BeatBox.PopupListView : Window {
#endif

	public const int MIN_SIZE = 400;

	LibraryManager lm;
	ViewWrapper view_wrapper;

	Gtk.Label album_label;
	Gtk.Label artist_label;
	Granite.Widgets.Rating rating;

	GenericList list_view;

	Gee.Collection<Media> media_list;

	public PopupListView (GridView grid_view) {
#if USE_GRANITE_DECORATED_WINDOW
        base ("", "album-list-view", "album-list-view");
#endif

		this.view_wrapper = grid_view.parent_view_wrapper;
		this.lm = view_wrapper.lm;

		set_transient_for (lm.lw);
		destroy_with_parent = true;
		set_skip_taskbar_hint (true);
		set_resizable(false);

#if !USE_GRANITE_DECORATED_WINDOW
		window_position = Gtk.WindowPosition.CENTER_ON_PARENT;

		// window stuff
		set_decorated(false);
		set_has_resize_grip(false);

		// close button
		var close = new Gtk.Button ();
        get_style_context ().add_class ("album-list-view");
		close.get_style_context().add_class("close-button");
		close.set_image (Icons.render_image ("window-close-symbolic", Gtk.IconSize.MENU));
		close.hexpand = close.vexpand = false;
		close.halign = Gtk.Align.START;
		close.set_relief(Gtk.ReliefStyle.NONE);
		close.clicked.connect( () =>  { this.hide(); });
#else
        // Don't destroy the window
		this.delete_event.connect (hide_on_delete);

        // Hide titlebar (we want to set a title, but not showing it!)
        this.show_title = false;
#endif
		// album artist/album labels
		album_label = new Label ("");
		artist_label = new Label ("");

		// Apply special style: Level-2 header
		UI.apply_style_to_label (album_label, UI.TextStyle.H2);

		album_label.ellipsize = Pango.EllipsizeMode.END;
		artist_label.ellipsize = Pango.EllipsizeMode.END;

		album_label.set_line_wrap (false);
		artist_label.set_line_wrap (false);
		
		album_label.set_max_width_chars (30);
		artist_label.set_max_width_chars (30);

		album_label.margin_left = album_label.margin_right = 12;
		artist_label.margin_bottom = 12;

		// Music List
		var tvs = new TreeViewSetup (MusicListView.MusicColumn.ARTIST, Gtk.SortType.ASCENDING, ViewWrapper.Hint.ALBUM_LIST);
		list_view = new MusicListView (view_wrapper, tvs);
		
		var list_view_scrolled = new ScrolledWindow (null, null);
		list_view_scrolled.add (list_view);

		// Rating widget
		rating = new Granite.Widgets.Rating (true, IconSize.MENU, true);
		// customize rating
		rating.star_spacing = 16;
		rating.margin_top = rating.margin_bottom = 16;

		// Add everything
		var vbox = new Box(Orientation.VERTICAL, 0);
#if !USE_GRANITE_DECORATED_WINDOW
		vbox.pack_start (close, false, false, 0);
#endif
		vbox.pack_start (album_label, false, true, 0);
		vbox.pack_start (artist_label, false, true, 0);
		vbox.pack_start (list_view_scrolled, true, true, 0);
		vbox.pack_start(rating, false, true, 0);

		add(vbox);

		rating.rating_changed.connect(rating_changed);

#if !USE_GRANITE_DECORATED_WINDOW
		/* Make window draggable */
		UI.make_window_draggable (this);
#endif
	}

	/**
	 * Resets the window
	 */
	public void reset () {
		// clear labels
		set_title ("");
		album_label.set_label ("");
		artist_label.set_label ("");

		// clear treeview and media list
        list_view.get_selection ().unselect_all (); // Unselect rows
        media_list = new Gee.LinkedList<Media> ();
        list_view.set_media (media_list);

		// Reset size request
		set_size (MIN_SIZE);
	}

	public void set_parent_wrapper (ViewWrapper parent_wrapper) {
		this.view_wrapper = parent_wrapper;
		this.list_view.set_parent_wrapper (parent_wrapper);
	}

	Mutex setting_media;

	public void set_media (Gee.Collection<Media> media) {
		reset ();

		setting_media.lock ();

        foreach (var m in media) {
            if (m != null) {
                var album = m.album;
                var artist = m.album_artist;
        		set_title (_("%s by %s").printf (album, artist));
        		album_label.set_label (album);
        		artist_label.set_label (artist);
        		break;
            }
        }

        // Make a copy. Otherwise the list won't work if some elements are
        // removed from the parent wrapper while the window is showing
        foreach (var m in media) {
            if (m != null)
                media_list.add (m);
        }

		list_view.set_media (media_list);

		setting_media.unlock ();

        if (list_view.get_realized ())
            list_view.columns_autosize ();

		// Set rating
		update_album_rating ();
		lm.media_updated.connect (update_album_rating);
	}

	void update_album_rating () {
		// We don't want to set the overall_rating as each media's rating.
		// See rating_changed() in case you want to figure out what would happen.
		rating.rating_changed.disconnect(rating_changed);

		// Use average rating for the album
		int total_rating = 0, n_media = 0;
		foreach (var media in media_list) {
			if (media == null)
				continue;
			n_media ++;
			total_rating += (int)media.rating;
		}

		float average_rating = (float)total_rating / (float)n_media;

		// fix approximation and set new rating
		rating.rating = Numeric.int_from_float (average_rating);

		// connect again ...
		rating.rating_changed.connect (rating_changed);
	}

	void rating_changed (int new_rating) {
		setting_media.lock ();

		var updated = new LinkedList<Media> ();
		foreach (var media in media_list) {
			if (media == null)
				continue;

			media.rating = (uint)new_rating;
			updated.add (media);
		}

		setting_media.unlock ();

		lm.update_media (updated, false, true);
	}


    /**
     * Force squared layout
     */
    public void set_size (int size) {
        this.set_size_request (size, -1);
        queue_resize ();
    }

    public override Gtk.SizeRequestMode get_request_mode () {
        return Gtk.SizeRequestMode.HEIGHT_FOR_WIDTH;
    }

    public override void get_preferred_height_for_width (int width,
                                                         out int minimum_height,
                                                         out int natural_height)
    {
        minimum_height = natural_height = width;
    }
}
