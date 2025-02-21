module ElfUtils
  class Section::DebugAddr < Section::Base
    def get(base:, index:)
      @addr_type ||= @file.elf_type(:Addr)
      offset = base + index * @addr_type.size
      @addr_type.unpack(bytes[offset..])
    end
  end
end
