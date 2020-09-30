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

struct Int
  def to_rlp : Bytes
    case self
    when 0..128
      Bytes[self.to_u8]
    else
      byte_count = (Math.log(self, 2).ceil.to_i/8).ceil.to_i

      # that can't happen for UInt32
      # if byte_count > 56
      # raise "Number is too big to be serialized"
      # end
      data = Bytes.new(byte_count + 1)
      data[0] = 128u8 + byte_count
      0..byte_count.times do |i|
        data[i + 1] = ((self >> (8 * (byte_count - i - 1))) & 0xFF).to_u8
      end
      data
    end
  end

  def Int.from_rlp(bytes : Bytes) : {self, UInt32}
    case bytes[0]
    when 0..128
      {bytes[0].to_u32, 1.to_u32}
    else
      byte_count = bytes[0] - 128
      val = 0u32
      byte_count.times do |i|
        val = (val << 8) + bytes[1 + i].to_u32
      end
      {val, byte_count.to_u32 + 1}
    end
  end
end

def write_bigendian(x : Int, to : Bytes)
  byte_count = (Math.log(x, 2).ceil.to_i/8).ceil.to_i
  byte_count.times do |i|
    to[byte_count - i - 1] = ((x >> (8 * i)) & 0xFF).to_u8
  end
end

class String
  def to_rlp : Bytes
    bytes = self.to_slice
    byte_count = bytes.size
    if byte_count == 1 && bytes[0] < 128u8
      bytes
    else
      if byte_count < 56
        data = Bytes.new(byte_count + 1)
        data[0] = 128u8 + byte_count
        data[1..].copy_from(bytes)
        data
      else
        length_length = (Math.log(byte_count, 2).ceil.to_i/8).ceil.to_i
        data = Bytes.new(1 + length_length + byte_count)
        data[0] = 183u8 + length_length
        write_bigendian(byte_count, data[1..])
        data[1 + length_length..].copy_from(bytes)
        data
      end
    end
  end

  def String.from_rlp(bytes : Bytes) : {String, UInt32}
    if bytes.size == 1 && bytes[0] < 128
      {"", 1.to_u32}
    elsif bytes[0] < 183
      size = bytes[0] - 128
      raise "Invalid length" if bytes.size < size + 1
      {String.new(bytes[1..size]), 1.to_u32 + size.to_u32}
    else
      length_size = bytes[0] - 183
      length = 0u32
      length_size.times do |i|
        length = (length << 8) + bytes[1 + i].to_u32
      end
      start = 1.to_u32 + length_size.to_u32
      stop = start + length.to_u32
      {String.new(bytes[start...stop]), stop}
    end
  end
end

class Array(T)
  def to_rlp : Bytes
    encoding = alloc_with_header
    self.each do |item|
      encoding.write item.to_rlp
    end
    payload_size = encoding.pos - 3
    write_header(encoding.to_slice, payload_size.to_u32)
  end
end

struct Tuple(*T)
  def to_rlp : Bytes
    encoding = alloc_with_header
    self.each do |item|
      encoding.write item.to_rlp
    end
    payload_size = encoding.pos - 3
    write_header(encoding.to_slice, payload_size.to_u32)
  end
end

class Hash(K, V)
  def to_rlp : Bytes
    encoding = alloc_with_header
    self.each do |k, v|
      encoding.write k.to_rlp
      encoding.write v.to_rlp
    end
    payload_size = encoding.pos - 3
    write_header(encoding.to_slice, payload_size.to_u32)
  end

  def from_rlp(bytes : Bytes) : Typle(self, UInt32)
  end
end

struct Struct
  def to_rlp : Bytes
    encoding = alloc_with_header
    puts {{@type.name}}
    {% for var in @type.class_vars %}
	    encoding.write @@{{var.name}}.to_rlp
    {% end %}

    {% for var in @type.instance_vars %}
	    encoding.write @{{var.name}}.to_rlp
    {% end %}
    payload_size = encoding.pos - 3
    puts encoding
    write_header(encoding.to_slice, payload_size.to_u32)
  end

  def Struct.from_rlp(rlp : Bytes) : {self, UInt32}
    {{@type.name}}.allocate.from_rlp(rlp)
  end

  def from_rlp(rlp : Bytes) : {self, UInt32}
    # The structure is encoded as a list, turn it into an array
    payload_size = case rlp[0]
                   when 0..191
                     raise DecodeException.new
                   when 192..247
                     rlp[0] - 192
                   else
                     size_size = rlp[0] - 247
                     size = 0u64
                     size_size.times do |b|
                       size = rlp[1 + b] + (size << 8)
                     end
                     size
                   end
    if rlp.size != payload_size + 1 # bug if in 248..255 range
      raise DecodeException.new
    end
    off : UInt32 = 1 # same bug

    {% for var in @type.class_vars %}
	    @@{{var.name}}, o = {{var.type}}.from_rlp(rlp[off..])
	    off += o
    {% end %}
    {% for var in @type.instance_vars %}
	    @{{var.name}}, o = {{var.type}}.from_rlp(rlp[off..])
	    off += o
    {% end %}

    {self, off}
  end
end

# Helper functions for RLP
module Fremkit::Utils::RLP
  class DecodeException < Exception
    def initialize
      super("RLP decode error")
    end
  end

  def alloc_with_header : IO::Memory
    encoding = IO::Memory.new(4096)
    encoding.write_byte(0) # placeholders for the header, 64K-3 max
    encoding.write_byte(0)
    encoding.write_byte(0)
    encoding
  end

  def write_header(payload : Bytes, payload_size : UInt32)
    if payload_size < 56
      payload[2] = 192u8 + payload_size.to_u8
      return payload[2..]
    elsif payload_size < 256
      payload[1] = 248
      payload[2] = payload_size.to_u8
      return payload[1..]
    elsif payload_size < 65533
      payload[0] = 249
      write_bigendian(payload_size, payload[1..])
      return payload
    else
      raise "RLP payloads bigger than 64K aren't supported"
    end
  end

  def rlp_bytes_size(bytes : Bytes) : UInt32
    if bytes[0] < 128
      1
    elsif bytes[0] < 183
      bytes[0].to_32 - 128
    else
      length_length = bytes[0] - 183
      val = 0.u32
      length_length.times do |i|
        val = (val << 8) + bytes[1 + i].u32
      end
    end
  end

  # General version: serialize all items one by one. This won't support
  # payloads more than 64K in total.
  def encode(items : Array) : Bytes
    # For the initial capacity, assume that most items will be a multiple
    # of 32 so including the header and the encoding, assume it is going
    # to be 3 + 33 * items.size as a rule of thumb. And then round it up
    # to a page size.
    page_size = 2 + 33*items.size
    page_size = page_size + page_size % 4096
    encoding = IO::Memory.new(page_size)
    encoding.write_byte(0) # placeholders for the header, 64K-3 max
    encoding.write_byte(0)
    encoding.write_byte(0)
    items.each do |item|
      encoding.write encode(item)
    end
    payload_size = encoding.pos - 3
    ret = encoding.to_slice
    if payload_size < 56
      ret[2] = 192u8 + payload_size.to_u8
      return ret[2..]
    elsif payload_size < 256
      ret[1] = 248
      ret[2] = payload_size.to_u8
      return ret[1..]
    elsif payload_size < 65533
      ret[0] = 249
      IO::ByteFormat::BigEndian.encode(payload_size.to_u16, ret[1..2])
      return ret
    else
      raise "RLP payload is too big"
    end
  end

  # Specialize template for bytes
  def encode(bytes : Bytes) : Bytes
    case
    when bytes.size == 0                     then bytes
    when bytes.size == 1 && bytes[0] < 128u8 then bytes
    when bytes.size < 56
      len = bytes.size.to_u8
      ret = IO::Memory.new(len + 1)
      ret.write_byte(128u8 + len)
      ret.write(bytes)
      ret.to_slice
    else
      len = bytes.size  # Length of payload in bytes
      lenlen = case len # Number of bytes to encode the length above
               when 0..255          then 1
               when 256..65535      then 2
               when 65536..16777215 then 3
               else                      4
               end

      ret = IO::Memory.new(len + lenlen + 1)
      # Array size is at most I32 in Crystal

      ret.write_byte(183u8 + lenlen)
      ret.seek(lenlen + 1)
      ret.write(bytes)

      buf = uninitialized UInt8[4]
      IO::ByteFormat::BigEndian.encode(len, buf.to_slice)
      buf.to_slice[-lenlen..-1].copy_to(ret.to_slice[1..len])

      ret.to_slice
    end
  end

  def decode(bytes : Bytes) : {Array, UInt32}
    case bytes[0]
    when 192..247
      length = bytes[0] - 192
      raise DecodeException.new if length + 1 != bytes.size
      ret = Array(T).new
      offset = 0
      while offset < length
      end
    when 248..255
    else
      raise DecodeException.new
    end
  end

  # Specialization for when this is a list of bytes
  def decode(bytes : Bytes) : {Bytes, UInt32}
    case bytes[0]
    when 0..127
      raise DecodeException.new if bytes.size != 1
      {bytes, 1.to_u32}
    when 128..182
      length = bytes[0] - 128
      raise DecodeException.new if length >= 56 || (bytes.size - length != 1)
      ret = IO::Memory.new(length)
      ret.write(bytes[1..])
      {ret.to_slice, length.to_u32 + 1}
    else
      length_length = bytes[0] - 183
      raise DecodeException.new if (bytes.size - length_length <= 1)
      buf = Bytes.new(4, 0)
      buf[-length_length.to_i32..].copy_from(bytes[1, length_length])
      length = IO::ByteFormat::BigEndian.decode(Int32, buf)
      raise DecodeException.new if (bytes.size - length_length - 1 - length) < 0
      buffer = Bytes.new(length, 0)
      bytes[1 + length_length..].copy_to(buffer)
      {buffer, length_length.to_u32 + length.to_u32 + 1}
    end
  end
end
