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

@[Link("secp256k1")]
lib Secp256k1
  FLAGS_TYPE_MASK              = ((1 << 8) - 1)
  FLAGS_TYPE_CONTEXT           = (1 << 0)
  FLAGS_TYPE_COMPRESSION       = (1 << 1)
  FLAGS_BIT_CONTEXT_VERIFY     = (1 << 8)
  FLAGS_BIT_CONTEXT_SIGN       = (1 << 9)
  FLAGS_BIT_CONTEXT_DECLASSIFY = (1 << 10)
  CONTEXT_VERIFY               = (FLAGS_TYPE_CONTEXT | FLAGS_BIT_CONTEXT_VERIFY)
  CONTEXT_SIGN                 = (FLAGS_TYPE_CONTEXT | FLAGS_BIT_CONTEXT_SIGN)
  CONTEXT_DECLASSIFY           = (FLAGS_TYPE_CONTEXT | FLAGS_BIT_CONTEXT_DECLASSIFY)
  CONTEXT_NONE                 = (FLAGS_TYPE_CONTEXT)

  alias Context = UInt8
  alias PubKey = StaticArray(UInt8, 64)
  alias SecKey = StaticArray(UInt8, 32)
  alias Signature = StaticArray(UInt8, 64)

  fun secp256k1_context_create(flags : UInt32) : Context*
  fun secp256k1_ec_pubkey_create(ctx : Context*, pubkey : PubKey*, seckey : SecKey*) : UInt32
  fun secp256k1_ecdsa_sign(ctx : Context*, sig : Signature*, msg : UInt8*, seckey : SecKey*, nonce_fct : -> UInt32, ndata : UInt8*) : UInt32
  fun secp256k1_ecdsa_verify(ctx : Context*, sig : Signature*, msg : UInt8*, pubkey : PubKey*) : UInt32
end

class Curve(N)
  struct Point
    def initialize(@x : BigInt, @y : BigInt)
    end

    getter :x, :y

    def +(other : Point) : Point
      (self.jacobian + other.jacobian).to_affine
    end
  end

  def initialize(@p : BigInt, @n : BigInt, @b : BigInt, @g : Point)
  end

  getter :p

  def generator : Point
    @g
  end

  def on_curve?(p : Point) : Bool
    # y² = x³ + b
    left = p.y**2 % @p
    right = (p.x**3 + @b) % @p

    return left == right
  end
end

S256 = Curve(256).new(
  "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F".to_big_i(16),
  "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141".to_big_i(16),
  "0000000000000000000000000000000000000000000000000000000000000007".to_big_i(16),
  Curve::Point.new(
    "79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798".to_big_i(16),
    "483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8".to_big_i(16)
  )
)
end
