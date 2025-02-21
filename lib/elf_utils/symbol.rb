module ElfUtils
  # Represents a symbol found in an ELF file.
  class Symbol
    # @param file [ElfFile] ElfFile that declared this symbol
    # @param symbol [Integer] symbol index in symbol table
    # @param strtab [Section::Strtab] string table to lookup symbol name in
    # @api private
    def initialize(file, symbol, strtab = file.strtab)
      @file = file
      @sym = symbol
      @strtab = strtab
    end

    # @api private
    attr_reader :file

    # get the name of the symbol
    # @return [String, nil] symbol name
    def name
      @name ||= @strtab[@sym.st_name]
    end

    # get the ELF section this symbol resides in
    # @return [Section::Base]
    def section
      @file.sections[@sym.st_shndx]
    end

    # get the symbol type
    # @return [Symbol] symbol type
    # @see Types::Elf_Stt
    def type
      Types::Elf_Stt[@sym.st_info & 0xf] or
        raise Error, "invalid symbol table type: %p", @sym.st_info & 0xf
    end

    # get the address of the symbol
    #
    # This method will return the address of the symbol in memory, taking into
    # account any relocation performed on the section or load segment.
    #
    # @return [Integer] address of the symbol in memory
    # @see Segment::Base#relocate
    # @see Section::Base#relocate
    def addr
      if @sym.st_shndx == Types::SHN_COMMON
        nil
      elsif @sym.st_shndx == Types::SHN_ABS
        @sym.st_value
      elsif @file.relocatable?
        @sym.st_value + section.addr
      else
        @sym.st_value + section.relocation_offset
      end
    end

    # get the offset of this symbol within the ELF section
    # @return [Integer] offset in bytes from the start of the ELF section
    def section_offset
      addr - section.addr
    end

    # get the size of this symbol in memory
    # @return [Integer] size in bytes of this symbol
    def size
      @sym.st_size
    end

    # get the range of memory addresses this symbol occupies in memory
    # @return [Range]
    def to_range
      addr = self.addr || 0
      (addr...addr + size)
    end

    # get the CType datatype instance for the variable declared in this symbol
    # @return [CType::Type] datatype instance
    # @see https://rubydoc.info/gems/ctypes
    #
    # @example
    #   elf_file = ElfUtils.open("spec/data/complex_64be-dwarf64-v5")
    #   symbol = elf_file.symbol("my_tlv")      # => #<ElfUtils::Symbol ...>
    #   ctype = symbol.ctype                    # => #<CTypes::Struct ... >
    #   tlv = ctype.unpack("\1\bhello world")   # => {  type: 1,
    #                                           # =>     len: 11,
    #                                           # =>   value: "hello world" }
    def ctype
      return nil unless type == :object && (debug_info = @file.debug_info)

      name = self.name
      addr = self.addr
      die = debug_info.dies(top: true).find do |die|
        die.tag == :variable &&
          die[:name] == name &&
          die.location == addr
      end or return nil
      die[:type]&.ctype
    end

    # get the source location for an :object or :func symbol
    # @return [Hash<file, line>]
    #
    # @example
    #   elf_file = ElfUtils.open("spec/data/complex_64be-dwarf64-v5")
    #   symbol = elf_file.symbol("main")    # => #<ElfUtils::Symbol ...>
    #   symbol.source_location              # => { file: "test.c", line: 13 }
    def source_location
      # look up the CU die, and the die for this object
      name = self.name
      addr = self.addr
      cu_die = nil
      die = @file.debug_info
        .dies(root: true, top: true)
        .find do |die|
          cu_die = die if die.tag == :compile_unit
          die[:name] == name && die.has_addr?(addr)
        end or return

      # get the line number program for the compilation unit
      lnp = @file
        .section(".debug_line")
        &.line_number_program(cu_die[:stmt_list]) or return

      # based on the type of symbol, we have different ways of looking up the
      # source location
      case type
      when :func
        lnp.source_location(addr)
      when :object
        {
          file: lnp.file_name(die[:decl_file]),
          line: die[:decl_line]
        }
      end
    end

    def inspect
      "<%p %-7p %-18s %s, 0x%08x>" %
        [self.class, type, section&.name, name, addr]
    rescue
      @sym.inspect
    end
  end
end
