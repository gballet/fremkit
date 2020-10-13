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

require "sha3"

module Fremkit
  module Trees
    # A generic (key, value) store in which items are stored in a Merkle tree
    abstract class MerkleTree(K, V, H)
      abstract def root_hash : H
      abstract def insert(key : K, value : V)
      abstract def get(key : K) : V
    end

    # Implements a hexary Merkle Patricia Tree (MPT), which is not backed
    # by a data store: all values are stored in memory.
    #
    # ```
    # trie = Trie.new
    # trie.root_hash # => [86, 232, 31, 23, 27, 204, 85, 166, 255, 131, 69, 230, 146, 192, 248, 110, 91, 72, 224, 27, 153, 108, 173, 192, 1, 98, 47, 181, 227, 99, 180, 33]
    # ```
    class Trie < MerkleTree(Bytes, Bytes, Bytes)
      EmptyRoot = Bytes[86, 232, 31, 23, 27, 204, 85, 166, 255, 131, 69, 230, 146, 192, 248, 110, 91, 72, 224, 27, 153, 108, 173, 192, 1, 98, 47, 181, 227, 99, 180, 33]

      abstract class TrieNode
        def hash : Bytes
          digest = Digest::Keccak3.new(256)
          digest.update(self.to_rlp).result
        end

        def hex_prefix(key : Bytes, leaf?) : Bytes
          length = (key.size / 2).to_i
          ret = Bytes.new(length + 1)
          ret[0] = (leaf? ? 32u8 : 0u8) + (key.size.odd? ? 16u8 : 0u8)
          off = key.size.even? ? 1 : 0
          key.each.with_index do |x, idx|
            byte = off + ((1 - off + idx)/2).to_i
            ret[byte] |= (idx.odd? ^ key.size.odd?) ? key[idx] : key[idx] << 4
          end
          ret
        end

      end

      class EmptyNode < TrieNode
        def to_rlp : Bytes
          Bytes[0x80]
        end
      end
      class ExtNode < TrieNode
        getter prefix
        getter child

        def initialize(@prefix : Bytes, @child : TrieNode)
        end

        def to_rlp : Bytes
          {hex_prefix(@prefix, false), child}.to_rlp
        end
      end

      class LeafNode < TrieNode
        def initialize(@prefix : Bytes, @value : Bytes)
        end

        def to_rlp : Bytes
          {hex_prefix(@prefix, true), @value}.to_rlp
        end
      end

      class BranchNode < TrieNode
        class BranchNodeIndexException < Exception
        end

        @children_and_value : StaticArray(TrieNode | Bytes, 17) = StaticArray[
          EmptyNode.new.as(TrieNode),
          EmptyNode.new.as(TrieNode),
          EmptyNode.new.as(TrieNode),
          EmptyNode.new.as(TrieNode),
          EmptyNode.new.as(TrieNode),
          EmptyNode.new.as(TrieNode),
          EmptyNode.new.as(TrieNode),
          EmptyNode.new.as(TrieNode),
          EmptyNode.new.as(TrieNode),
          EmptyNode.new.as(TrieNode),
          EmptyNode.new.as(TrieNode),
          EmptyNode.new.as(TrieNode),
          EmptyNode.new.as(TrieNode),
          EmptyNode.new.as(TrieNode),
          EmptyNode.new.as(TrieNode),
          EmptyNode.new.as(TrieNode),
          Bytes.empty,
        ]

        def [](idx : UInt8) : TrieNode | Bytes
          raise BranchNodeIndexException.new("getting index > 16 in branch node") if idx > 16
          @children_and_value[idx]
        end

        def []=(idx : UInt8, child : TrieNode | Bytes)
          case idx
          when 0..15
            @children_and_value[idx] = child.as(TrieNode)
          when 16
            # Only idx=16 has is of type `Bytes`
            @children_and_value[idx] = child.as(Bytes)
          else
            raise BranchNodeIndexException.new("setting index idx > 16 in branch node")
          end
        end

        def to_rlp : Bytes
          @children_and_value.to_rlp
        end
      end

      root : TrieNode

      def initialize
        @root = EmptyNode.new
      end

      def root_hash : Bytes
        @root.hash
      end

      def insert(key : Bytes, value : Bytes)
      end

      def get(key : Bytes) : Bytes
      end
    end
  end
end
