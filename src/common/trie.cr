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

        def self.get : TrieNode
          @@instance = EmptyNode.new.as(TrieNode) if @@instance.nil?
          @@instance.as(TrieNode)
        end
      end

      class ExtNode < TrieNode
        property prefix
        property child

        def initialize(@prefix : Bytes, @child : TrieNode)
        end

        def to_rlp : Bytes
          {hex_prefix(@prefix, false), child}.to_compact_rlp
        end
      end

      class LeafNode < TrieNode
        property prefix
        property value

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
          EmptyNode.get.as(TrieNode),
          EmptyNode.get.as(TrieNode),
          EmptyNode.get.as(TrieNode),
          EmptyNode.get.as(TrieNode),
          EmptyNode.get.as(TrieNode),
          EmptyNode.get.as(TrieNode),
          EmptyNode.get.as(TrieNode),
          EmptyNode.get.as(TrieNode),
          EmptyNode.get.as(TrieNode),
          EmptyNode.get.as(TrieNode),
          EmptyNode.get.as(TrieNode),
          EmptyNode.get.as(TrieNode),
          EmptyNode.get.as(TrieNode),
          EmptyNode.get.as(TrieNode),
          EmptyNode.get.as(TrieNode),
          EmptyNode.get.as(TrieNode),
          Bytes.empty,
        ]

        def [](idx : UInt8) : TrieNode | Bytes
          raise BranchNodeIndexException.new("getting index > 16 in branch node") if idx > 16
          @children_and_value[idx]
        end

        def []=(idx : UInt8, child : TrieNode | Bytes)
          raise BranchNodeIndexException.new("setting index idx > 16 in branch node") if idx > 16
          raise BranchNodeIndexException.new("index 16 contains a value, not a child node") if idx == 16 && !child.is_a?(Bytes)
          raise BranchNodeIndexException.new("index 16 contains a value, not a child node") if idx < 16 && !child.is_a?(TrieNode)
          @children_and_value[idx] = child
        end

        def to_rlp : Bytes
          @children_and_value.to_rlp_compact
        end
      end

      root : TrieNode

      def initialize
        @root = EmptyNode.get
      end

      def root_hash : Bytes
        @root.hash
      end

      def common_length(key : Bytes, prefix : Bytes) : UInt32
        split = 0
        prefix.each.with_index do |p, i|
          if p != key[i]
            return i.to_u32
          end
        end
        return key.size.to_u32
      end

      def insert(key : Bytes, value : Bytes)
        it = @root
        key_idx = 0 # nibble index into the key
        parent = @root.as(TrieNode)
        while true
          case it
          when BranchNode
            parent = it
            if it[key[key_idx]].is_a?(EmptyNode)
              it[key[key_idx]] = LeafNode.new key[key_idx + 1..], value
              break
            end
            it = it[key[key_idx]]
            key_idx += 1
          when ExtNode
            split = common_length key[key_idx..], it.prefix
            if split < it.prefix.size
              # need to create a branch node
              nbranch = BranchNode.new
              nbranch[key[key_idx + split]] = LeafNode.new(key[key_idx + split + 1..], value)
              # Insert an intermediate ext node if the split occured before
              # the last nibble.
              nbranch[it.prefix[split]] = if split + 1 == it.prefix.size
                                            it.child
                                          else
                                            ExtNode.new(it.prefix[key_idx + split + 1..], it.child)
                                          end
              it.child = nbranch
              it.prefix = it.prefix[...split]
              break
            else
              # recurse into child node
              parent = it
              key_idx += it.prefix.size
              it = it.child
            end
          when LeafNode
            if key[key_idx..] != it.prefix
              # need to create a branch node
              split = common_length key[key_idx..], it.prefix
              nbranch = BranchNode.new
              nbranch[key[key_idx + split]] = LeafNode.new(key[key_idx + split + 1..], value)
              nbranch[it.prefix[split]] = LeafNode.new it.prefix[split + 1..], it.value

              start_node = if split == key_idx
                             nbranch
                           else
                             ExtNode.new key[key_idx...split], nbranch
                           end
              if parent == @root
                @root = start_node
              else
                parent.as(BranchNode)[key[key_idx - 1]] = start_node
              end
              break
            else
              # Overwrite the current value
              it.value = value
              break
            end
          when EmptyNode
            if parent == @root
              @root = LeafNode.new key, value
            else
              parent.as(BranchNode)[key[key_idx]] = LeafNode.new key[key_idx + 1..], value
            end
            break
          end
        end
      end

      def get(key : Bytes) : Bytes
      end
    end
  end
end
