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

require "./spec_helper"
require "../src/core/vm"

VMTestDir = "tests/VMTests"

struct TestDataAccount
  include JSON::Serializable

  @[JSON::Field(key: "balance", converter: TestDataAccount::ParseBigInt)]
  property balance : BigInt
  @[JSON::Field(key: "code", converter: TestDataAccount::ParseBytes)]
  property code : Bytes
  @[JSON::Field(key: "nonce", converter: TestDataAccount::ParseBigInt)]
  property nonce : BigInt
  @[JSON::Field(key: "storage", converter: TestDataAccount::ParseStorage)]
  property storage : Hash(BigInt, BigInt)

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

  def self.default_account : TestDataAccount
    ret = TestDataAccount.allocate
    ret.balance = 0.to_big_i
    ret.nonce = 0.to_big_i
    ret.storage = Hash(BigInt, BigInt).new
    ret
  end

  def self.default_slot : UInt8[32]
    StaticArray(UInt8, 32).new(0)
  end
end

NullAddress = LibEVMOne::Address.new(0)

def exec_test(desc)
  state = Fremkit::Core::MapState(TestDataAccount).new
  pre = Hash(String, TestDataAccount).from_json desc["pre"].to_json
  pre.each do |addr, account|
    state[addr[2..].to_big_i(16)] = account
  end

  exec = desc["exec"]
  code = exec["code"].to_s[2..].hexbytes
  gas = exec["gas"].to_s[2..].to_big_i(16).to_i64
  msg = LibEVMOne::Message.new(
    kind: LibEVMOne::CallKind::CALL,
    gas: gas,
    destination: LibEVMOne::Address.new(20),
    sender: LibEVMOne::Address.new(20),
  )
  accaddr = exec["address"].to_s[2..].hexbytes
  sendaddr = exec["caller"].to_s[2..].hexbytes
  20.times do |i|
    msg.destination[i] = accaddr[i]
    msg.sender[i] = sendaddr[i]
  end

  input = exec["data"].to_s[2..].hexbytes

  evm = EVMOne.new msg.sender, msg.destination, code, gas, input, state
  result = evm.run

  post = Hash(String, TestDataAccount).from_json (desc["post"]? || Hash(Nil, Nil).new).to_json
  post.each do |addr, account|
    res_account = state[addr[2..].to_big_i(16)]
    res_account.should eq account
  end
end

describe "evmone lib" do
  it "runs a simple program" do
    # 2x PUSH1
    code = "60016000".hexbytes
    vm = EVMOne.new(NullAddress, NullAddress, code, 10000, Bytes.empty, Fremkit::Core::MapState(TestDataAccount).new)
    result = vm.run
    result.status_code.should eq LibEVMOne::StatusCode::Success
    result.gas_left.should eq 9994
  end

  it "runs a program with a call to the host interface" do
    # PUSH1 1
    # PUSH1 0
    # SLOAD
    # SSTORE
    # STOP
    code = "60016000545500".hexbytes
    state = Fremkit::Core::MapState(TestDataAccount).new
    state[0.to_big_i] = TestDataAccount.default_account
    state[0.to_big_i].storage[0.to_big_i] = 2.to_big_i
    vm = EVMOne.new(NullAddress, NullAddress, code, 25000, Bytes.empty, state)
    result = vm.run
    result.status_code.should eq LibEVMOne::StatusCode::Success
    result.gas_left.should eq 4944
  end

  describe "Ethereum VM tests" do
    describe "Arithmetic" do
      dirname = "#{VMTestDir}/vmArithmeticTest"
      dir = Dir.new(dirname)
      dir.each { |filename|
        next if filename !~ /.json$/
        name = filename.gsub(/.json$/, "")
        desc = JSON.parse(File.read("#{dirname}/#{filename}"))

        it name do
          exec_test desc[name]
        end
      }
    end

    describe "Bitwise logic" do
      dirname = "#{VMTestDir}/vmBitwiseLogicOperation"
      dir = Dir.new(dirname)
      dir.each { |filename|
        next if filename !~ /.json$/
        name = filename.gsub(/.json$/, "")
        desc = JSON.parse(File.read("#{dirname}/#{filename}"))

        it name do
          exec_test desc[name]
        end
      }
    end
  end
end
