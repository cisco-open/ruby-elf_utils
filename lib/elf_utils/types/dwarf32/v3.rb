# frozen_string_literal: true

require "ctypes"

module ElfUtils::Types::Dwarf32::V3
  extend CTypes::Helpers

  class CU_Header < CTypes::Struct # standard:disable Naming/ClassAndModuleCamelCase
    layout do
      attribute :unit_length, uint32
      attribute :version, uint16
      attribute :debug_abbrev_offset, uint32
      attribute :addr_size, uint8
      attribute :data, string(trim: false)
      size { |h| offsetof(:version) + h[:unit_length] }
    end

    def format
      :dwarf32
    end
  end

  class LineNumberProgramHeader < CTypes::Struct
    layout do
      attribute :unit_length, uint32
      attribute :version, uint16
      attribute :header_length, uint32
      attribute :minimum_instruction_length, uint8
      attribute :default_is_stmt, uint8
      attribute :line_base, int8
      attribute :line_range, uint8
      attribute :opcode_base, uint8
      attribute :_rest, string(trim: false)
    end

    def addr_type
      CTypes::Helpers.uint32.with_endian(@endian)
    end
  end
end
