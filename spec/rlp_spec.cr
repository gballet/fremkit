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

require "./spec_helper.cr"

include Fremkit::Utils::RLP

describe "RLP tests" do
  it "should encode 1 as 1 byte" do
    x = encode(Bytes[1u8])
    x.size.should eq(1)
    x[0].should eq(1)
  end

  it "should encode 129 as 2 bytes" do
    x = encode(Bytes[129u8])
    x.size.should eq(2)
    x.should eq(Bytes[129u8, 129u8])
  end

  it "should encode a 55 bytes array as 56 bytes" do
    x = encode(Bytes.new(55, 0))
    x.size.should eq(56)
    x.should eq(Bytes[183, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
  end

  it "should encode a 56 byte array as 58 bytes" do
  end

  it "should be able to decode a byte that it has encoded" do
    i = Bytes[23u8]
    r, size = decode(encode(i))
    r.should eq(i)
    size.should eq 1

    i = Bytes[157u8]
    r, size = decode(encode(i))
    r.should eq(i)
    size.should eq 2
  end

  it "should be able to decode a byte array that it has encoded" do
    i = Bytes[23u8, 35u8, 12u8]
    r, size = decode(encode(i))
    r.should eq(i)
    size.should eq 4
  end

  it "should be able to decode a long byte array that it has encoded" do
    i = Random.new.random_bytes(59)
    r, size = decode(encode(i))
    r.should eq(i)
    size.should eq 61
  end

  it "should be able to encode and decode a byte array whose length is more than 1 byte wide" do
    i = Random.new.random_bytes(1024)
    r, size = decode(encode(i))
    r.should eq(i)
    size.should eq 1027
  end

  it "should be able to encode a complex structure smaller than 56 bytes" do
    r = encode [Bytes[1u8, 1u8, 1u8], Bytes[2u8, 2u8, 2u8, 2u8]]
    r.should eq Bytes[201u8, 131u8, 1u8, 1u8, 1u8, 132u8, 2u8, 2u8, 2u8, 2u8]
  end

  it "should be able to encode a complex structure bigger than 56 bytes" do
    r = encode [Bytes[1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8], Bytes[2u8, 2u8, 2u8, 2u8, 2u8, 2u8, 2u8, 2u8, 2u8, 2u8, 2u8, 2u8, 2u8, 2u8, 2u8, 2u8, 2u8, 2u8, 2u8, 2u8, 2u8, 2u8, 2u8, 2u8]]
    r.should eq Bytes[248, 58, 160, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 152, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]
  end

  it "should be able to encode a u32" do
    rlp = 1u32.to_rlp
    rlp.should eq Bytes[1u8]

    rlp = 129u32.to_rlp
    rlp.should eq Bytes[129u8, 129u8]

    rlp = 0xFFFFFFFFu32.to_rlp
    rlp.should eq Bytes[132u8, 255u8, 255u8, 255u8, 255u8]
  end

  it "should be able to encode a string" do
    rlp = "Kull wahad".to_rlp
    rlp.should eq Bytes[202, 75, 117, 108, 108, 32, 119, 97, 104, 97, 100]

    rlp = ("Kull wahad"*10).to_rlp
    rlp.should eq Bytes[184, 100, 75, 117, 108, 108, 32, 119, 97, 104, 97, 100, 75, 117, 108, 108, 32, 119, 97, 104, 97, 100, 75, 117, 108, 108, 32, 119, 97, 104, 97, 100, 75, 117, 108, 108, 32, 119, 97, 104, 97, 100, 75, 117, 108, 108, 32, 119, 97, 104, 97, 100, 75, 117, 108, 108, 32, 119, 97, 104, 97, 100, 75, 117, 108, 108, 32, 119, 97, 104, 97, 100, 75, 117, 108, 108, 32, 119, 97, 104, 97, 100, 75, 117, 108, 108, 32, 119, 97, 104, 97, 100, 75, 117, 108, 108, 32, 119, 97, 104, 97, 100]
  end
end
