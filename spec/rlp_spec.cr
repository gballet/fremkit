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

struct SandWorm
  getter :age
  getter :length

  def initialize(@age : UInt32, @length : UInt32)
  end
end

struct Harvester
  @@maker : String = "ix industries"

  def initialize(@fuel : UInt32)
  end

  def set_maker(name : String)
    @@maker = name
  end
end

describe "RLP tests" do
  it "should encode 1 as 1 byte" do
    x = Fremkit::Utils::RLP.encode(Bytes[1])
    x.size.should eq(1)
    x[0].should eq(1)
  end

  it "should encode 129 as 2 bytes" do
    x = Fremkit::Utils::RLP.encode(Bytes[129])
    x.size.should eq(2)
    x.should eq(Bytes[129, 129])
  end

  it "should encode a 55 bytes array as 56 bytes" do
    x = Fremkit::Utils::RLP.encode(Bytes.new(55, 0))
    x.size.should eq(56)
    x.should eq(Bytes[183, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
  end

  it "should encode a 56 byte array as 58 bytes" do
    rlp = Array.new(56, 0u8).to_rlp
    rlp.size.should eq 58
  end

  it "should be able to decode a byte that it has encoded" do
    i = Bytes[23]
    r, size = decode(Fremkit::Utils::RLP.encode(i))
    r.should eq(i)
    size.should eq 1

    i = Bytes[157]
    r, size = decode(Fremkit::Utils::RLP.encode(i))
    r.should eq(i)
    size.should eq 2
  end

  it "should be able to decode a byte array that it has encoded" do
    i = Bytes[23, 35, 12]
    r, size = decode(Fremkit::Utils::RLP.encode(i))
    r.should eq(i)
    size.should eq 4
  end

  it "should be able to decode a long byte array that it has encoded" do
    i = Random.new.random_bytes(59)
    r, size = decode(Fremkit::Utils::RLP.encode(i))
    r.should eq(i)
    size.should eq 61
  end

  it "should be able to encode and decode a byte array whose length is more than 1 byte wide" do
    i = Random.new.random_bytes(1024)
    r, size = decode(Fremkit::Utils::RLP.encode(i))
    r.should eq(i)
    size.should eq 1027
  end

  it "should be able to encode a complex structure smaller than 56 bytes" do
    r = Fremkit::Utils::RLP.encode [Bytes[1, 1, 1], Bytes[2, 2, 2, 2]]
    r.should eq Bytes[201, 131, 1, 1, 1, 132, 2, 2, 2, 2]
  end

  it "should be able to encode a complex structure bigger than 56 bytes" do
    r = Fremkit::Utils::RLP.encode [Bytes[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], Bytes[2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]]
    r.should eq Bytes[248, 58, 160, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 152, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]
  end

  it "should be able to encode a u32" do
    rlp = 1u32.to_rlp
    rlp.should eq Bytes[1]

    rlp = 129u32.to_rlp
    rlp.should eq Bytes[129, 129]

    rlp = 0xFFFFFFFFu32.to_rlp
    rlp.should eq Bytes[132, 255, 255, 255, 255]
  end

  it "should be able to encode a string" do
    rlp = "Kull wahad".to_rlp
    rlp.should eq Bytes[138, 75, 117, 108, 108, 32, 119, 97, 104, 97, 100]

    rlp = ("Kull wahad"*10).to_rlp
    rlp.should eq Bytes[184, 100, 75, 117, 108, 108, 32, 119, 97, 104, 97, 100, 75, 117, 108, 108, 32, 119, 97, 104, 97, 100, 75, 117, 108, 108, 32, 119, 97, 104, 97, 100, 75, 117, 108, 108, 32, 119, 97, 104, 97, 100, 75, 117, 108, 108, 32, 119, 97, 104, 97, 100, 75, 117, 108, 108, 32, 119, 97, 104, 97, 100, 75, 117, 108, 108, 32, 119, 97, 104, 97, 100, 75, 117, 108, 108, 32, 119, 97, 104, 97, 100, 75, 117, 108, 108, 32, 119, 97, 104, 97, 100, 75, 117, 108, 108, 32, 119, 97, 104, 97, 100]
  end

  it "shoud be able to decode a u32" do
    i, pos = UInt32.from_rlp(Bytes[42])
    pos.should eq 1
    i.should eq 42

    i, pos = UInt32.from_rlp(Bytes[0x83, 0xde, 0xad, 0xbe])
    pos.should eq 4
    i.should eq 0xdeadbeu32
  end

  it "should be able to decode a string" do
    s, pos = String.from_rlp(Bytes[0x83, 97, 98, 99])
    pos.should eq 4
    s.should eq "abc"

    s, pos = String.from_rlp(Bytes[184, 57, 97, 98, 99, 97, 98, 99, 97, 98, 99, 97, 98, 99, 97, 98, 99, 97, 98, 99, 97, 98, 99, 97, 98, 99, 97, 98, 99, 97, 98, 99, 97, 98, 99, 97, 98, 99, 97, 98, 99, 97, 98, 99, 97, 98, 99, 97, 98, 99, 97, 98, 99, 97, 98, 99, 97, 98, 99])
    pos.should eq 59
    s.should eq "abcabcabcabcabcabcabcabcabcabcabcabcabcabcabcabcabcabcabc"
  end

  it "should be able to encode a tuple of primitives" do
    {1, "Kull wahad"}.to_rlp.should eq Bytes[204, 1, 138, 75, 117, 108, 108, 32, 119, 97, 104, 97, 100]
  end

  it "should be able to encode an empty tuple" do
    Tuple.new.to_rlp.should eq Bytes[0xc0]
  end

  it "should be able to encode a hash table" do
    {"Kull wahad" => "Secher Nbiw", 42 => "Rock'n'roll"}.to_rlp.should eq Bytes[228, 138, 75, 117, 108, 108, 32, 119, 97, 104, 97, 100, 139, 83, 101, 99, 104, 101, 114, 32, 78, 98, 105, 119, 42, 139, 82, 111, 99, 107, 39, 110, 39, 114, 111, 108, 108]
  end

  it "should be able to encode a struct" do
    worm = SandWorm.new(100, 20)
    worm.to_rlp.should eq Bytes[194, 100, 20]

    worm = SandWorm.new(100_000, 20)
    worm.to_rlp.should eq Bytes[197, 131, 1, 134, 160, 20]
  end

  it "should be able to encode a struct with class variables" do
    harvester = Harvester.new(90)
    harvester.to_rlp.should eq Bytes[207, 141, 105, 120, 32, 105, 110, 100, 117, 115, 116, 114, 105, 101, 115, 90]
  end

  it "shoud be able to decode a structure" do
    worm, off = SandWorm.from_rlp(Bytes[197, 131, 1, 134, 160, 20])
    off.should eq 6
    worm.length.should eq 20
    worm.age.should eq 100_000
  end
end
