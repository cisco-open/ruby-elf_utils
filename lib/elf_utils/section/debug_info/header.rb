module ElfUtils
  class Section::DebugInfo::Header < CTypes::Union
    extend Forwardable
    include CTypes::Helpers

    layout do
      member :unit, Types::Dwarf::UnitHeader
      member :dwarf32_v2, Types::Dwarf32::V2::CU_Header
      member :dwarf32_v3, Types::Dwarf32::V3::CU_Header
      member :dwarf32_v4, Types::Dwarf32::V4::CU_Header
      member :dwarf32_v5, Types::Dwarf32::V5::CU_Header
      member :dwarf64_v3, Types::Dwarf64::V3::CU_Header
      member :dwarf64_v4, Types::Dwarf64::V4::CU_Header
      member :dwarf64_v5, Types::Dwarf64::V5::CU_Header

      size { |header| header[:unit].unit_size }
    end
    def_delegators :unit, :format, :version

    def inner
      # PERF: we're caching this here because the Union type will do a bunch of
      # extra work if we keep accessing the union via different members.
      @inner ||= send(:"#{format}_v#{version}").freeze
    end
  end
end
