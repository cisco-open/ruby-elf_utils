module ElfUtils
  class Segment::Base
    def initialize(file, header)
      @file = file
      @header = header
      @offset = 0
    end

    def type
      @header.p_type
    end

    def addr
      @header.p_vaddr + @offset
    end

    def offset
      @header.p_offset
    end

    def filesize
      @header.p_filesz
    end

    def size
      @header.p_memsz
    end

    def align
      @header.p_align
    end

    def flags
      @header.p_flags
    end

    def to_range
      addr...(addr + size)
    end

    def inspect
      @header.inspect
    end

    def sections
      a = addr...(addr + size)
      @file.sections.select do |section|
        next unless section.alloc?
        a.include?(section.addr) ||
          a.include?(section.addr + section.size - 1)
      end
    end

    # relocate this segement and all sections within it
    #
    # @param addr address for section; `nil` clears relocation
    def relocate(addr)
      if addr.nil?
        sections.relocate(nil)
        @offset = 0
        return
      end

      # calculate the offset, then relocate the sections by that offset
      offset = addr - @header.p_vaddr
      sections.each do |section|
        section.relocate(offset, relative: true)
      end
      @offset = offset
    end
  end
end
