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

require "./state"
require "../common/address"
require "sha3"

class ExecutionContext
  property gas : UInt64 = 0
  getter address : BigInt = BigInt.new(0)
  property state : Hash(BigInt, BigInt) = Hash(BigInt, BigInt).new
  getter origin : BigInt = BigInt.new(0)
  getter caller : BigInt = BigInt.new(0)
  getter callvalue : BigInt = BigInt.new(0)
  property calldata : Bytes = Bytes.empty
  getter code : Bytes = Bytes.empty
  getter gasprice : UInt64 = 0
  property retdata : Bytes = Bytes.empty
  getter block_num : BigInt = BigInt.new(0)

  def set_caller(cller : BigInt)
    @caller = cllr
  end

  def set_address(addr : BigInt)
    @address = addr
  end
end

abstract class Registers
  abstract def [](name : String) : Int
end

abstract class VM
  abstract def memory : Bytes
  abstract def run
end

class EVM(T) < VM
  UInt256Mask = (BigInt.new("1") << 256) - 1

  class EVMRegisters < Registers
    def initialize(@pc : UInt64)
    end

    def [](name : String) : Int
      raise "Invalid register #{name}" if name != "pc"
      @pc
    end
  end

  def initialize(@code : Bytes, @mem : Bytes, @context : ExecutionContext, @state : Fremkit::Core::State(BigInt, T))
    @pc = 0
    @done = false
    @stack = Array(BigInt).new
    @retaddr = -1
    @retlength = -1
    @logs = Array(Bytes).new
    @topics = Array(BigInt).new
  end

  U256Overflow = BigInt.new(2)**256

  def step
    if @pc < @code.size
      instr = @code[@pc]

      case instr
      when 0 # STOP
        @done = true
      when 1 # ADD
        a = @stack.pop
        b = @stack.pop
        r = (a + b) & UInt256Mask
        @stack.push r
      when 2 # MUL
        a = @stack.pop
        b = @stack.pop
        r = (a * b) & UInt256Mask
        @stack.push r
      when 3 # SUB
        a = @stack.pop
        b = @stack.pop
        r = (a - b) & UInt256Mask
        @stack.push r
      when 4 # DIV
        a = @stack.pop
        b = @stack.pop
        if b == 0
          @stack.push b
        else
          @stack.push a.tdiv(b)
        end
      when 0x05 # SDIV
        a = @stack.pop
        b = @stack.pop

        if a.bit(255) == 1
          a -= U256Overflow
        end
        if b.bit(255) == 1
          b -= U256Overflow
        end

        if b == 0
          @stack.push b
        elsif b == -1 && a.popcount == 255
          # This doesn't crash the tests, I suspect that this
          # case isn't being tested. TODO test when fuzzing the
          # EVM.
          @stack.push a
        else
          t = a.tdiv(b)
          if t < 0
            @stack.push (U256Overflow + t)
          else
            @stack.push t
          end
        end
      when 6 # MOD
        a = @stack.pop
        b = @stack.pop
        if b == 0
          @stack.push b
        else
          @stack.push (a % b)
        end
      when 7 # SMOD
        a = @stack.pop
        b = @stack.pop
        if b == 0
          @stack.push b
        else
          if a.bit(255) == 1
            a -= U256Overflow
          end
          if b.bit(255) == 1
            b -= U256Overflow
          end

          if a.sign == -1
            x = (U256Overflow - (a.abs % b.abs)) % U256Overflow
            @stack.push x
          else
            @stack.push (a % b.abs)
          end
        end
      when 8 # ADDMOD
        a = @stack.pop
        b = @stack.pop
        c = @stack.pop
        if c == 0
          @stack.push BigInt.new(0)
        else
          @stack.push ((a + b) % c)
        end
      when 9 # MULMOD
        a = @stack.pop
        b = @stack.pop
        c = @stack.pop
        if c == 0
          @stack.push BigInt.new(0)
        else
          @stack.push ((a*b) % c)
        end
      when 0x0a # EXP
        a = @stack.pop
        b = @stack.pop
        @stack.push ((a**b) & UInt256Mask)
      when 0x0b # SIGNEXTEND
        b = @stack.pop
        if b < 31
          int = @stack.pop

          bit = b*8 + 7

          x = BigInt.new(1) << bit
          mask = x - 1
          if int.bit(bit) == 1
            val = (int | ~mask)
            val += UInt256Mask + 1 if val < 0
            @stack.push val
          else
            @stack.push (int & mask)
          end
        end
      when 0x10 # LT
        a = @stack.pop
        b = @stack.pop
        @stack.push BigInt.new(a < b ? 1 : 0)
      when 0x11 # GT
        a = @stack.pop
        b = @stack.pop
        @stack.push BigInt.new(a > b ? 1 : 0)
      when 0x12 # SLT
        a = @stack.pop
        b = @stack.pop
        if a.bit(255) == 1
          a -= U256Overflow
        end
        if b.bit(255) == 1
          b -= U256Overflow
        end
        @stack.push BigInt.new(a < b ? 1 : 0)
      when 0x13 # SGT
        a = @stack.pop
        b = @stack.pop
        if a.bit(255) == 1
          a -= U256Overflow
        end
        if b.bit(255) == 1
          b -= U256Overflow
        end
        @stack.push BigInt.new(a > b ? 1 : 0)
      when 0x14 # EQ
        a = @stack.pop
        b = @stack.pop
        @stack.push BigInt.new(a == b ? 1 : 0)
      when 0x15 # ISZERO
        a = @stack.pop
        @stack.push BigInt.new(a == 0 ? 1 : 0)
      when 0x16 # AND
        a = @stack.pop
        b = @stack.pop
        @stack.push (a & b)
      when 0x17 # OR
        a = @stack.pop
        b = @stack.pop
        @stack.push (a | b)
      when 0x18 # XOR
        a = @stack.pop
        b = @stack.pop
        @stack.push (a ^ b)
      when 0x19 # NOT
        n = @stack.pop
        r = ~n
        r += UInt256Mask + 1 if r < 0
        @stack.push r
      when 0x1a # BYTE
        byte_num = @stack.pop
        src = @stack.pop
        @stack.push ((src >> (8*byte_num)) & 0xFF)
      when 0x20 # SHA3
        if @stack.size < 2 || @stack[0] > UInt32::MAX || @stack[1] > UInt32::MAX
          @done = true
        else
          addr = @stack.pop.to_i64
          length = @stack.pop.to_i64
          if @mem.size < addr + length
            new_mem_size = addr + length
            new_mem_size += new_mem_size % 32
            new_mem = Bytes.new(new_mem_size)
            new_mem.copy_from(@mem)
            @mem = new_mem
          end
          digest = Digest::Keccak3.new(256)
          @stack.push digest.update(@mem[addr...addr + length]).hexdigest.to_big_i(16)
        end
      when 0x30 # ADDRESS
        @stack.push @context.address
      when 0x31 # BALANCE
        @stack.push @context.state[@context.address]
      when 0x32 # ORIGIN
        @stack.push @context.origin
      when 0x33 # CALLER
        @stack.push @context.caller
      when 0x34 # CALLVALUE
        @stack.push @context.callvalue
      when 0x35 # CALLDATALOAD
        off = @stack.pop
        result = BigInt.new(0)
        32.times do |i|
          x = if off + i >= @context.calldata.size
                0
              else
                @context.calldata[off + i]
              end
          result = (result << 8) | x
        end
        @stack.push result
      when 0x36 # CALLDATASIZE
        @stack.push BigInt.new @context.calldata.size
      when 0x37 # CALLDATACOPY
        addr = @stack.pop
        input_off = @stack.pop
        len = @stack.pop
        len.times do |i|
          if @context.calldata.size > input_off + i
            @mem[addr + i] = @context.calldata[input_off + i]
            # TODO check memory extension
          else
            # Terminate if trying to read beyond the input data size
            done = true
          end
        end
      when 0x38 # CODESIZE
        @stack.push BigInt.new @context.code.size
      when 0x39 # CODECOPY
        addr = @stack.pop
        code_off = @stack.pop
        len = @stack.pop
        len.times do |i|
          if @context.calldata.size > code_off + i
            @mem[addr + i] = @context.calldata[code_off + i]
            # TODO check memory extension
          else
            # Terminate if trying to read beyond the input data size
            done = true
          end
        end
      when 0x3a # GASPRICE
        @stack.push BigInt.new @context.gasprice
      when 0x43 # NUMBER
        @stack.push @context.block_num
      when 0x50 # POP
        @stack.pop
      when 0x51 # MLOAD
        memaddr = @stack.pop.to_i

        a = BigInt.new(@mem[memaddr])
        31.times do |i|
          a <<= 8
          a |= @mem[memaddr + 1 + i]
        end
        @stack.push a
      when 0x52 # MSTORE
        memaddr = @stack.pop
        word = @stack.pop

        32.times do |i|
          @mem[memaddr.to_i + 31 - i] = (word & 0xFF).to_u8
          word >>= 8
        end
      when 0x53 # MSTORE8
        puts @stack.inspect
        memaddr = @stack.pop
        word = @stack.pop

        @mem[memaddr] = (word & 0xFF).to_u8
      when 0x54 # SLOAD
        addr = @stack.pop
        storage = @state[@context.address].storage
        @stack.push (storage[addr]? || BigInt.new)
      when 0x55 # SSTORE
        addr = @stack.pop
        word = @stack.pop
        storage = @state[@context.address].storage
        if word.popcount == 0
          storage.delete(addr)
        else
          storage[addr] = word
        end
      when 0x56 # JUMP
        addr = @stack.pop
        pc = addr.to_u16 - 1
      when 0x57 # JUMPI
        to = @stack.pop
        cond = @stack.pop
        pc = to.to_u16 - 1 if cond != 0
      when 0x58 # PC
        @stack.push BigInt.new(@pc)
      when 0x59 # MSIZE
        @stack.push BigInt.new(@mem.size)
      when 0x5a # GAS
        @stack.push BigInt.new @context.gas
      when 0x5b # JUMPDEST
        # Does nothing
      when 0x60..0x7f # PUSHn
        datasize : UInt8 = instr - 0x60 + 1
        data = BigInt.new
        datasize.times do |i|
          data <<= 8
          if @code.size > @pc + 1 + i
            data |= @code[@pc + 1 + i]
          end
        end
        @pc += datasize
        @stack.push data
      when 0x80..0x8f # DUPn
        depth : UInt8 = instr - 0x80
        @stack.push @stack[@stack.size - 1 - depth]
      when 0x90..0x9f # SWAPn
        sdepth : UInt8 = instr - 0x90 + 1
        tmp = @stack[@stack.size - 1 - sdepth]
        @stack[@stack.size - 1 - sdepth] = @stack[@stack.size - 1]
        @stack[@stack.size - 1] = tmp
      when 0xa0..0xa4 # LOGn
        topic_length : UInt8 = instr - 0xa0
        if @stack.size < 2 + topic_length || @stack[@stack.size - 1] > UInt32::MAX || @stack[@stack.size - 2] > UInt32::MAX
          @done
        else
          addr = @stack.pop.to_i
          length = @stack.pop.to_i
          @logs.push @mem[addr...addr + length]
          topic_length.times do |topic_n|
            @topics.push @stack.pop
          end
        end
      when 0xf3 # RETURN
        @retaddr = @stack.pop.to_i
        @retlength = @stack.pop.to_i
        @done = 1
      else
        raise Exception.new "Unsupported instruction: #{instr}"
      end
    else
      @done = 1
    end

    @pc += 1
  end

  def retdata : Bytes
    raise Exception.new "Trying to get return data on a contract that did not return properly" if @retaddr < 0 || @retlength < 0
    @mem[@retaddr..@retaddr + @retlength]
  end

  def registers : Registers
    EVMRegisters.new(@pc)
  end

  def memory : Bytes
    @mem
  end

  def run
    while !@done
      step
    end
  end
end
