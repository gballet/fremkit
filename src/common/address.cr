# This is free and unencumbered software released into the public domain.
#
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.
#
# In jurisdictions that recognize copyright laws, the author or authors
# of this software dedicate any and all copyright interest in the
# software to the public domain. We make this dedication for the benefit
# of the public at large and to the detriment of our heirs and
# successors. We intend this dedication to be an overt act of
# relinquishment in perpetuity of all present and future rights to this
# software under copyright law.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
# For more information, please refer to <http://unlicense.org>

require "big"

module Fremkit
  class InvalidAddressFormatException < Exception
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
      # Remove the header, not supported by BigInt.new
      str = str[2..] if str[0] == '0' && (str[1] == 'x' || str[1] == 'X')

      @to_i = BigInt.new(str, 16)
      @bytes = Array(UInt8).new(str.size.as(Int) >> 1, 0u8)

      @bytes.size.times do |i|
        @bytes[@little ? i : (@bytes.size - 1 - i)] = ((@to_i >> (8*i)) & 0xFF).to_u8
      end
    end

    # This should be overloaded to check that the size of
    # the `@bytes` array corresponds to a valid address.
    abstract def check_format : Bool

    # This should be overloaded to allocate the right size
    # of bytes into @bytes
    abstract def format_size : Int32

    # Default address format descriptor, overload if needed.
    def format_str : String
      "#{self.format_size} bytes"
    end

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
        raise InvalidAddressFormatException.new(format_str, self)
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
