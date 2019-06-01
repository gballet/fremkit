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

describe "prout" do
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
        r = decode(encode(i))
        r.should eq(i)

        i = Bytes[157u8]
        r = decode(encode(i))
        r.should eq(i)
    end

    it "should be able to decode a byte array that it has encoded" do
        i = Bytes[23u8, 35u8, 12u8]
        r = decode(encode(i))
        r.should eq(i)
    end

    it "should be able to decode a long byte array that it has encoded" do
        i = Random.new.random_bytes(59)
        r = decode(encode(i))
        r.should eq(i)
    end

    it "should be able to encode and decode a byte array whose length is more than 1 byte wide" do
        i = Random.new.random_bytes(1024)
        r = decode(encode(i))
        r.should eq(i)
    end
end