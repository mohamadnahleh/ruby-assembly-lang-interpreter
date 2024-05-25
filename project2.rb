# Mohamad Nahleh

# Class represents a register (the accumulator and data register) which holds a single data value.
class Registers
  attr_accessor :data

  # Initializes the register with a default value of 0.
  def initialize
    @data = 0
  end
end

# Class represents an abstract language interpreter (ALI) with various attributes and methods.
class ALI
  attr_accessor :symbol_table,  :terminate, :memory, :accumulator, :data_register, :program_counter, :zero_bit, :overflow_bit

  # Initializes the ALI with default values for its attributes.
  def initialize
    @terminate = false
    @symbol_table = {}
    @memory = Array.new(256) { nil }
    @accumulator = Registers.new
    @data_register = Registers.new
    @program_counter = 0
    @zero_bit = false
    @overflow_bit = false
  end

  # Loads instructions from a file into memory.
  def loading_file(file_name)
    File.readlines(file_name).each_with_index do |line, index|
      line.strip!
      memory[index] = new_instr(line.split[0].upcase, line.split[1..-1])
    end
  end

  # Creates a new instruction based on its name and operands.
  def new_instr(name, operands)
    # Determine the instruction type based on the name and instantiate the appropriate class.
    if name == 'DEC'
      DecInstruction.new(self, name, *operands)
    elsif name == 'LDA'
      LdaInstruction.new(self, name ,operands.first)
    elsif name == 'LDI'
      LdiInstruction.new(self, name , operands.first.to_i)
    elsif name == 'STR'
      StrInstruction.new(self, name ,  *operands)
    elsif name == 'XCH'
      XchInstruction.new(self , name)
    elsif name == 'JMP'
      JmpInstruction.new(self, name , operands.first.to_i)
    elsif name == 'JZS'
      JzsInstruction.new(self, name , operands.first.to_i)
    elsif name == 'LVS'
      JvsInstruction.new(self, name ,operands.first.to_i)
    elsif name == 'ADD'
      AddInstruction.new(self , name)
    elsif name == 'SUB'
      SubInstruction.new(self, name)
    elsif name == 'HLT'
      HltInstruction.new(self , name)
    end
  end

  # Prints the contents of instruction memory, registers, and data memory.
  def printing
    instruction_memory
    registers
    data_memory
  end

  # Prints the contents of registers.
  def registers
    puts "\n>>>>> REGISTERS <<<<<"
    puts "Accumulator    : #{conversion(@accumulator.data)}"
    puts "Data register  : #{conversion(@data_register.data)}"
    puts "Program Counter: #{conversion(@program_counter)}"
    puts "Zero Flag      : #{@zero_bit ? '1' : '0'}"
    puts "Overflow Flag  : #{@overflow_bit ? '1' : '0'}"
  end

  # Prints the contents of instruction memory.
  def instruction_memory
    puts "\n>>>>> Instruction Memory (Source Code) <<<<<"
    @memory[0..127].each_with_index do |data, index|
      puts "#{index}- #{data}" unless data.nil?
    end
  end

  # Prints the contents of data memory.
  def data_memory
    puts "\n>>>>> Data Memory <<<<<"
    @memory[128..255].each_with_index do |data, index|
      puts "#{index+128}- #{@symbol_table.invert[index+128]}: #{data}" unless data.nil?
    end
  end

  # Executes all instructions in memory until termination or end of program.
  def execute_all_instr
    @count = 0
    loop do
      break if terminate || program_counter >= memory.size
      execute_single_instr(false)
    end
    printing
  end

  # Executes a single instruction.
  def execute_single_instr(x = true)
    @count ||= 0
    @count += 1

    # Limit the number of executed instructions to prevent infinite loops.
    if @count > 1000
      puts "Limit reached! Exceeded 999 instructions."
      @terminate = true
      return
    end

    # Check for termination or end of program.
    return if terminate || (program_counter >= memory.size)

    # Fetch the instruction from memory and execute it.
    instr = memory[program_counter]
    if instr
      increment_or_not = instr.execute
      self.program_counter += 1 if increment_or_not
    end
    printing if x
  end

  # Creates an address for a symbol in the symbol table.
  def make_address(symbol)
    @symbol_table[symbol] ||= (@symbol_table.length + 128)
  end

  # Converts a value to a specific format
  def conversion(value)
    hash = { hexadecimal: ->(val) { "0x#{val.to_s(16)}" }, }
    style = hash[:decimal] || ->(val) { val.to_s }
    style.call(value)
  end
end

# The command loop for interacting with the ALI interpreter.
def command_loop
  puts "Enter filename: "
  file_name = gets.chomp.downcase

  interpreter = ALI.new
  interpreter.loading_file(file_name)

  loop do
    puts "Enter command (s , q , a): "
    instr = gets.chomp.downcase
    if instr == 's'
      interpreter.execute_single_instr(true)
    elsif instr == 'q'
      puts "Exiting Program."
      break
    elsif instr == 'a'
      interpreter.execute_all_instr
    else
      puts "Invalid command. Enter command (s , q , a): "
    end
    break if interpreter.terminate
  end
end

# This class represents an abstract instruction.
class Instruction
  def initialize(ali , opcode)
    @ali = ali
    @opcode = opcode
  end

  # Executes the instruction (to be implemented by subclasses).
  def execute
  end
end

# Declares a symbolic variable consisting of a sequence of letters (e.g., sum). The
# variable is stored at an available location in data memory
class DecInstruction < Instruction
  def initialize(ali, opcode ,symbol)
    super(ali, opcode)
    @symbol = symbol
    @opcode = opcode
  end

  def execute
    address = @ali.make_address(@symbol)
    @ali.memory[address] = 0 unless @ali.memory[address]
  end

  def to_s
    "#{@opcode} #{@symbol}"
  end
end

# Loads word at data memory address of symbol into the accumulator.
class LdaInstruction < Instruction
  def initialize(ali, opcode ,symbol)
    super(ali, opcode)
    @symbol = symbol
    @opcode = opcode
  end

  def execute
    if (128..255).cover?(@ali.make_address(@symbol))
      @ali.accumulator.data = @ali.memory[@ali.make_address(@symbol)] || 0
    end
  end

  def to_s
    "#{@opcode} #{@symbol}"
  end
end

# Loads the integer value into the accumulator register. The value could be negative
class LdiInstruction < Instruction
  def initialize(ali, opcode, value)
    super(ali , opcode)
    @value = value
    @opcode = opcode
  end

  def execute
    @ali.accumulator.data = @value
    true
  end

  def to_s
    "#{@opcode} #{@value}"
  end
end

# Stores content of accumulator into data memory at address of symbol.
class StrInstruction < Instruction
  def initialize(ali, opcode, symbol)
    super(ali , opcode)
    @symbol = symbol
    @opcode = opcode
  end

  def execute
    if (128..255).cover?(@ali.make_address(@symbol))
      @ali.memory[@ali.make_address(@symbol)] = @ali.accumulator.data
    end
  end

  def to_s
    "#{@opcode} #{@symbol}"
  end
end

# Exchanges the content registers A and B
class XchInstruction < Instruction
  def initialize(ali, opcode)
    super(ali , opcode)
    @opcode = opcode
  end
  def execute
    temp = @ali.accumulator.data
    @ali.accumulator.data = @ali.data_register.data
    @ali.data_register.data = temp
    true
  end

  def to_s
    "#{@opcode}"
  end
end

# Transfers control to instruction at address number in program memory
class JmpInstruction < Instruction
  def initialize(ali, opcode , address)
    super(ali , opcode)
    @address = address
    @opcode = opcode
  end

  def execute
    @ali.program_counter = @address
    false
  end

  def to_s
    "#{@opcode} #{@address}"
  end
end

# Transfers control to instruction at address number if the zero-result bit is set.
class JzsInstruction < Instruction
  def initialize(ali, opcode , address)
    super(ali , opcode)
    @address = address
    @opcode = opcode
  end

  def execute
    if @ali.zero_bit
      @ali.program_counter = @address
      false
    else
      true
    end
  end

  def to_s
    "#{@opcode} #{@address}"
  end
end

# Transfers control to instruction at address number if the overflow bit is set.
class JvsInstruction <Instruction
  def initialize(ali, opcode , address)
    super(ali , opcode)
    @address = address
    @opcode = opcode
  end

  def execute
    if @ali.overflow_bit
      @ali.program_counter = @address
      false
    else
      true
    end
  end

  def to_s
    "#{@opcode} #{@address}"
  end
end

# Adds the content of registers A and B. The sum is stored in A. The overflow and
# zero-result bits are set or cleared as needed.
class AddInstruction < Instruction
  def initialize(ali, opcode )
    super(ali , opcode)
    @opcode = opcode
  end
  def execute
    @ali.accumulator.data += @ali.data_register.data
    @ali.overflow_bit = @ali.accumulator.data > 2**31 - 1 || @ali.accumulator.data < -2**31
    @ali.zero_bit = @ali.accumulator.data.zero?
    true
  end

  def to_s
    "#{@opcode}"
  end
end

# The content of register B is subtracted from A. The difference is stored in A.
# The overflow and zero-result bits are set or cleared as needed.
class SubInstruction < Instruction
  def initialize(ali, opcode)
    super(ali , opcode)
    @opcode = opcode
  end
  def execute
    @ali.accumulator.data -= @ali.data_register.data
    @ali.overflow_bit = @ali.accumulator.data > 2**31 - 1 || @ali.accumulator.data < -2**31
    @ali.zero_bit = @ali.accumulator.data.zero?
    true
  end

  def to_s
    "#{@opcode}"
  end
end

# Terminates program execution.
class HltInstruction < Instruction
  def initialize(ali, opcode )
    super(ali , opcode)
    @opcode = opcode
  end
  def execute
    @ali.terminate = true
    false
  end

  def to_s
    "#{@opcode}"
  end
end

command_loop