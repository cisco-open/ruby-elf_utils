module ElfUtils
  class Section::DebugLine::LineNumberProgram::Header < CTypes::Union
    extend Forwardable
    include CTypes::Helpers

    # struct used for `directory_entry_format` and `file_name_entry_format` in
    # DWARF v5.
    EntryFormat = CTypes::Helpers.struct(
      type: Types::Dwarf::EntryFormatType,
      form: Types::Dwarf::Form
    )

    # entry format for `include_directories` prior to DWARF v5
    INCLUDE_DIRECTORIES_FORMAT = [EntryFormat.new(type: :path, form: :string)]

    # entry format for `file_names` prior for DWARF v5
    FILE_NAMES_FORMAT = [
      EntryFormat.new(type: :path, form: :string),
      EntryFormat.new(type: :directory_index, form: :udata),
      EntryFormat.new(type: :timestamp, form: :udata),
      EntryFormat.new(type: :size, form: :udata)
    ]

    layout do
      member :unit, Types::Dwarf::UnitHeader
      member :dwarf32_v2, Types::Dwarf32::V2::LineNumberProgramHeader
      member :dwarf32_v3, Types::Dwarf32::V3::LineNumberProgramHeader
      member :dwarf32_v4, Types::Dwarf32::V4::LineNumberProgramHeader
      member :dwarf32_v5, Types::Dwarf32::V5::LineNumberProgramHeader
      member :dwarf64_v3, Types::Dwarf64::V3::LineNumberProgramHeader
      member :dwarf64_v4, Types::Dwarf64::V4::LineNumberProgramHeader
      member :dwarf64_v5, Types::Dwarf64::V5::LineNumberProgramHeader

      size do |union|
        type = union[:unit].type
        header = union[type]
        header.class.offsetof(:minimum_instruction_length) +
          header[:header_length]
      end
    end
    def_delegators :inner, :version, :type
    def_delegators :unit, :format, :addr_type

    def inner
      @inner = send(unit.type)
    end
  end
end
