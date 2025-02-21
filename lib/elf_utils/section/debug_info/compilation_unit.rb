require "forwardable"

module ElfUtils
  class Section::DebugInfo::CompilationUnit
    extend Forwardable
    include CTypes::Helpers

    ULEB128 = Types::ULEB128

    def initialize(file, offset, header)
      @file = file
      @offset = offset
      @header = header
      @debug_str = @file.section(".debug_str")

      @endian = @file.endian
      @addr_size = header.addr_size
      @addr_type = case header.addr_size
      when 4
        uint32.with_endian(@endian)
      when 8
        uint64.with_endian(@endian)
      else
        raise Error,
          "unsupported address size in DWARF header: %p" % [@header]
      end
      @offset_type = (header.format == :dwarf32) ?
        uint32.with_endian(@endian) :
        uint64.with_endian(@endian)

      @types = {}
    end
    attr_reader :offset, :addr_type, :offset_type, :file

    def_delegators :@file, :endian
    def_delegators :@header, :format, :version, :addr_size
    def_delegator :@header, :unit_length, :size
    def_delegator :@header, :debug_abbrev_offset, :abbr_offset

    def inspect
      fmt = <<~FMT.chomp
        <%s offset=0x%x, size=%d, format=%p, version=%d, abbr_offset=0x%x, \
        addr_size=%d>
      FMT
      fmt %
        [self.class, offset, size, format, version, abbr_offset, addr_size]
    end

    def abbrev_table
      @abbrev_table ||= file.section(".debug_abbrev")
        .abbreviation_table(@header.debug_abbrev_offset)
    end

    def die_range
      @range ||= begin
        start = @offset + @header.class.size
        start...start + @header.data.size
      end
    end

    def root_die
      dies.first
    end

    def die(offset)
      @dies ||= split_dies
      @dies[offset] or raise Error, "invalid DIE offset: 0x%x" % offset
    end

    def dies
      @dies ||= split_dies
      @dies.values
    end

    def types
      unless @cached_all_types
        dies.each do |die|
          name = die.type_name or next
          @types[name] ||= die.ctype
        end
        @cached_all_types = true
      end
      @types
    end

    def type(arg)
      case arg
      when Integer
        _, t = die(arg).ctype
        t
      when String
        # check the cache first
        if (type = @types[arg])
          return type
        end

        # then try finding the die with the type
        dies.each do |die|
          next unless die.type_name == arg
          @types[arg] = die.ctype
        end
        @types[arg]
      else
        raise Error, "unsupported type lookup key: %p" % [arg]
      end
    end

    # helper for {Types::Dwarf::Expression} to get values from the .debug_addr
    # section.
    # @param index [Integer] index into the .debug_addr section to be adjusted
    #   by the base for this CompilationUnit
    def debug_addr_get!(index)
      debug_addr = @file.section(".debug_addr") or
        raise Error, "`.debug_addr` section not present in #{@file}"
      debug_addr.get(base: root_die[:addr_base], index:)
    end

    # helper for DIEs to get easy access to .debug_str_offsets & base
    def debug_str_offsets
      @debug_str_offsets ||=
        [@file.section(".debug_str_offsets"), root_die[:str_offsets_base]]
    end

    # helper for accessing DW_TAG_str_offsets_base in the CU DIE
    def str_offsets_base
      @str_offsets_base ||= root_die.raw_attr(:str_offsets_base)
    end

    # helper for accessing DW_TAG_addr_base in the CU DIE
    def addr_base
      @addr_base ||= root_die.raw_attr(:addr_base)
    end

    def include_addr?(addr)
      root_die.addr_ranges&.any? { |r| r.include?(addr) }
    end

    private

    def split_dies
      endian = file.endian
      addr_size = @addr_type.size
      offset_size = @offset_type.size
      abbrevs = {}

      dies = {}
      parents = []

      buf = @header.data
      offset = @offset + @header.class.size
      last_size = buf.size

      until buf.empty?
        offset += last_size - buf.size
        last_size = buf.size

        code, buf = ElfUtils::Types::ULEB128.unpack_one(buf)
        if code == 0
          parents.pop
          next
        end

        ab, tag, size, children = abbrevs[code] ||= begin
          ab = abbrev_table[code]
          [ab, ab.tag, ab.die_size(addr_size:, offset_size:), ab.children?]
        end

        die = if size
          d = dies[offset] = Section::DebugInfo::Die
            .new(cu: self, offset:, tag:, children:, abbrev: ab, buf:)
          buf = buf.byteslice(size..)
          d
        else
          attrs, buf = ab.unpack_die(buf:, endian:, offset_type:, addr_type:)
          dies[offset] = Section::DebugInfo::Die
            .new(cu: self, offset:, tag:, children:, abbrev: ab, attrs:)
        end

        dies[offset] = die

        parents[-1].add_child(die) unless parents.empty?
        parents.push(die) if children
      end
      dies
    end
  end
end

require_relative "die"
