module ElfUtils
  class Section::DebugInfo::Die::Base
    include CTypes::Helpers

    def initialize(cu:, offset:, attrs:, has_children:)
      @cu = cu
      @offset = offset
      @attrs = attrs
      @children = [] if has_children
    end
    attr_reader :cu, :offset, :tag

    def <<(child)
      raise Error, "This DIE cannot have children" unless @children
      @children << child
    end

    def children?
      !!@children
    end

    def children
      # to make it easier to walk a tree of DIEs, we're going to return an
      # empty array for DIEs that don't have children
      @children || []
    end

    def inspect
      buf = "<%p\n    0x%08x: DW_TAG_%s (children=%p)\n" %
        [self.class, @offset, tag, @children ? @children.size : false]
      @attrs.each do |name, value|
        buf << "            DW_AT_%-15s %p\n" % [name, value]
      end
      buf.chomp! << ">"
    end

    def has_attr?(key)
      @attrs.has_key?(key)
    end

    def type?
      tag == :typedef || tag.to_s.end_with?("_type")
    end

    def ctype
      return unless type?
      return @ctype if @ctype

      name, type = case tag
      when :base_type
        unsigned = @attrs[:encoding].to_s.include?("unsigned")
        type = case @attrs[:byte_size]
        when 1
          unsigned ? uint8 : int8
        when 2
          unsigned ? uint16 : int16
        when 4
          unsigned ? uint32 : int32
        when 8
          unsigned ? uint64 : int64
        else
          raise "unsupported base_type size: %p" % die
        end
        [@attrs[:name].deref, type.with_endian(@cu.file.endian)]
      when :volatile_type
        name, type = @attrs[:type].deref.ctype
        ["volatile #{name}", type]
      when :typedef
        _, type = @attrs[:type].deref.ctype
        [@attrs[:name].deref, type]
      when :array_type
        name, inner_type = @attrs[:type].deref.ctype

        subrange = children.find { |c| c.tag == :subrange_type }
        size = if subrange.has_attr?(:count)
          subrange.count
        elsif subrange.has_attr?(:upper_bound)
          subrange.upper_bound
        end

        # XXX need flexible array member test

        # if we have a signed char array, we'll use that
        if inner_type.is_a?(CTypes::Int) &&
            inner_type.size == 1 &&
            inner_type.signed?
          ["#{name}[#{size}]", string(size)]
        else
          ["#{name}[#{size}]", array(inner_type, size)]
        end
      when :pointer_type
        type = @attrs[:type].deref
        name, = type.ctype
        [(type.tag == :pointer_type) ? "#{name}*" : "#{name} *", @cu.addr_type]
      when :structure_type
        fields, = @children.inject([{}, 0]) do |(o, offset), child|
          next [o, offset] unless child.tag == :member

          pad = child.data_member_location - offset
          o[:"__pad_#{offset}"] = string(pad, trim: false) if pad != 0

          _, type = child.type.deref.ctype
          o[child.name.deref.to_sym] = type
          [o, child.data_member_location + type.size]
        end

        name = @attrs[:name]&.deref || ("anon_%x" % offset)

        ["struct #{name}", struct(**fields)]
      when :union_type
        layout = @children.each_with_object({}) do |child, o|
          next o unless child.tag == :member

          _, type = child.type.deref.ctype
          o[child.name.deref.to_sym] = type
        end

        name = @attrs[:name]&.deref || ("anon_%x" % offset)

        ["union #{name}", union(**layout)]
      when :subrange_type, :subroutine_type
        return
      else
        raise Error, "unsupported DIE: %p" % [die]
      end

      @ctype = [name, type]
    end
  end
end
