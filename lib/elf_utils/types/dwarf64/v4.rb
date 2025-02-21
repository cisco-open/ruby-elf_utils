# frozen_string_literal: true

require "ctypes"

module ElfUtils::Types::Dwarf64::V4
  extend CTypes::Helpers

  class CU_Header < CTypes::Struct # standard:disable Naming/ClassAndModuleCamelCase
    layout do
      attribute :_dw64_flag, uint32
      attribute :unit_length, uint64
      attribute :version, uint16
      attribute :debug_abbrev_offset, uint64
      attribute :addr_size, uint8
      attribute :data, string(trim: false)
      size { |h| offsetof(:version) + h[:unit_length] }
    end

    def format
      :dwarf64
    end
  end

  class LineNumberProgramHeader < CTypes::Struct
    layout do
      attribute :_marker, uint32
      attribute :unit_length, uint64
      attribute :version, uint16
      attribute :header_length, uint64
      attribute :minimum_instruction_length, uint8
      attribute :maximum_operations_per_instruction, uint8
      attribute :default_is_stmt, uint8
      attribute :line_base, int8
      attribute :line_range, uint8
      attribute :opcode_base, uint8
      attribute :_rest, string(trim: false)
    end

    def addr_type
      CTypes::Helpers.uint64.with_endian(@endian)
    end
  end
end
