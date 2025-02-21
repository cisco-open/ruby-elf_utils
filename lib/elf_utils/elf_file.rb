require "forwardable"
require_relative "string_pread"

module ElfUtils
  # Read ELF and DWARF data from any class that provides a #pread method.
  #
  # @example dump the symbols found in an ELF file
  #   ElfUtils::ElfFile.open("spec/data/complex_64be-dwarf64-v5") do |elf_file|
  #     pp elf_file.symbols
  #   end
  #
  # @example read complex structure from running process
  #   # open an ELF file, in this case an executable
  #   elf_file = ElfUtils.open("a.out")
  #
  #   # get the Symbol instance for a global variable
  #   symbol = elf_file.symbol(:some_global_var)      # => #<ElfUtils::Symbol ...>
  #
  #   # get the address of the symbol
  #   addr = symbol.addr                              # => 0x40001000
  #
  #   # relocate the load segments to account for ASLR.  Addresses for load segments
  #   # gleaned manually from /proc/pid/map.
  #   elf_file.load_segments[0].relocate(text_addr)
  #   elf_file.load_segments[1].relocate(data_addr)
  #
  #   # get the address of the symbol after relocation
  #   addr = symbol.addr                              # => 0x90301000
  #
  #   # get the data type for the symbol; requires DWARF debug information
  #   type = symbol.ctype                             # => #<CTypes::Struct ...>
  #
  #   # open the memory for a process running this executable, and read the value of
  #   # the global variable.
  #   value = File.open(File.join("/proc", pid, "mem")) do |mem|
  #       # read the raw bytes for the variable
  #       bytes = mem.pread(type.size, addr)          # => "\xef\x99\xde... "
  #
  #       # unpack the bytes
  #       type.unpack_one(bytes)                      # => { field: val, ... }
  #   end
  class ElfFile
    extend Forwardable
    using StringPread

    # open a file path, and return an ElfFile instance
    # @overload open(path)
    #   @param path [String] file path
    #   @return [ElfFile]
    #
    # @overload open(path)
    #   @param path [String] file path
    #   @yield [ElfFile] invokes block with opened file, will close when block
    #     returns
    #
    # @example
    #   elf_file = ElfFile.open("spec/data/complex_64be-dwarf64-v5")
    #   pp(elf_file.symbols)
    #   elf_file.close
    #
    # @example
    #   ElfFile.open("spec/data/complex_64be-dwarf64-v5") do |elf_file|
    #     pp(elf_file.symbols)
    #   end
    #
    def self.open(path)
      if block_given?
        File.open(path) do |f|
          yield new(f)
        end
      else
        new(File.open(path))
      end
    end

    # create an instance of ElfFile
    # @param io [IO, String, #pread] Anything that provides
    #   the #pread(max_len, offset) method
    def initialize(io)
      io.force_encoding("ASCII-8BIT") if io.is_a?(String)
      @io = io
      @header = load_header(io)
      @type_prefix = (elf_class == :elf32) ? "Elf32" : "Elf64"
    end

    # @api private
    attr_reader :header

    # return the path of the ElfFile
    # @return [String, nil] path of the ElfFile
    def path
      @io.path if @io.respond_to?(:path)
    end

    # Return the ELF class according to the ident in the header
    # @return [Symbol] :elf32 or :elf64
    def elf_class
      case @header.e_ident.ei_class
      when Types::ELFCLASS32
        :elf32
      when Types::ELFCLASS64
        :elf64
      else
        raise InvalidFormat, "Unsupported ELF ident.ei_class: %p", @header
      end
    end

    # get the endian according to the ELF header
    # @return [Symbol] :big or :little
    def endian
      case @header.e_ident.ei_data
      when :lsb
        :little
      when :msb
        :big
      else
        raise "Invalid EI_DATA value in ELF header ident: %p", @header
      end
    end

    # check if this is a relocatable ELF file
    # @return [Boolean] true if the file is relocatable
    def relocatable?
      @header.e_type == :rel
    end

    # Get the segments
    # @return [Array<Segment::Base>] segments present in ELF file
    def segments
      @segments ||= pread([:Phdr, @header.e_phnum], @header.e_phoff).map do |hdr|
        Segment.from_header(self, hdr)
      end
    end

    # Return the list of load segments
    # @return [Array<Segment::Base>] load segments present in ELF file
    def load_segments
      segments.select { |s| s.type == :load }
    end

    # Return the .shstrtab section
    # @return [Section]
    def shstrtab
      # XXX we end up with a duplicate copy of this section, but we need to
      # get the shstrtab while building the full sections list
      @shstrtab ||= begin
        hdr_class = elf_type(:Shdr)
        offset = hdr_class.size * @header.e_shstrndx
        hdr = pread(hdr_class, @header.e_shoff + offset)
        Section.from_header(self, hdr)
      end
    end

    # Return the .strtab section
    # @return [Section::Strtab]
    def strtab
      section(".strtab")
    end

    # return the .symtab section
    # @return [Section::Symtab]
    def symtab
      @symtab ||= section(".symtab") || section(".dynsym")
    end

    # return the .symtab section
    # @return [Section::DebugInfo]
    def debug_info
      section(".debug_info")
    end

    # get the sections present in the ELF file
    # @return [Array<Section::Base>]
    def sections
      @sections ||= pread([:Shdr, @header.e_shnum], @header.e_shoff)
        .map do |hdr|
          Section.from_header(self, hdr)
        end
    end

    # lookup a section by name
    # @return [Section::Base, nil] section instance if found, nil otherwise
    def section(name)
      @sections_by_name ||= sections.each_with_object({}) do |section, cache|
        cache[section.name] = section
      end
      @sections_by_name[name]
    end

    # return the list of symbols found in the ELF file
    # @return [Array<Symbol>]
    def symbols
      symtab&.symbols || []
    end

    # lookup a symbol by name
    # @param [String, Symbol] symbol name
    # @return [Symbol, name]
    def symbol(name)
      name = name.to_s
      symbols.find { |s| s.name == name }
    end

    # lookup a symbol by memory address
    # @param [Integer] in-memory address
    # @return [Symbol, name]
    def symbol_at_addr(addr)
      symbols.find do |sym|
        next unless sym.section&.alloc?
        sym.to_range.include?(addr)
      end
    end

    # Get the ctypes datatype for a type defined in the .debug_info section
    # @param name [String] name of type
    #
    # @example lookup a structure type by name from .debug_info section
    #   ElfFile.open("spec/data/complex_64be-dwarf64-v5") do |elf_file|
    #     elf_file.type("struct tlv")
    #   end   # => #<CTypes::Struct ... >
    def type(name)
      raise Error, "File does not contain .debug_info section: #{path}" unless
        (debug_info = section(".debug_info"))
      debug_info.type(name)
    end
    alias_method :ctype, :type

    # pread wrapper providing support for type lookup by name
    # @api private
    def pread(type_or_size, offset)
      type, size = parse_type(type_or_size)
      buf = @io.pread(size, offset)
      return buf unless type
      type.unpack(buf)
    end

    # lookup the ctypes datatype for this file's bitsize (ELF32 vs ELF64)
    # @param name [Symbol, String] name of type
    # @see Types
    # @api private
    def elf_type(name)
      Types.const_get("#{@type_prefix}_#{name}").with_endian(endian)
    end

    # get the ctype that represents an address for this ELF file
    # @api private
    def addr_type
      elf_type(:Addr)
    end

    private

    # load the correct header type from the file
    # @api private
    def load_header(io)
      ident = pread(Types::Elf_Ident, 0)
      raise InvalidFormat, "Invalid ELF ident: %p" % ident unless
        ident.ei_magic == Types::ELFMAGIC
      endian = case ident.ei_data
      when :lsb
        :little
      when :msb
        :big
      else
        raise "Invalid EI_DATA value in ELF header ident: %p", @header
      end

      case ident.ei_class
      when Types::ELFCLASS32
        pread(Types::Elf32_Ehdr.with_endian(endian), 0)
      when Types::ELFCLASS64
        pread(Types::Elf64_Ehdr.with_endian(endian), 0)
      else
        raise InvalidFormat, "Unsupported ELF ident.ei_class: %p",
          ident
      end
    rescue Dry::Types::ConstraintError
      raise InvalidFormat, "Invalid ELF header"
    end

    # Return a type & size given a type or size argument; used by pread()
    # @api private
    def parse_type(type)
      case type
      when Integer
        [nil, type] # just a plain old size
      when CTypes::Type
        [type, type.size]
      when ::Symbol
        # This is an elf type we'll need to conver to the correct size
        type = elf_type(type)
        [type, type.size]
      when Array
        if type.size != 2
          raise Error, "array type must be of the form `[type, count]`; got %p" %
            [type]
        end

        type, count = type
        inner, _ = parse_type(type)
        type = CTypes::Helpers
          .array(inner, count).with_endian(inner.default_endian)
        [type, type.size]
      else
        raise Error, "unsupported type: %p" % [type]
      end
    end
  end
end

require_relative "section"
require_relative "segment"
