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

struct TestDataAccount
  JSON.mapping(
    balance: {type: BigInt, converter: TestDataAccount::ParseBigInt},
    code: {type: Bytes, converter: TestDataAccount::ParseBytes},
    nonce: {type: BigInt, converter: TestDataAccount::ParseBigInt},
    storage: {type: Hash(BigInt, BigInt), converter: TestDataAccount::ParseStorage},
  )

  class ParseStorage
    def self.from_json(pull : JSON::PullParser)
      h = Hash(BigInt, BigInt).new
      pull.read_object do |key, loc|
        h[key[2..].to_big_i(16)] = pull.read_string[2..].to_big_i(16)
      end
      h
    end
  end

  class ParseBytes
    def self.from_json(pull : JSON::PullParser)
      str = pull.read_string
      str[2..].hexbytes
    end
  end

  class ParseBigInt
    def self.from_json(pull : JSON::PullParser)
      str = pull.read_string
      str[2..].to_big_i(16)
    end
  end
end

VMTestDir = "tests/VMTests"

describe "Ethereum VM tests" do
  describe "Arithmetic tests" do
    dirname = "#{VMTestDir}/vmArithmeticTest"
    dir = Dir.new(dirname)
    dir.each { |filename|
      next if filename !~ /.json$/
      name = filename.gsub(/.json$/, "")
      desc = JSON.parse(File.read("#{dirname}/#{filename}"))
      it name do
        state = Fremkit::Core::MapState(TestDataAccount).new
        pre = Hash(String, TestDataAccount).from_json desc[name]["pre"].to_json
        pre.each do |addr, account|
          state[addr[2..].to_big_i(16)] = account
        end
        post = Hash(String, TestDataAccount).from_json (desc[name]["post"]? || Hash(Nil, Nil).new).to_json

        exec = desc[name]["exec"]
        code = exec["code"].to_s[2..].hexbytes

        ctx = ExecutionContext.new
        ctx.set_address(exec["address"].as_s[2..].to_big_i(16))
        ctx.calldata = exec["data"].to_s[2..].hexbytes

        evm = EVM.new code, Bytes.new(4000), ctx, state
        evm.run

        post.each do |addr, account|
          res_account = state[addr[2..].to_big_i(16)]
          res_account.should eq account
        end
      end
    }
  end

  describe "Sha3 tests" do
    dirname = "#{VMTestDir}/vmSha3Test"
    dir = Dir.new(dirname)
    dir.each { |filename|
      next if filename !~ /.json$/
      name = filename.gsub(/.json$/, "")
      desc = JSON.parse(File.read("#{dirname}/#{filename}"))
      it name do
        state = Fremkit::Core::MapState(TestDataAccount).new
        pre = Hash(String, TestDataAccount).from_json desc[name]["pre"].to_json
        pre.each do |addr, account|
          state[addr[2..].to_big_i(16)] = account
        end
        post = Hash(String, TestDataAccount).from_json (desc[name]["post"]? || Hash(Nil, Nil).new).to_json

        exec = desc[name]["exec"]
        code = exec["code"].to_s[2..].hexbytes

        ctx = ExecutionContext.new
        ctx.set_address(exec["address"].as_s[2..].to_big_i(16))
        ctx.calldata = exec["data"].to_s[2..].hexbytes

        evm = EVM.new code, Bytes.new(4000), ctx, state
        evm.run

        post.each do |addr, account|
          res_account = state[addr[2..].to_big_i(16)]
          res_account.should eq account
        end
      end
    }
  end

  describe "Log tests" do
    dirname = "#{VMTestDir}/vmLogTest"
    dir = Dir.new(dirname)
    dir.each { |filename|
      next if filename !~ /.json$/
      name = filename.gsub(/.json$/, "")
      desc = JSON.parse(File.read("#{dirname}/#{filename}"))
      it name do
        state = Fremkit::Core::MapState(TestDataAccount).new
        pre = Hash(String, TestDataAccount).from_json desc[name]["pre"].to_json
        pre.each do |addr, account|
          state[addr[2..].to_big_i(16)] = account
        end
        post = Hash(String, TestDataAccount).from_json (desc[name]["post"]? || Hash(Nil, Nil).new).to_json

        exec = desc[name]["exec"]
        code = exec["code"].to_s[2..].hexbytes

        ctx = ExecutionContext.new
        ctx.set_address(exec["address"].as_s[2..].to_big_i(16))
        ctx.calldata = exec["data"].to_s[2..].hexbytes

        evm = EVM.new code, Bytes.new(4000), ctx, state
        evm.run

        post.each do |addr, account|
          res_account = state[addr[2..].to_big_i(16)]
          res_account.should eq account
        end
      end
    }
  end
end
