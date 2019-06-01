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

# Helper functions for RLP
module Fremkit::Utils::RLP
    class DecodeException < Exception
        def initialize
            super("RLP decode error")
        end
    end

    def encode(bytes : Bytes) : Bytes
        case
        when bytes.size == 0 then bytes
        when bytes.size == 1 && bytes[0] < 128u8 then bytes
        when bytes.size < 56
            len = bytes.size.to_u8
            ret = IO::Memory.new(len+1)
            ret.write_byte(128u8+len)
            ret.write(bytes)
            ret.to_slice
        else
            len = bytes.size        # Length of payload in bytes
            lenlen = case len       # Number of bytes to encode the length above
            when 0..255 then 1
            when 256..65535 then 2
            when 65536..16777215 then 3
            else 4
            end

            ret = IO::Memory.new(len+lenlen+1)
            # Array size is at most I32 in Crystal
            
            
            ret.write_byte(183u8+lenlen)
            ret.seek(lenlen+1)
            ret.write(bytes)

            buf = uninitialized UInt8[4]
            IO::ByteFormat::BigEndian.encode(len, buf.to_slice)
            buf.to_slice[-lenlen..-1].copy_to(ret.to_slice[1..len])

            ret.to_slice
        end
    end

    def decode(bytes : Bytes) : Bytes
        case bytes[0]
        when 0..127
            raise DecodeException.new if bytes.size != 1
            bytes
        when 128..182
            length = bytes[0] - 128
            raise DecodeException.new if length >= 56 || (bytes.size - length != 1)
            ret = IO::Memory.new(length)
            ret.write(bytes[1..])
            ret.to_slice
        else
            length_length = bytes[0] - 183
            raise DecodeException.new if (bytes.size - length_length <= 1)
            buf = Bytes.new(4, 0)
            buf[-length_length.to_i32..].copy_from(bytes[1,length_length])
            length = IO::ByteFormat::BigEndian.decode(Int32, buf)
            raise DecodeException.new if (bytes.size - length_length - 1 - length) < 0
            buffer = Bytes.new(length, 0)
            bytes[1+length_length..].copy_to(buffer)
            buffer
        end
    end
end