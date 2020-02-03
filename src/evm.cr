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

while !done
  if pc < bytecode.size
    instr = bytecode[pc]

    case instr
    end
  else
    raise Exception.new "Invalid program counter: #{pc} < #{bytecode.size} = bytecode size"
  end
end
