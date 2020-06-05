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
  abstract def step
  abstract def registers : Registers
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
  end

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
          @stack.push (a/b)
        end
      when 5 # SDIV
        a = @stack.pop
        b = @stack.pop
        if b == 0
          @stack.push b
        elsif b == -1 && a.popcount == 256
          @stack.push a
        else
          @stack.push a.tdiv(b)
        end
      when 6 # MOD
        a = @stack.pop
        b = @stack.pop
        @stack.push (a % b)
      when 8 # ADDMOD
        a = @stack.pop
        b = @stack.pop
        c = @stack.pop
        r = (a + b) % c
        @stack.push r
      when 9 # MULMOD
        a = @stack.pop
        b = @stack.pop
        c = @stack.pop
        r = (a*b) % c
        @stack.push r
      when 0x10 # LT
        a = @stack.pop
        b = @stack.pop
        @stack.push BigInt.new(a < b ? 1 : 0)
      when 0x11 # GT
        a = @stack.pop
        b = @stack.pop
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
        o = BigInt.new(0)
        256.times do |bit|
          o |= (1 << bit) if n.bit(bit) == 0
        end
      when 0x1a # BYTE
        byte_num = @stack.pop
        src = @stack.pop
        @stack.push ((src >> (8*byte_num)) & 0xFF)
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
      when 0x50 # POP
        @stack.pop
      when 0x54 # SLOAD
        addr = @stack.pop
        storage = @state[@context.address].storage
        @stack.push (storage[addr] || BigInt.new)
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
        # when 0x58 # JUMPI
        # addr = @stack.pop
        # cond = @stack.pop
        # unless cond.zero?
        # pc = addr.to_u16 - 1
        # end
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
          data |= @code[@pc + 1 + i]
        end
        @pc += datasize
        @stack.push data
      when 0x80..0x8f # DUPn
        depth : UInt8 = instr - 0x60
        @stack.push @stack[@stack.size - 1 - depth]
      when 0x90..0x9f # SWAPn
        sdepth : UInt8 = instr - 0x60
        tmp = @stack[@stack.size - 1 - sdepth]
        @stack[@stack.size - 1 - sdepth] = @stack[@stack.size - 1]
        @stack[@stack.size - 1] = tmp
      else
        raise Exception.new "Unsupported instruction: #{instr}"
      end
    else
      @done = 1
    end

    @pc += 1
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
