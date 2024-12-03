require 'gtk3'
require 'json'
require 'net/http'
require 'uri'
require_relative '../lib/uid'

# Base URL for server requests
BASE_URL = 'http://localhost:3000'

# Performs a GET request to the server and fetches data.
# @param path [String] the endpoint path to append to the base URL.
# @param params [Hash] optional query parameters to include in the request.
# @return [Hash, nil] the parsed JSON response from the server, or nil if an error occurs.
def fetch_data(path, params = {})
    uri = URI("#{BASE_URL}#{path}")
    uri.query = URI.encode_www_form(params) unless params.empty?
    begin
        response = Net::HTTP.get_response(uri)
        if response.code.to_i == 200
            JSON.parse(response.body)
        else
            puts "Server error: #{response.code} - #{response.body}"
            nil
        end
    rescue StandardError => e
        puts "Connection error: #{e.message}"
        nil
    end
end

# Main class managing the application's graphical interface.
class SimpleClientApp
    attr_accessor :uid

    # Initializes the application, setting up the main window and UI components.
    # No parameters or return values.
    def initialize
        self.uid = UID.new
        self.uid.id = ''

        @window = Gtk::Window.new('Client Atenea')
        @window.set_size_request(800, 600)

        @window.signal_connect('destroy') { Gtk.main_quit }

        @vbox = Gtk::Box.new(:vertical, 10)
        @vbox.margin = 10
        @window.add(@vbox)

        # Loads styles from an external CSS file.
        load_css_from_file('./styles/styles_gtk.css')

        # Displays the authentication screen at startup.
        show_authentication_screen

        @window.show_all
    end

    # Displays the authentication screen to input the UID.
    # No parameters or return values.
    def show_authentication_screen
        @vbox.children.each(&:destroy)

        label = Gtk::Label.new('Enter your UID to authenticate')
        @vbox.pack_start(label, expand: false, fill: false, padding: 10)

        entry = Gtk::Entry.new
        entry.signal_connect("key-press-event") do |widget, event|
            handle_keypress(widget, event)
        end
        @vbox.pack_start(entry, expand: false, fill: false, padding: 10)

        auth_button = Gtk::Button.new(label: 'Authenticate')
        auth_button.set_name('auth_button')
        auth_button.signal_connect('clicked') do
            uid = entry.text.strip
            authenticate_user(uid)
        end
        @vbox.pack_start(auth_button, expand: false, fill: false, padding: 10)

        @window.show_all
    end

    # Handles keypress events during UID input.
    # @param widget [Gtk::Entry] the text entry widget.
    # @param event [Gdk::EventKey] the key event triggered.
    # @return [Boolean] true to stop further handling of the event.
    def handle_keypress(widget, event)
        key_val = event.keyval
        key_str = Gdk::Keyval.to_name(key_val)

        if key_str == "Return"
            authenticate_user(uid.hex_uid)
            puts uid.hex_uid
            self.uid.id.clear
        else
            self.uid.id += key_str
        end

        true
    end

    # Displays the main interface after successful authentication.
    # @param name [String] the name of the authenticated user.
    # No return value.
    def show_main_interface(name)
        @vbox.children.each(&:destroy)

        # Creates a header with a welcome message and logout button.
        header_box = Gtk::Box.new(:horizontal, 5)

        welcome_label = Gtk::Label.new("Welcome, #{name}!")
        header_box.pack_start(welcome_label, expand: true, fill: true, padding: 10)

        logout_button = Gtk::Button.new(label: 'Log Out')
        logout_button.set_name('logout_button')
        logout_button.signal_connect('clicked') { logout }
        header_box.pack_start(logout_button, expand: false, fill: false, padding: 10)

        @vbox.pack_start(header_box, expand: false, fill: false, padding: 10)

        @text_views_box = Gtk::Box.new(:vertical, 2)
        scrolled_window = Gtk::ScrolledWindow.new
        scrolled_window.add(@text_views_box)
        scrolled_window.set_policy(:automatic, :automatic)
        @vbox.pack_start(scrolled_window, expand: true, fill: true, padding: 10)

        query_button = Gtk::Button.new(label: 'Query Table')
        query_button.set_name('query_button')
        query_button.signal_connect('clicked') { query_table }
        @vbox.pack_start(query_button, expand: false, fill: false, padding: 10)

        @window.show_all
    end

    # Authenticates the user using a provided UID.
    # @param uid [String] the user identifier to authenticate.
    # No return value.
    def authenticate_user(uid)
        result = fetch_data('/authenticate', { uid: uid })
        if result && result['name']
            show_main_interface(result['name'])
        else
            show_error_dialog('Authentication error. Please try again.')
        end
    end

    # Queries a table and filters data from the server.
    # No parameters.
    # No return value.
    def query_table
        table = prompt('Enter the table name (tasks, timetables, marks):')
        return unless table

        filter_string = prompt('Enter filters (e.g., subject=Math&date[gte]=2023-01-01):')
        filters = parse_filters(filter_string)

        params = { table: table }.merge(filters)
        result = fetch_data('/query', params)

        if result.is_a?(Array) && !result.empty?
            populate_text_views(result)
        elsif result.is_a?(Array) && result.empty?
            show_error_dialog("No data available for table #{table}")
        else
            show_error_dialog('Error: unexpected response')
        end
    end
    # Fills the text view with data fetched from the server.
    # @param data [Array<Hash>] the data to populate in the text views.
    # No return value.
    def populate_text_views(data)
        @text_views_box.children.each(&:destroy)

        # Calculates the maximum width for each column.
        columns = data.first.keys
        column_widths = columns.map { |col| [col.to_s.length, *data.map { |row| row[col].to_s.length }].max }

        # Adds headers as the first row.
        headers = columns.each_with_index.map { |col, i| col.to_s.ljust(column_widths[i]) }.join("\t")
        add_text_view(headers, 'header', 0)

        # Adds data row by row.
        data.each_with_index do |row, index|
            row_data = columns.each_with_index.map { |col, i| row[col].to_s.ljust(column_widths[i]) }.join("\t")
            style_class = index.even? ? 'row_even' : 'row_odd'
            add_text_view(row_data, style_class, index + 1)
        end

        @window.show_all
    end

    # Adds a row of data to the text view.
    # @param text [String] the text content of the row.
    # @param style_class [String] the CSS class to style the row.
    # @param row_index [Integer] the row index for reference.
    # No return value.
    def add_text_view(text, style_class, row_index)
        buffer = Gtk::TextBuffer.new
        buffer.text = text

        text_view = Gtk::TextView.new
        text_view.buffer = buffer
        text_view.editable = false
        text_view.cursor_visible = false
        text_view.set_name(style_class)
        @text_views_box.pack_start(text_view, expand: false, fill: false, padding: 2)
    end

    # Converts a filter string into a hash of keys and values.
    # @param filter_string [String] the raw filter string (e.g., "key1=value1&key2=value2").
    # @return [Hash] a hash of parsed filters.
    def parse_filters(filter_string)
        return {} if filter_string.nil? || filter_string.empty?

        filters = {}
        filter_string.split('&').each do |filter|
            key, value = filter.split('=')
            filters[key.strip] = value.strip if key && value
        end
        filters
    end

    # Displays an error dialog with a message.
    # @param message [String] the error message to display.
    # No return value.
    def show_error_dialog(message)
        dialog = Gtk::MessageDialog.new(
            parent: @window,
            flags: :destroy_with_parent,
            type: :error,
            buttons: :close,
            message: message
        )
        dialog.run
        dialog.destroy
    end

    # Resets the application to the authentication screen.
    # No parameters or return value.
    def logout
        show_authentication_screen
    end

    # Displays a dialog to prompt the user for text input.
    # @param message [String] the message to display in the dialog.
    # @return [String, nil] the user's input, or nil if canceled or empty.
    def prompt(message)
        dialog = Gtk::Dialog.new(
            title: message,
            parent: @window,
            flags: :destroy_with_parent,
            buttons: [[Gtk::Stock::OK, :ok], [Gtk::Stock::CANCEL, :cancel]]
        )
        entry = Gtk::Entry.new
        dialog.child.add(entry)
        dialog.child.show_all

        response = dialog.run
        input = entry.text.strip
        dialog.destroy
        response == :ok && !input.empty? ? input : nil
    end

    # Loads styles from a CSS file.
    # @param file_path [String] the path to the CSS file.
    # No return value.
    def load_css_from_file(file_path)
        return unless File.exist?(file_path)

        provider = Gtk::CssProvider.new
        provider.load_from_path(file_path)
        Gtk::StyleContext.add_provider_for_screen(
            Gdk::Screen.default,
            provider,
            Gtk::StyleProvider::PRIORITY_USER
        )
    end
end

# Initializes and runs the GTK application.
Gtk.init
SimpleClientApp.new
Gtk.main
