require "forwardable"

module ElfUtils
  class Section::DebugAbbrev::Abbreviation
    extend Forwardable

    class UnsupportedDwarfAttributeFormError < ElfUtils::Error; end

    def initialize(table, decl)
      @table = table
      @decl = decl
    end
    attr_reader :decl
    def_delegators :@decl, :code, :tag

    def pretty_print(q)
      q.group(4,
        "<%p [%d] DW_TAG_%s DW_CHILDREN_%s" %
          [self.class, code, tag, children? ? "yes" : "no"],
        ">") do
        q.text("\n" + " " * q.indent)
        q.seplist(@decl.attribute_specifications) do |attr|
          q.text("DW_AT_%-15s  DW_FORM_%s" % [attr.name, attr.form])
        end
      end
    end
    alias_method :inspect, :pretty_inspect

    def children?
      @decl.children == 1
    end

    def attrs
      @attrs ||= begin
        attrs = {}
        @decl.attribute_specifications.each do |attr|
          attrs[attr.name] = attr.form
        end
        attrs.freeze
      end
    end

    def die_size(addr_size:, offset_size:)
      return nil if @variable_size

      size = 0
      @decl.attribute_specifications.each do |attr|
        if (s = form_size(form: attr.form, addr_size:, offset_size:))
          size += s
        else
          @variable_size = true
          return nil
        end
      end
      size
    end

    def variable_sized_attrs(addr_size:, offset_size:)
      out = []
      @decl.attribute_specifications.each do |attr|
        next if form_size(form: attr.form, addr_size:, offset_size:)
        out << attr
      end
      out
    end

    def unpack_die(buf:, endian:, offset_type:, addr_type:)
      out = []
      @decl.attribute_specifications.each do |attr|
        value, buf = case attr.form
        when :addr
          addr_type.unpack_one(buf, endian: endian)
        when :strp, :sec_offset
          offset_type.unpack_one(buf, endian: endian)
        when :data1, :flag, :ref1, :strx1
          CTypes::UInt8.unpack_one(buf, endian: endian)
        when :data2, :ref2
          CTypes::UInt16.unpack_one(buf, endian: endian)
        when :data4, :ref4
          CTypes::UInt32.unpack_one(buf, endian: endian)
        when :data8, :ref8
          CTypes::UInt64.unpack_one(buf, endian: endian)
        when :udata, :addrx
          Types::ULEB128.unpack_one(buf)
        when :sdata
          Types::SLEB128.unpack_one(buf)
        when :string
          CTypes::String.terminated.unpack_one(buf, endian: endian)
        when :block1
          len, buf = CTypes::UInt8.unpack_one(buf, endian: endian)
          [buf.byteslice(0, len), buf.byteslice(len..)]
        when :block2
          len, buf = CTypes::UInt16.unpack_one(buf, endian: endian)
          [buf.byteslice(0, len), buf.byteslice(len..)]
        when :exprloc
          len, buf = Types::ULEB128.unpack_one(buf)
          [buf.byteslice(0, len), buf.byteslice(len..)]
        when :loclistx
          Types::ULEB128.unpack_one(buf)
        when :flag_present
          [1, buf]
        else
          raise UnsupportedDwarfAttributeFormError,
            "unsupported DWARF form: %p" % [attr.form]
        end

        out << [attr.name, attr.form, value]
      end
      [out, buf]
    end

    private

    # return the size of a given dwarf attribute form
    def form_size(form:, addr_size:, offset_size:)
      case form
      when :addr
        addr_size
      when :data1, :ref1
        1
      when :data2, :ref2
        2
      when :data4, :ref4
        4
      when :data8, :ref8
        8
      when :flag
        1
      when :strp
        offset_size
      when :ref_addr
        addr_size
      when :sec_offset
        offset_size
      when :flag_present
        0
      when :ref_sup4
        4
      when :strp_sup
        offset_size
      when :data16
        16
      when :line_strp
        offset_size
      when :ref_sig8
        8
      when :ref_sup8
        8
      when :strx1
        1
      when :strx2
        2
      when :strx3
        3
      when :strx4
        4
      when :addrx1
        1
      when :addrx2
        2
      when :addrx3
        3
      when :addrx4
        4
      else
        # variable sized
        nil
      end
    end
  end
end
