module ElfUtils
  class Section::Base
    def initialize(file, header)
      @file = file
      @header = header
      @offset = 0
    end
    attr_reader :header

    def name
      @file.shstrtab[@header.sh_name]
    end

    def inspect
      "<%p %s %p 0x%08x %p>" % [self.class, name, @header.sh_type, addr, flags]
    end

    def bytes
      @file.pread(@header.sh_size, @header.sh_offset)
    end

    def addr
      @header.sh_addr + @offset
    end

    def size
      @header.sh_size
    end

    def flags
      @header.sh_flags
    end

    def offset
      @header.sh_offset
    end

    def alloc?
      flags.include?(:alloc)
    end

    def to_range
      (addr...addr + size)
    end

    def symbols
      @file.symtab.symbols.select { |s| s.section == self }
    end

    def symbol(name)
      @file.symtab.symbols.find { |s| s.section == self && s.name == name }
    end

    # relocate this section
    #
    # @param addr address for section; `nil` clears relocation
    def relocate(addr, relative: false)
      @offset = if addr.nil?
        0
      elsif relative
        addr
      else
        addr - @header.sh_addr
      end
    end

    # return the relocation offset for this section
    def relocation_offset
      @offset
    end

    # get the load_segment this section belongs to
    def load_segment
      @file.load_segments.find { |s| s.sections.include?(self) }
    end
  end
end
