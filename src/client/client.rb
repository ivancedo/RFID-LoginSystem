require 'gtk3'
require 'json'
require 'net/http'
require 'uri'
require_relative '../lib/uid'

# URL base para las solicitudes al servidor
BASE_URL = 'http://localhost:3000'

# Realiza una solicitud GET al servidor y obtiene datos.
def fetch_data(path, params = {})
    uri = URI("#{BASE_URL}#{path}")
    uri.query = URI.encode_www_form(params) unless params.empty?
    begin
        response = Net::HTTP.get_response(uri)
        if response.code.to_i == 200
            JSON.parse(response.body)
        else
            puts "Error del servidor: #{response.code} - #{response.body}"
            nil
        end
    rescue StandardError => e
        puts "Error al conectar con el servidor: #{e.message}"
        nil
    end
end

# Clase principal que gestiona la interfaz gráfica de la aplicación.
class SimpleClientApp
    attr_accessor :uid

    # Inicializa la aplicación, configurando la ventana principal y los componentes de la UI.
    def initialize
        self.uid = UID.new
        self.uid.id = ''

        @window = Gtk::Window.new('Client Atenea')
        @window.set_size_request(800, 600)

        @window.signal_connect('destroy') { Gtk.main_quit }

        @vbox = Gtk::Box.new(:vertical, 10)
        @vbox.margin = 10
        @window.add(@vbox)

        # Carga estilos desde un archivo CSS externo
        load_css_from_file('styles.css')

        # Muestra la pantalla de autenticación al inicio
        show_authentication_screen

        @window.show_all
    end

    # Muestra la pantalla de autenticación para ingresar el UID.
    def show_authentication_screen
        @vbox.children.each(&:destroy)

        label = Gtk::Label.new('Introdueix el teu UID per autenticar-te')
        @vbox.pack_start(label, expand: false, fill: false, padding: 10)

        entry = Gtk::Entry.new
        entry.signal_connect("key-press-event") do |widget, event|
            handle_keypress(widget, event)
        end
        @vbox.pack_start(entry, expand: false, fill: false, padding: 10)

        auth_button = Gtk::Button.new(label: 'Autentica')
        auth_button.set_name('auth_button')
        auth_button.signal_connect('clicked') do
            uid = entry.text.strip
            authenticate_user(uid)
        end
        @vbox.pack_start(auth_button, expand: false, fill: false, padding: 10)

        @window.show_all
    end

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

    # Muestra la interfaz principal después de la autenticación exitosa.
    def show_main_interface(name)
        @vbox.children.each(&:destroy)

        # Crea un contenedor horizontal para el texto de bienvenida y el botón de cerrar sesión
        header_box = Gtk::Box.new(:horizontal, 5)

        welcome_label = Gtk::Label.new("Benvingut/da, #{name}!")
        header_box.pack_start(welcome_label, expand: true, fill: true, padding: 10)

        logout_button = Gtk::Button.new(label: 'Tanca Sessio')
        logout_button.set_name('logout_button')
        logout_button.signal_connect('clicked') { logout }
        header_box.pack_start(logout_button, expand: false, fill: false, padding: 10)

        @vbox.pack_start(header_box, expand: false, fill: false, padding: 10)

        @text_views_box = Gtk::Box.new(:vertical, 2)
        scrolled_window = Gtk::ScrolledWindow.new
        scrolled_window.add(@text_views_box)
        scrolled_window.set_policy(:automatic, :automatic)
        @vbox.pack_start(scrolled_window, expand: true, fill: true, padding: 10)

        query_button = Gtk::Button.new(label: 'Consulta Taula')
        query_button.set_name('query_button')
        query_button.signal_connect('clicked') { query_table }
        @vbox.pack_start(query_button, expand: false, fill: false, padding: 10)

        @window.show_all
    end

    # Autentica al usuario con un UID proporcionado.

    def authenticate_user(uid)
        result = fetch_data('/authenticate', { uid: uid })
        if result && result['name']
            show_main_interface(result['name'])
        else
            show_error_dialog('Error d\'autenticacio. Torna-ho a intentar.')
        end
    end

    # Muestra un cuadro de diálogo para ingresar una tabla y filtros, y consulta datos del servidor.
    def query_table
        table = prompt('Introdueix el nom de la taula (tasks, timetables, marks):')
        return unless table

        filter_string = prompt('Introdueix els filtres (exemple: subject=Math&date[gte]=2023-01-01):')
        filters = parse_filters(filter_string)

        params = { table: table }.merge(filters)
        result = fetch_data('/query', params)

        if result.is_a?(Array) && !result.empty?
            populate_text_views(result)
        elsif result.is_a?(Array) && result.empty?
            show_error_dialog("No hi ha dades disponibles per a la taula #{table}")
        else
            show_error_dialog('Error: resposta inesperada')
        end
    end

    # Rellena la vista de texto con los datos obtenidos del servidor.
    def populate_text_views(data)
        @text_views_box.children.each(&:destroy)

        # Calcula la longitud máxima por columna
        columns = data.first.keys
        column_widths = columns.map { |col| [col.to_s.length, *data.map { |row| row[col].to_s.length }].max }

        # Agrega encabezados como la primera fila
        headers = columns.each_with_index.map { |col, i| col.to_s.ljust(column_widths[i]) }.join("\t")
        add_text_view(headers, 'header', 0)

        # Agrega los datos fila por fila
        data.each_with_index do |row, index|
            row_data = columns.each_with_index.map { |col, i| row[col].to_s.ljust(column_widths[i]) }.join("\t")
            style_class = index.even? ? 'row_even' : 'row_odd'
            add_text_view(row_data, style_class, index + 1)
        end

        @window.show_all
    end

    # Añade una fila de datos a la vista de texto.
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

    # Convierte una cadena de filtros en un hash de claves y valores.
    def parse_filters(filter_string)
        return {} if filter_string.nil? || filter_string.empty?

        filters = {}
        filter_string.split('&').each do |filter|
            key, value = filter.split('=')
            filters[key.strip] = value.strip if key && value
        end
        filters
    end

    # Muestra un cuadro de diálogo con un mensaje de error.
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

    # Restablece la aplicación a la pantalla de autenticación.
    def logout
        show_authentication_screen
    end

    # Muestra un cuadro de diálogo para ingresar texto y devuelve la entrada del usuario.
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

    # Carga estilos desde un archivo CSS.
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

Gtk.init
SimpleClientApp.new
Gtk.main