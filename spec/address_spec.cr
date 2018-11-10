require "./spec_helper"

# Define a small, 8-byte address scheme for testing purposes
struct TestAddress < Fremkit::Address
    def check_format : Bool
        @bytes.size == 8
    end

    def format_size : Int32
        8
    end
end

TestAddressBytes = [0xde_u8, 0xad_u8, 0xbe_u8, 0xef_u8, 0_u8, 0_u8, 0_u8, 0_u8]

describe Fremkit::Address do
    it "should translate an array of big-endian bytes of the correct size and turn it into a valid address" do
        addr = TestAddress.new(TestAddressBytes)
        TestAddressBytes.should eq(addr.bytes)
        addr.bytes.size.should eq(8)
        "0xdeadbeef00000000".should eq(addr.to_s)
    end

    it "should translate an array of little-endian bytes of the correct size and turn it into a valid address" do
        addr = TestAddress.new(TestAddressBytes.reverse, true)
        TestAddressBytes.reverse.should eq(addr.bytes)
        addr.bytes.size.should eq(8)
        "0xdeadbeef00000000".should eq(addr.to_s)
    end

    it "should fail if the number of bytes is smaller than the expected address size" do
        expect_raises(Fremkit::InvalidAddressFormatException, /expected: 8 bytes/) do
            addr = TestAddress.new(TestAddressBytes[0..2], true)
        end
    end

    it "should fail if the number of bytes is bigger than the expected address size" do
        expect_raises(Fremkit::InvalidAddressFormatException, /expected: 8 bytes/) do
            addr = TestAddress.new(TestAddressBytes + [0_u8], true)
        end
    end

    it "should be able to decode a string and return a little-endian array of bytes" do
        addr = TestAddress.new("0xdeadbeef00000000")
        TestAddressBytes.should eq(addr.bytes)
    end

    it "should be able to decode a string and return a big-endian array of bytes" do
        addr = TestAddress.new("0xdeadbeef00000000", true)
        TestAddressBytes.reverse.should eq(addr.bytes)
    end

    it "should be able to decode a string and get it back" do
        "0xdeadbeef00000000".should eq(TestAddress.new("0xdeadbeef00000000").to_s)
        "0xdeadbeef00000000".should eq(TestAddress.new("0xdeadbeef00000000", true).to_s)
    end
end