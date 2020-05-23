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

require "json"

require "./spec_helper.cr"
require "../src/core/vm"

describe "Ethereum VM tests" do
  describe "Arithmetic tests" do
    dirname = "../tests/VMTests/vmArithmeticTest"
    dir = Dir.new(dirname)
    dir.each { |filename|
      next if filename !~ /.json$/
      name = filename.gsub(/.json$/, "")
      desc = JSON.parse(File.read("#{dirname}/#{filename}"))
      it name do
        state = Fremkit::Core::MapState(JSON::Any).new
        pre = desc[name]["pre"].as_h
        pre.each do |addr, account|
          state[addr[2..].to_big_i(16)] = account
        end

        exec = desc[name]["exec"]
        code = exec["code"].to_s[2..].hexbytes
        inputdata = exec["data"].to_s[2..].hexbytes

        evm = EVM.new code, Bytes.new(4000), ExecutionContext.new, state
      end
    }
  end
end
