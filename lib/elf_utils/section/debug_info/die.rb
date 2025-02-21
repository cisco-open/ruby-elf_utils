require "forwardable"

module ElfUtils
  class Section::DebugInfo::Die
    def initialize(cu:, offset:, tag:, children:, abbrev:, attrs: nil, buf: nil)
      @cu = cu
      @offset = offset
      @tag = tag
      @children = children ? [] : false
      @abbrev = abbrev
      @unpacked_attrs = attrs
      @buf = buf
    end
    attr_reader :tag, :offset, :abbrev, :cu

    def pretty_print(q)
      q.group(4,
        "<%p 0x%08x: DW_TAG_%s (%d children)" %
          [self.class, @offset, @tag, @children ? @children.size : 0],
        ">") do
        q.text("\n" + " " * q.indent)
        q.group_sub do
          attrs = if @attrs
            @attrs.map do |name, value|
              ["DW_AT_%-15s  " % [name], value]
            end
          elsif @unpacked_attrs
            @unpacked_attrs.map do |name, form, value|
              ["DW_AT_%-15s  [DW_FORM_%s] " % [name, form], value]
            end
          end

          if attrs
            q.seplist(attrs) do |label, value|
              q.group(4, label) do
                case value
                when self.class
                  q.text("<%p 0x%08x: DW_TAG_%s ...>" %
                         [self.class, value.offset, value.tag])
                else
                  q.pp(value)
                end
              end
            end
          else
            q.group(1, "abbrev=") { q.pp(@abbrev) }
          end
        end
      end
    end
    alias_method :inspect, :pretty_inspect

    def children?
      @children != false
    end

    def children
      @children || []
    end

    def has_attr?(attr)
      @attrs ? @attrs.has_key?(attr) : @abbrev.attrs.has_key?(attr)
    end

    def add_child(child)
      raise Error, "This DIE cannot have children" unless @children
      @children << child
      self
    end

    def type?
      @is_a_type ||= case @tag
      when :base_type,
            :typedef,
            :volatile_type,
            :const_type,
            :pointer_type,
            :array_type,
            :union_type,
            :enumeration_type,
            :structure_type,
            :subroutine_type
        true
      else
        false
      end
    end

    def [](name)
      @attrs ||= parse_attrs
      @attrs[name]
    end

    def []=(name, value)
      @attrs ||= parse_attrs
      @attrs[name] = value
    end

    def attrs
      @attrs ||= parse_attrs
      @attrs.keys
    end

    # get the unprocessed value for an attribute
    def raw_attr(key)
      unpacked_attrs.each do |name, _, value|
        return value if name == key
      end
      raise Error, "no attribute %p found in DIE: %p" % [key, self]
    end

    def addr_ranges
      @attrs ||= parse_attrs
      @addr_ranges ||=
        if (low = @attrs[:low_pc]) && (high = @attrs[:high_pc])
          [low..(high - 1)]
        elsif @attrs[:ranges]
          @cu.file.section(".debug_ranges")
            .get(offset: @attrs[:ranges], base: @attrs[:low] || 0)
        end
    end

    def has_addr?(addr)
      case tag
      when :subprogram
        addr_ranges&.any? { |r| r.include?(addr) }
      when :variable
        type = self[:type].ctype
        [location...location + type.size]
      else
        false
      end
    end

    # return the number of elements in the subrange
    def subrange_len
      @attrs ||= parse_attrs

      raise "not a subrange DIE: %p" % [self] unless @tag == :subrange_type
      return @attrs[:count] if @attrs.has_key?(:count)

      # upper bound may be DW_TAG_variable, so special handling
      if (upper_bound = @attrs[:upper_bound])
        return @attrs[:upper_bound] + 1 if upper_bound.is_a?(Integer)
      end

      # XXX we'll need to do some work to support flexible array members, or
      # arrays with an upper bound defined by DW_TAG_variable
      0
    end

    # return the value of DW_AT_location
    def location
      value = self[:location]

      if value.is_a?(Types::Dwarf::Expression)
        value = value.evaluate(addr_type: cu.addr_type, stack: [])[-1]
      end
      value
    end

    def type_name
      return nil unless type?

      @type_name ||= begin
        @attrs ||= parse_attrs

        case @tag
        when :base_type, :typedef
          @attrs[:name]
        when :volatile_type
          "volatile #{@attrs[:type]&.type_name || "void"}"
        when :const_type
          "const #{@attrs[:type]&.type_name || "void"}"
        when :array_type
          sizes = children
            .inject("") do |buf, child|
              buf << "[%d]" % child.subrange_len if child.tag == :subrange_type
              buf
            end
          "#{@attrs[:type].type_name}#{sizes}"
        when :pointer_type
          inner = @attrs[:type]&.type_name || "void"
          if inner.end_with?("*")
            "#{inner}*"
          else
            "#{inner} *"
          end
        when :structure_type
          name = @attrs[:name] || ("anon_%x" % @offset)
          "struct #{name}"
        when :union_type
          name = @attrs[:name] || ("anon_%x" % @offset)
          "union #{name}"
        when :enumeration_type
          name = @attrs[:name] || ("anon_%x" % @offset)
          "enum #{name}"
        when :subrange_type, :subroutine_type
          return
        else
          raise Error, "unsupported DIE: %p" % [self]
        end
      end
    end

    def ctype
      return unless type?
      return @ctype if @ctype

      @attrs ||= parse_attrs

      @ctype = case tag
      when :base_type
        signed = !@attrs[:encoding].to_s.include?("unsigned")
        int_type(size: @attrs[:byte_size], signed:)
      when :typedef
        @attrs[:type].ctype
      when :const_type, :volatile_type
        # const void has no equivalent ctype... maybe empty struct?
        @attrs[:type]&.ctype
      when :pointer_type, :subroutine_type
        @cu.addr_type
      when :array_type
        sizes = children
          .filter_map { |c| c.subrange_len if c.tag == :subrange_type }

        # if we have a signed char array, we'll use a string to hold it
        inner_type = @attrs[:type].ctype
        if inner_type.is_a?(CTypes::Int) &&
            inner_type.size == 1 &&
            inner_type.signed?
          inner_type = CTypes::String.new(size: sizes.pop)
        end

        while (size = sizes.pop)
          inner_type = CTypes::Array.new(type: inner_type, size:)
        end

        inner_type
      when :structure_type
        offset = 0
        struct = CTypes::Struct.builder
          .name(self[:name])
          .endian(@endian ||= @cu.file.endian)
        bitfield = nil

        (@children || []).each do |child|
          next unless child.tag == :member

          name = child[:name]&.to_sym
          type = child[:type].ctype
          loc = child[:data_member_location] || 0
          if loc.is_a?(Types::Dwarf::Expression)
            child[:data_member_location] = loc =
              loc.evaluate(addr_type: @cu.addr_type)[0]
          end
          delta = loc - offset

          # add any bitfield if we're moving past it
          if bitfield && delta >= 0
            struct.attribute bitfield.build
            bitfield = nil
          end

          # handle any padding we need to do
          struct.pad delta if delta > 0

          # check for v2, v3 bitfield
          if (bits = child[:bit_size]) && (bit_offset = child[:bit_offset])
            bitfield ||= CTypes::Bitfield.builder.endian(@endian)

            # convert the left-hand offset to a right-hand offset when we're
            # on a little-endian system
            if CTypes.host_endian == :little
              bit_offset = child[:byte_size] * 8 - bit_offset - bits
            end

            bitfield.field(name,
              offset: bit_offset,
              bits: bits,
              signed: type.signed?)

          # v4, v5 bitfield
          elsif (bits = child[:bit_size]) &&
              (bit_offset = child[:data_bit_offset])

            bitfield ||= CTypes::Bitfield.builder.endian(@endian)

            # If the endian of the type doesn't match the host-endian, we
            # need to flip the offset
            if @endian != CTypes.host_endian
              bit_offset = self[:byte_size] * 8 - bit_offset - bits
            end

            bitfield.field(name,
              offset: bit_offset,
              bits: bits,
              signed: type.signed?)

          # not a bitfield
          elsif name.nil?
            # handle unnamed field
            struct.attribute type

            # must be a named field
          else
            struct.attribute name, type
          end
          offset = loc + type.size
        end

        # ensure we include the bitfield if it was the last element
        struct.attribute(bitfield.build) if bitfield

        struct.build
      when :union_type
        union = CTypes::Union.builder
          .name(self[:name])
          .endian(@endian ||= @cu.file.endian)
        (@children || []).each do |child|
          next unless child.tag == :member

          name = child[:name]
          type = child[:type].ctype
          if name
            union.member name.to_sym, type
          else
            union.member type
          end
        end

        union.build
      when :enumeration_type
        type = int_type(size: @attrs[:byte_size], signed: false)

        values = {}
        @children.each do |child|
          values[child[:name].downcase.to_sym] = child[:const_value]
        end

        CTypes::Enum.new(type.with_endian(@cu.file.endian), values)
      when :subrange_type
        return
      else
        raise Error, "unsupported DIE: %p" % [self]
      end
    end

    private

    def unpacked_attrs
      @unpacked_attrs ||= begin
        o, _ = @abbrev.unpack_die(buf: @buf,
          endian: @cu.file.endian,
          offset_type: @cu.offset_type,
          addr_type: @cu.addr_type)
        o
      end
    end

    def parse_attrs
      attrs = {}
      unpacked_attrs.each do |name, form, value|
        case name
        when :encoding
          value = Types::Dwarf::Encoding[value]
        when :data_member_location
          value = Types::Dwarf::Expression.new(@cu, value) if
            value.is_a?(String)
        when :location
          value = Types::Dwarf::Expression.new(@cu, value) if
            value.is_a?(String)
        when :high_pc
          value += attrs[:low_pc] if form == :data4
        end

        case form
        when :ref1, :ref2, :ref4, :ref8
          value = @cu.die(value + @cu.offset)
        when :strp
          value = @cu.file.section(".debug_str")[value]
        when :addrx
          value = @cu.file.section(".debug_addr")
            .get(base: @cu.addr_base, index: value)
        when :strx1
          base = @cu.str_offsets_base
          offset = @cu.file.section(".debug_str_offsets")
            .get(base:, offset: value, format: @cu.format)
          value = @cu.file.section(".debug_str")[offset]
        end

        attrs[name] = value
      end
      attrs
    end

    def attr_value(name, form, value)
      case name
      when :encoding
        return Types::Dwarf::Encoding[value]
      when :data_member_location
        if value.is_a?(String)
          return Types::Dwarf::Expression.new(@cu, value)
        else
          return value
        end
      when :location
        if value.is_a?(String)
          return Types::Dwarf::Expression.new(@cu, value)
        else
          return value
        end
      end

      case form
      when :addrx
        return @cu.file.section(".debug_addr")[@cu.addr_base + value]
      when :ref1, :ref2, :ref4, :ref8
        return @cu.die(value + @cu.offset)
      when :strp
        return @cu.file.section(".debug_str")[value]
      when :strx1
        # if we're working on the compile unit, we need the unparsed
        # :str_offsets_base in this DIE to resolve str offset values.  For any
        # other DIE, we can use the parsed compile unit to get the offset.
        str_offsets, base = if @tag == :compile_unit
          @str_offsets_base = @unpacked_attrs.find do |name, form, value|
            next unless name == :str_offsets_base
            break value
          end or raise Error, ":str_offsets_base not found in %p" % [self]
          [@cu.file.section(".debug_str_offsets"), @str_offsets_base]
        else
          @cu.debug_str_offsets
        end
        offset = str_offsets.get(base:, offset: value, format: @cu.format)
        return @cu.file.section(".debug_str")[offset]
      end

      value
    end

    def int_type(size:, signed:)
      @endian ||= @cu.endian

      case size
      when 0
        CTypes::String.new(size: 0)
      when 1
        signed ? CTypes::Int8 : CTypes::UInt8
      when 2
        signed ? CTypes::Int16 : CTypes::UInt16
      when 4
        signed ? CTypes::Int32 : CTypes::UInt32
      when 8
        signed ? CTypes::Int64 : CTypes::UInt64
      when 16
        CTypes::Array.new(type: CTypes::UInt64, size: 2)
      when 32
        CTypes::Array.new(type: CTypes::UInt64, size: 4)
      else
        raise "unsupported base_type size %d in: %p" % [size, self]
      end.with_endian(@endian)
    end
  end
end

require_relative "die/base"
require_relative "die_ref"
require_relative "debug_str_ref"
require_relative "debug_str_offsets_ref"
