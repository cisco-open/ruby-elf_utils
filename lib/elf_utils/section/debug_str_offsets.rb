module ElfUtils
  class Section::DebugStrOffsets < Section::Base
    def get(base:, offset:, format:)
      type = case format
      when :dwarf32
        CTypes::UInt32.with_endian(@file.endian)
      when :dwarf64
        CTypes::UInt64.with_endian(@file.endian)
      else
        raise Error, "unsupported format: %p" % [format]
      end
      pos = base + offset * type.size
      type.unpack(bytes[pos..])
    end
  end
end
