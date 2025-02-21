class ElfUtils::Section::DebugLine
  class LineNumberProgram
    include CTypes::Helpers

    def initialize(file:, offset:, header:, body:)
      @file = file
      @offset = offset
      @header = header
      @body = body
    end
    attr_reader :body, :file, :header

    def addr_type
      @header.addr_type
    end

    def standard_opcode_lengths
      unpack_header_tail unless @standard_opcode_lengths
      @standard_opcode_lengths
    end

    def directories
      unpack_header_tail unless @directories
      @directories
    end

    def file_names
      unpack_header_tail unless @file_names
      @file_names
    end

    def file_name(index)
      file_name = file_names[index]
      dir = directories[file_name[:directory_index]]
      File.join(dir[:path], file_name[:path])
    end

    def address_table
      @address_table ||= begin
        state = StateMachine.new(self)
        state.process(body).each_with_object({}) do |entry, o|
          o[entry.address] = entry.freeze
        end.freeze
      end
    end

    def source_location(addr)
      entry = address_table[addr] || return
      {
        file: file_name(entry.file),
        line: entry.line,
        column: entry.column
      }
    end

    private

    def unpack_header_tail
      buf = header._rest
      @standard_opcode_lengths, buf = array(uint8, header.opcode_base - 1)
        .unpack_one(buf)
      @standard_opcode_lengths.unshift(nil)

      # unpack directory entries
      if header.version < 5
        @directories, buf = unpack_terminated_entries(buf,
          Header::INCLUDE_DIRECTORIES_FORMAT)

        # Prior to DWARF v5, the include directories were 1-indexed.  Insert a
        # nil at index 0, shifting all the entires up one index.
        @directories.unshift(nil)
      else
        format, count, buf = unpack_format_and_count(buf)
        @directories, buf = unpack_count_entries(buf, format, count)
      end

      # unpack file_name entries
      if header.version < 5
        @file_names, = unpack_terminated_entries(buf, Header::FILE_NAMES_FORMAT)
        @file_names.unshift(nil)
      else
        format, count, buf = unpack_format_and_count(buf)
        @file_names, = unpack_count_entries(buf, format, count)
      end
    end

    def unpack_format_and_count(buf)
      format_count, buf = uint8.unpack_one(buf)
      format, buf = array(Header::EntryFormat, format_count).unpack_one(buf)
      count, buf = ElfUtils::Types::ULEB128.unpack_one(buf)
      [format, count, buf]
    end

    def unpack_count_entries(buf, format, count)
      entries = count.times.map do
        entry, buf = unpack_entry(buf, format)
        entry
      end
      [entries, buf]
    end

    def unpack_terminated_entries(buf, format)
      entries = []
      until buf[0] == "\0"
        entry, buf = unpack_entry(buf, format)
        entries << entry
      end
      [entries, buf[1..]]
    end

    def unpack_entry(buf, format)
      entry = {}
      format.each do |field|
        case field.form
        when :string
          entry[field.type], buf = string.terminated.unpack_one(buf)
        when :line_strp
          offset, buf = addr_type.unpack_one(buf)
          entry[field.type] = @file.section(".debug_line_str")[offset]
        when :udata
          entry[field.type], buf = ElfUtils::Types::ULEB128.unpack_one(buf)
        when :data16
          entry[field.type], buf = string(16, trim: false).unpack_one(buf)
        else
          raise ElfUtils::Error, "unsupported entry field form: %p" % [field]
        end
      end
      [entry, buf]
    end
  end
end

require_relative "line_number_program/header"
require_relative "line_number_program/state_machine"
