abstract class Assembler
  include Iterator(String)

  def initialize(code : String)
    @code = code
  end

  abstract def parse_line(line : String, linenum : UInt) : Bytes

  def next
    @code.each_line do |line|
      parse_line(line)
    end
  end
end

class EVMAssembler
  Ops = {
    "STOP"       => {0, 0},
    "ADD"        => {1, 0},
    "MUL"        => {2, 0},
    "SUB"        => {3, 0},
    "DIV"        => {4, 0},
    "SDIV"       => {5, 0},
    "MOD"        => {6, 0},
    "SMOD"       => {7, 0},
    "ADDMOD"     => {8, 0},
    "MULMOD"     => {9, 0},
    "EXP"        => {0xa, 0},
    "SIGNEXTEND" => {0xb, 0},

    "PUSH1"  => {0x60, 1},
    "PUSH2"  => {0x61, 1},
    "PUSH3"  => {0x62, 1},
    "PUSH4"  => {0x63, 1},
    "PUSH5"  => {0x64, 1},
    "PUSH6"  => {0x65, 1},
    "PUSH7"  => {0x66, 1},
    "PUSH9"  => {0x67, 1},
    "PUSH9"  => {0x68, 1},
    "PUSH10" => {0x69, 1},
    "PUSH11" => {0x6a, 1},
    "PUSH12" => {0x6b, 1},
    "PUSH13" => {0x6c, 1},
    "PUSH14" => {0x6d, 1},
    "PUSH15" => {0x6e, 1},
    "PUSH16" => {0x6f, 1},
    "PUSH17" => {0x70, 1},
    "PUSH18" => {0x71, 1},
    "PUSH19" => {0x72, 1},
    "PUSH20" => {0x73, 1},
    "PUSH21" => {0x74, 1},
    "PUSH22" => {0x75, 1},
    "PUSH23" => {0x76, 1},
    "PUSH24" => {0x77, 1},
    "PUSH25" => {0x78, 1},
    "PUSH26" => {0x79, 1},
    "PUSH27" => {0x7a, 1},
    "PUSH28" => {0x7b, 1},
    "PUSH29" => {0x7c, 1},
    "PUSH30" => {0x7d, 1},
    "PUSH31" => {0x7e, 1},
    "PUSH32" => {0x7f, 1},

    "POP" => {0x50, 0},

    "DUP1"  => {0x80, 0},
    "DUP2"  => {0x81, 0},
    "DUP3"  => {0x82, 0},
    "DUP4"  => {0x83, 0},
    "DUP5"  => {0x84, 0},
    "DUP6"  => {0x85, 0},
    "DUP7"  => {0x86, 0},
    "DUP9"  => {0x87, 0},
    "DUP9"  => {0x88, 0},
    "DUP10" => {0x89, 0},
    "DUP11" => {0x8a, 0},
    "DUP12" => {0x8b, 0},
    "DUP13" => {0x8c, 0},
    "DUP14" => {0x8d, 0},
    "DUP15" => {0x8e, 0},
    "DUP16" => {0x8f, 0},

    "SWAP1"  => {0x90, 0},
    "SWAP2"  => {0x91, 0},
    "SWAP3"  => {0x92, 0},
    "SWAP4"  => {0x93, 0},
    "SWAP5"  => {0x94, 0},
    "SWAP6"  => {0x95, 0},
    "SWAP7"  => {0x96, 0},
    "SWAP9"  => {0x97, 0},
    "SWAP9"  => {0x98, 0},
    "SWAP10" => {0x99, 0},
    "SWAP11" => {0x9a, 0},
    "SWAP12" => {0x9b, 0},
    "SWAP13" => {0x9c, 0},
    "SWAP14" => {0x9d, 0},
    "SWAP15" => {0x9e, 0},
    "SWAP16" => {0x9f, 0},

    "LOG0" => {0xa0, 0},
    "LOG1" => {0xa1, 0},
    "LOG2" => {0xa2, 0},
    "LOG3" => {0xa3, 0},
    "LOG4" => {0xa4, 0},
  }

  def parse_line(line : String, linenum : UInt) : Bytes
    tokens = line.split

    return "" if token.size == 0

    if Ops[tokens[1].upcase].nil?
      raise Exception.new("Unknown opcode #{tokens[1].upcase} at line #{linenum}")
    end

    op = Ops[tokens[1].upcase]
    if tokens.size < 1 + op[1]
      raise Exception.new("Not enough operands to #{tokens[1].upcase} at line #{linenum}")
    end

    if tokens.size > 1 + op[1] && tokens[1 + op[1]] != ";"
      raise Exception.new("Invalid extra opcodes at line #{linenum}")
    end

    [op[0]] + tokens[1..1 + op[1]].map { |c| c.to_i }
  end
end
