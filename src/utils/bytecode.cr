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
