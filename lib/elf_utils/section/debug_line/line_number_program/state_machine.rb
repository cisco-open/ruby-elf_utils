class ElfUtils::Section::DebugLine
  class LineNumberProgram::StateMachine
    include CTypes::Helpers

    StandardOpCodes = ElfUtils::Types::Dwarf::StandardOpCodes
    ExtendedOpCodes = ElfUtils::Types::Dwarf::ExtendedOpCodes
    ULEB128 = ElfUtils::Types::ULEB128
    SLEB128 = ElfUtils::Types::SLEB128

    StateRegisters = Struct.new("StateRegisters", :address, :op_index, :file,
      :line, :column, :is_stmt, :basic_block, :end_sequence, :prologue_end,
      :epilogue_begin, :isa, :discriminator, keyword_init: true) do
        def initialize(args)
          # save off values we need for `#advance`
          @maximum_operations_per_instruction =
            args.delete(:maximum_operations_per_instruction)
          @minimum_instruction_length = args.delete(:minimum_instruction_length)

          # add the hard-coded defaults
          args.merge!(
            address: 0,
            op_index: 0,
            file: 1,
            line: 1,
            column: 0,
            basic_block: false,
            end_sequence: false,
            prologue_end: false,
            epilogue_begin: false,
            isa: 0,
            discriminator: 0
          )

          # save off the initial values to support `#reset`
          @initial_values = args
          super
        end

        # advance `address` & `op_index` by the provided `operation_advance`
        def advance(operation_advance)
          self.address += @minimum_instruction_length *
            ((op_index + operation_advance) /
              @maximum_operations_per_instruction)
          self.op_index = (op_index + operation_advance) %
            @maximum_operations_per_instruction
        end

        # reset the registers to their initial values
        def reset
          @initial_values.each { |k, v| self[k] = v }
        end

        def flags
          flags = []
          %i[is_stmt basic_block end_sequence prologue_end epilogue_begin]
            .each { |f| flags << f if send(f) }
          flags
        end

        def to_s
          "0x%016x %6d %6d %6d %3d %13d  %s" % [
            address, line, column, file, isa, discriminator, flags.join(" ")
          ]
        end
      end

    def initialize(program)
      @opcode_base = program.header.opcode_base
      @standard_opcode_lengths = program.standard_opcode_lengths
      @special_opcodes = build_special_opcode_table(program.header)
      @addr_type = program.file.elf_type(:Addr)

      # initial state
      @initial_registers = StateRegisters.new(
        minimum_instruction_length: program.header.minimum_instruction_length,
        maximum_operations_per_instruction: (program.header.version >= 4) ?
            program.header.maximum_operations_per_instruction : 1,
        is_stmt: program.header.default_is_stmt == 1
      ).freeze
    end

    def process(opcodes)
      buf = opcodes
      opcode_base = @opcode_base
      matrix = []
      registers = @initial_registers.dup

      # TODO merge unpack & eval steps for extended & special opcodes
      until buf.empty?
        byte = uint8.unpack(buf)
        if byte == 0
          opcode, args, buf = unpack_extended_op(buf[1..])
          eval_extended_opcode(matrix, registers, opcode, args)
        elsif byte < opcode_base
          buf = eval_standard_opcode(buf, matrix, registers)
        else
          opcode, buf = byte, buf[1..]
          opcode = @special_opcodes[opcode]
          eval_special_opcode(matrix, registers, opcode)
        end
      end

      matrix
    end

    private

    # construct a special opcode table to lookup the values for each special
    # opcode
    def build_special_opcode_table(program_header)
      opcode_base = program_header.opcode_base

      (opcode_base..255).each_with_object([]) do |opcode, o|
        adjusted_opcode = opcode - opcode_base

        o[opcode] = {
          line_increment: program_header.line_base +
            (adjusted_opcode % program_header.line_range),
          operation_advance: adjusted_opcode / program_header.line_range
        }
        o
      end
    end

    def unpack_extended_op(buf)
      size, buf = ULEB128.unpack_one(buf)
      opcode, buf = uint8.unpack_one(buf)
      args, buf = if size > 1
        string(size - 1, trim: false).unpack_one(buf)
      else
        ["", buf]
      end
      [ExtendedOpCodes[opcode] || opcode, args, buf]
    end

    def eval_special_opcode(matrix, reg, opcode)
      reg.advance(opcode[:operation_advance])
      reg.line += opcode[:line_increment]
      matrix << reg.dup
      reg.basic_block = false
      reg.prologue_end = false
      reg.epilogue_begin = false
      reg.discriminator = 0
    end

    def eval_standard_opcode(buf, matrix, reg)
      opcode, buf = uint8.unpack_one(buf)
      case StandardOpCodes[opcode]
      when :copy
        matrix << reg.dup
        reg.discriminator = 0
        reg.basic_block = false
        reg.prologue_end = false
        reg.epilogue_begin = false
      when :advance_pc
        operation_advance, buf = ULEB128.unpack_one(buf)
        reg.advance(operation_advance)
      when :advance_line
        lines, buf = SLEB128.unpack_one(buf)
        reg.line += lines
      when :set_file
        reg.file, buf = ULEB128.unpack_one(buf)
      when :set_column
        reg.column, buf = ULEB128.unpack_one(buf)
      when :negate_stmt
        reg.is_stmt = !reg.is_stmt
      when :set_basic_block
        reg.basic_block = true
      when :const_add_pc
        reg.advance(@special_opcodes[255][:operation_advance])
      when :fixed_advance_pc
        offset, buf = uint16.unpack_one(buf)
        reg.address += offset
        reg.op_index = 0
      when :set_prologue_end
        reg.prologue_end = true
      when :set_epilogue_begin
        reg.epilogue_begin = true
      when :set_isa
        reg.isa, buf = ULEB128.unpack_one(buf)
      else
        # for unsupported opcodes, skip the arguments
        _, buf = array(ULEB128, @standard_opcode_lengths[opcode])
          .unpack_one(buf)
      end

      buf
    end

    def eval_extended_opcode(matrix, reg, opcode, args)
      case opcode
      when :end_sequence
        reg.end_sequence = true
        matrix << reg.dup
        reg.reset
      when :set_address
        reg.address = @addr_type.unpack(args)
        reg.op_index = 0
      when :set_discriminator
        reg.discriminator = ULEB128.unpack(args)
      else
        raise ElfUtils::Error, "unknown opcode: %p %p" % [opcode, args]
      end
    end
  end
end
