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

require "./core/vm"
require "./utils/bytecode"

if ARGV.size < 1
  puts "usage: evm [options] <bytecode>"
  exit -1
end

b = BigInt.new(ARGV[1], 16)
bytecode = Array(UInt8).new(ARGV[-1].size.as(Int) >> 1, 0u8)
bytecode.size.times do |i|
  bytecode[bytecode.size - 1 - i] = ((b >> (8*i)) & 0xFF).to_u8
end

done = false
pc : UInt16 = 0
stack = Array(BigInt).new

state = Hash(BigInt, BigInt).new

mem = Array(BigInt).new(4_000)

context = ExecutionContext.new

# TODO idee de malade: jetter du Int dans la pile, comme ca je peux
# melanger le bigint et le int et voir si ca depote un max question
# execution, sans avoir a me prendre la tete pour voir si un truc
# est ceci ou cela.

while !done
  if pc < bytecode.size
    instr = bytecode[pc]

    case instr
    when 0 # STOP
      done = true
    when 1 # ADD
      a = stack.pop
      b = stack.pop
      stack.push (a + b)
    when 2 # MUL
      a = stack.pop
      b = stack.pop
      stack.push (a * b)
    when 0x10 # LT
      a = stack.pop
      b = stack.pop
      stack.push BigInt.new(a < b ? 1 : 0)
    when 0x11 # GT
      a = stack.pop
      b = stack.pop
      stack.push BigInt.new(a > b ? 1 : 0)
    when 0x14 # EQ
      a = stack.pop
      b = stack.pop
      stack.push BigInt.new(a == b ? 1 : 0)
    when 0x15 # ISZERO
      a = stack.pop
      stack.push BigInt.new(a == 0 ? 1 : 0)
    when 0x16 # AND
      a = stack.pop
      b = stack.pop
      stack.push (a & b)
    when 0x17 # OR
      a = stack.pop
      b = stack.pop
      stack.push (a | b)
    when 0x18 # XOR
      a = stack.pop
      b = stack.pop
      stack.push (a ^ b)
    when 0x19 # NOT
      n = stack.pop
      o = BigInt.new(0)
      256.times do |bit|
        o |= (1 << bit) if n.bit(bit) == 0
      end
    when 0x1a # BYTE
      byte_num = stack.pop
      src = stack.pop
      stack.push ((src >> (8*byte_num)) & 0xFF)
    when 0x30 # ADDRESS
      stack.push context.address
    when 0x31 # BALANCE
      stack.push context.state[context.address]
    when 0x32 # ORIGIN
      stack.push context.origin
    when 0x33 # CALLER
      stack.push context.caller
    when 0x34 # CALLVALUE
      stack.push context.callvalue
    when 0x35 # CALLDATALOAD
      off = stack.pop
      result = BigInt.new(0)
      32.times do |i|
        x = if off + i >= context.calldata.size
              0
            else
              context.calldata[off + i]
            end
        result = (result << 8) | x
      end
      stack.push result
    when 0x36 # CALLDATASIZE
      stack.push BigInt.new context.calldata.size
    when 0x37 # CALLDATACOPY
      addr = stack.pop
      input_off = stack.pop
      len = stack.pop
      len.times do |i|
        if context.calldata.size > input_off + i
          mem[addr + i] = context.calldata[input_off + i]
          # TODO check memory extension
        else
          # Terminate if trying to read beyond the input data size
          done = true
        end
      end
    when 0x38 # CODESIZE
      stack.push BigInt.new context.code.size
    when 0x39 # CODECOPY
      addr = stack.pop
      code_off = stack.pop
      len = stack.pop
      len.times do |i|
        if context.calldata.size > code_off + i
          mem[addr + i] = context.calldata[code_off + i]
          # TODO check memory extension
        else
          # Terminate if trying to read beyond the input data size
          done = true
        end
      end
    when 0x3a # GASPRICE
      stack.push context.gasprice
    when 0x50 # POP
      stack.pop
    when 0x54 # SLOAD
      addr = stack.pop
      stack.push (state[addr] || BigInt.new)
    when 0x55 # SSTORE
      addr = stack.pop
      word = stack.pop
      state[addr] = word
    when 0x56 # JUMP
      addr = stack.pop
      pc = addr.to_u16 - 1
    when 0x58 # PC
      stack.push BigInt.new(pc)
    when 0x59 # MSIZE
      stack.push BigInt.new(mem.size)
    when 0x5a # GAS
      stack.push BigInt.new context.gas
    when 0x5b # JUMPDEST
      # Does nothing
    when 0x60..0x7f # PUSHn
      datasize : UInt8 = instr - 0x60
      data = BigInt.new
      datasize.times do |i|
        data += bytecode[pc + i] << (1*8)
      end
      stack.push data
    when 0x80..0x8f # DUPn
      depth : UInt8 = instr - 0x60
      stack.push stack[stack.size - 1 - depth]
    when 0x90..0x9f # SWAPn
      depth : UInt8 = instr - 0x60
      tmp = stack[stack.size - 1 - depth]
      stack[stack.size - 1 - depth] = stack[stack.size - 1]
      stack[stack.size - 1] = tmp
    else
      raise Exception.new "Unsupported instruction: #{instr}"
    end
  else
    raise Exception.new "Invalid program counter: #{pc} < #{bytecode.size} = bytecode size"
  end

  pc += 1
end
