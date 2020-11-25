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

@[Link(ldflags: "-levmone")]
lib LibEVMOne
  enum StatusCode
    Success
    Failure
    Revert
    OutOfGas
    InvalidInstruction
    UndefinedInstruction
    StackOverflow
    StackUnderflow
    BadJumpDestination
    InvalidMemoryAccess
    CallDepthExceeded
    StaticModeViolation
    PrecompileFailure
    ContractValidationFailure
    ArgOutOfRange
    InternalError             = -1
    Rejected                  = -2
    OutOfMemory               = -3
  end

  enum StorageStatus
    StorageUnchanged
    StorageModified
    StorageModifiedAgain
    StorageAdded
    StorageDeleted
  end

  alias Address = UInt8[20]

  struct Result
    status_code : StatusCode
    gas_left : Int64
    output_data : UInt8*
    output_size : LibC::SizeT
    release : -> Result*
    create_address : Address
    padding : UInt8[4]
  end

  alias HostContext = Void

  struct HostInterface
    account_exist : (HostContext*, Address*) -> Bool
    get_storage : (HostContext*, Address*, UInt8[32]*) -> UInt8[32]
    set_storage : (HostContext*, Address*, UInt8[32]*, UInt8[32]*) -> StorageStatus
    get_balance : (HostContext*, Address*) -> UInt8[32]
    get_code_size : (HostContext*, Address*) -> LibC::SizeT
    get_code_hash : (HostContext*, Address*) -> UInt8[32]*
    copy_code : (HostContext*, Address*, LibC::SizeT, UInt8*, LibC::SizeT) -> LibC::SizeT
    selfdestruct : (HostContext*, Address*, Address*) ->
  end

  enum CallKind
    CALL
    DELEGATECALL
    CALLCODE
    CREATE
    CREATE2
  end

  enum Revision
    FRONTIER
    HOMESTEAD
    TANGERINE_WHISTLE
    SPURIOUS_DRAGON
    BYZANTIUM
    CONSTANTINOPLE
    PETERSBURG
    ISTANBUL
    BERLIN
  end

  struct Message
    kind : CallKind
    flags : UInt32
    depth : Int32
    gas : Int64
    destination : Address
    sender : Address
    input_data : UInt8*
    input_size : LibC::SizeT
    value : StaticArray(UInt8, 32)
    create2_salt : StaticArray(UInt8, 32)
  end

  fun execute = "_ZN6evmone7executeEP7evmc_vmPK19evmc_host_interfaceP17evmc_host_context13evmc_revisionPK12evmc_messagePKhm"(Void*, HostInterface*, HostContext*, Revision, Message*, UInt8*, LibC::SizeT) : Result
end
