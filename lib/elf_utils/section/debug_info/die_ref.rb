module ElfUtils
  class Section::DebugInfo::DieRef
    def initialize(cu, offset)
      @cu = cu
      @offset = offset
    end

    def deref
      @die ||= @cu.die(@offset + @cu.offset)
    end

    def inspect
      if (die = deref)
        "<%p cu=0x%x, offset=0x%08x, die=(0x%08x %s)>" %
          [self.class, @cu.offset, @offset, die.offset, die.tag]
      else
        "<%p cu=0x%x, offset=0x%x, die=:invalid>" %
          [self.class, @cu.offset, @offset]
      end
    end
  end
end
