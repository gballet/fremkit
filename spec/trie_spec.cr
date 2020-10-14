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

include Fremkit::Trees

describe "hexary trie:" do
  it "should hash the empty node to the empty root" do
    Trie::EmptyNode.new.hash.should eq Trie::EmptyRoot
  end
  describe "hex prefix:" do
    it "should pack an empty key" do
      key = Bytes.empty
      Trie::EmptyNode.new.hex_prefix(key, true).should eq Bytes[32]
    end

    it "should pack a single-nibble key" do
      key = Bytes[1]
      Trie::EmptyNode.new.hex_prefix(key, true).should eq Bytes[49]
    end

    it "should pack a single byte key" do
      key = Bytes[0, 1]
      Trie::EmptyNode.new.hex_prefix(key, true).should eq Bytes[32, 1]
    end

    it "should pack an even-length key" do
      key = Bytes[0, 1, 2, 3]
      Trie::EmptyNode.new.hex_prefix(key, true).should eq Bytes[32, 1, 35]
    end

    it "should pack an odd-sized key" do
      key = Bytes[0, 1, 2]
      Trie::EmptyNode.new.hex_prefix(key, true).should eq Bytes[48, 18]
    end
  end

  it "should be able to insert a (key,value) pair into the empty root" do
    trie = Trie.new
    trie.root_hash.should eq Trie::EmptyRoot

    trie.insert Bytes[0, 1, 2, 3], Bytes[4, 5, 6, 7]
    trie.get(Bytes[0, 1, 2, 3]).should eq Bytes[4, 5, 6, 7]
    trie.root_hash.should eq Bytes[210, 173, 155, 246, 191, 47, 142, 155, 159, 177, 26, 9, 92, 220, 46, 254, 182, 70, 215, 123, 170, 170, 69, 47, 203, 11, 122, 110, 126, 103, 233, 158]
  end

  it "should be able to insert a (key,value) pair into a leaf root" do
    trie = Trie.new
    trie.root_hash.should eq Trie::EmptyRoot

    trie.insert Bytes[0, 1, 2, 3], Bytes[4, 5, 6, 7]
    trie.insert Bytes[0, 1, 3, 3], Bytes[8, 9, 10, 11]
    trie.root_hash.should eq Bytes[186, 193, 14, 228, 135, 231, 231, 163, 129, 218, 34, 128, 99, 36, 34, 250, 51, 145, 99, 121, 10, 223, 66, 220, 84, 254, 118, 75, 125, 176, 199, 170]
  end
end
