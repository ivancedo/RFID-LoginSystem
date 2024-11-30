class UID
    attr_accessor :id

    # Initializes a new RFID instance with an optional UID.
    #
    # @param [String, nil] uid The UID of the RFID tag (optional).
    def initialize(id = nil)
        @id = id
    end

    # Converts the UID to a hexadecimal string with reversed bytes.
    #
    # This method validates that the `id` contains only numeric characters,
    # converts it to an integer, and then formats it as a hexadecimal string
    # with its bytes in reverse order.
    #
    # @return [String, nil] The hexadecimal representation of the UID in uppercase,
    #   or `nil` if the `id` is invalid or an error occurs during processing.
    def hex_uid
        return nil unless id && id =~ /^\d+$/

        decimal_id = id.to_i
        bytes_array = [decimal_id].pack('L').bytes.reverse
        decimal_array = bytes_array.pack('C*').unpack('L')
        hex_string = decimal_array[0].to_s(16).upcase
        hex_string
    rescue StandardError => e
        warn "Error converting UID to hex: #{e.message}"
        nil
    end
end