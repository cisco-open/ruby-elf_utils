module ElfUtils
  class Section::DebugLine < Section::Base
    def line_number_programs
      out = []
      buf = bytes
      until buf.empty?
        program, buf = unpack_line_number_program(buf)
        out << program
      end
      out
    end

    def line_number_program(offset)
      program, = unpack_line_number_program(bytes[offset..])
      program
    end

    private

    def unpack_line_number_program(buf)
      header, rest = LineNumberProgram::Header
        .with_endian(@file.endian)
        .unpack_one(buf)
      header.freeze
      header_size = buf.size - rest.size
      body_size = header.unit.unit_size - header_size
      body = rest[0, body_size]
      program = LineNumberProgram
        .new(file: @file, offset:, header: header.inner, body:)
      [program, buf[header.unit.unit_size..]]
    end
  end
end

require_relative "debug_line/line_number_program"
