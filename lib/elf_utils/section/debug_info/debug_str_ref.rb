module ElfUtils
  class Section::DebugInfo::DebugStrRef
    def initialize(cu, offset)
      @cu = cu
      @offset = offset
    end

    def deref
      @str ||= @cu.file.section(".debug_str")[@offset]
    end

    def inspect
      "<%p cu=0x%x, offset=0x%08x, str=%p>" %
        [self.class, @cu.offset, @offset, deref]
    end
  end
end
