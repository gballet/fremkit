require "big"

module Fremkit
    class InvalidFormatException < Exception
        def initialize(format : String, addr : Address)
            super("Invalid address format, got: #{addr.hex_str}, expected: #{format}")
        end
    end

    # This represents an address and contains general helper methods.
    # To obtain a workable object, `check_format` needs to be over-
    # loaded to check that the address' format is correct.
    abstract struct Address
        getter :bytes
        getter :to_i
        getter :little

        @str : String = ""

        # Turns the list of bytes into an address. `little` specifies
        # the endianness of those bytes.
        def initialize(@bytes : Array(UInt8), @little : Bool = false)
            @to_i = BigInt.new(0)
            from_bytes(@bytes)
        end

        # Turns a hex string representing an address into an address.
        # `little` is true if bytes should be stored in little-endian
        # order
        def initialize(str : String, @little : Bool = false)
            @to_i = str.to_i(16, prefix: true)

            @bytes = Array(UInt8).new

            @bytes.size.times do |i|
                @bytes[@little ? i : (@bytes.size - 1 - i)] = @to_i & (0xff << (8*i))
            end
        end

        # This should be overloaded to check that the size of
        # the `@bytes` array corresponds to a valid address.
        abstract def check_format : Bool

        # This should be overloaded to allocate the right size
        # of bytes into @bytes
        abstract def format_size : Int32

        def to_s
            hex_str()
        end

        def from_bytes(bytes : Array(UInt8))
            @bytes = bytes

            if check_format()
                # Calculates the integral version
                @to_i = BigInt.new(0)
                (@little ? @bytes.reverse : @bytes).each do |b|
                    @to_i = (@to_i << 8) + b
                end
            else
                raise "Invalid address format"
            end
        end

        def hex_str : String
            # Cache the string version, and display the length
            # of the address based on the size of the @bytes
            # array.
            @str = sprintf "0x%0#{@bytes.size*2}x", @to_i if @str == ""
            @str
        end
    end
end