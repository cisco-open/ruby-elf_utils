module ElfUtils
  class Section::DebugInfo::DebugStrOffsetsRef
    def initialize(cu, offset)
      @cu = cu
      @offset = offset
    end

    def deref
      base = @cu.root_die.str_offsets_base
      str_offset = @cu.file.section(".debug_str_offsets")
        .get(base:, offset: @offset, format: @cu.format)
      @cu.file.section(".debug_str")[str_offset]
    end
  end
end
