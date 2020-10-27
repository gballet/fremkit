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

require "./spec_helper"

def str_to_skey(str : String) : StaticArray(UInt8, 32)
  skey : StaticArray(UInt8, 32) = StaticArray(UInt8, 32).new(0)
  str.hexbytes.each_with_index do |b, i|
    skey[i] = b
  end
  skey
end

describe "libsecp256k1" do
  it "generates a public key" do
    skey = str_to_skey "b1709928c134598d8718829738e8e954a906afdbc065abe6049cb66970070ee8"
    ctx = Secp256k1.secp256k1_context_create(Secp256k1::CONTEXT_SIGN | Secp256k1::CONTEXT_VERIFY)

    Secp256k1.secp256k1_ec_pubkey_create(ctx, out pubkey, pointerof(skey)).should eq 1
    pubkey.to_slice[0..31].should eq "c4ccc37f7b6b92cec5038ddca99e8f8871bd1a5d1a3ccb27b84cf2b72ee8ba55".hexbytes.reverse!
  end

  it "signs and verifies a public key" do
    skey = StaticArray(UInt8, 32).new { Random.new.rand(255).to_u8 }
    [1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8, 1u8]
    ctx = Secp256k1.secp256k1_context_create(Secp256k1::CONTEXT_SIGN | Secp256k1::CONTEXT_VERIFY)
    Secp256k1.secp256k1_ec_pubkey_create(ctx, out pubkey, pointerof(skey)).should eq 1

    msg = Bytes.new(32, 1)
    puts msg
    sig = StaticArray(UInt8, 64).new(64)
    Secp256k1.secp256k1_ecdsa_sign(ctx, pointerof(sig), msg, pointerof(skey), nil, nil).should eq 1
    Secp256k1.secp256k1_ecdsa_verify(ctx, pointerof(sig), msg, pointerof(pubkey)).should eq 1
  end
end

describe "curve" do
  it "generator is on_curve?" do
    S256.on_curve?(S256.generator)
  end
end
