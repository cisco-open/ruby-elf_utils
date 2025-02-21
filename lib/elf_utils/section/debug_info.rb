module ElfUtils
  class Section::DebugInfo < Section::Base
    def compilation_units
      @cus ||= begin
        offset = 0
        Header.with_endian(@file.endian).unpack_all(bytes).map do |header|
          # PERF: we freeze the header to prevent CTypes::Union from
          # re-encoding the header when accessing the inner value.  This is
          # the common performance work-around for union change tracking.
          #
          # The proper fix is probably to break up the convenience Header union
          # and just parse the unit header directly, then parse the proper
          # header version.
          header.freeze
          cu = CompilationUnit.new(@file, offset, header.inner)
          offset += (cu.format == :dwarf32) ? 4 : 12
          offset += cu.size
          cu
        end
      end
    end
    alias_method :cus, :compilation_units

    # get a compilation unit
    def compilation_unit(arg)
      # XXX do this in a way where we don't need to load all the CUs
      case arg
      when String
        cus.find { |cu| cu.root_die[:name] == arg }
      when Integer
        cus.find { |cu| cu.offset == arg }
      end
    end
    alias_method :cu, :compilation_unit

    # return the CompilationUnit that contains the provided offset
    def compilation_unit_for_offset(offset)
      cus.find { |cu| cu.die_range.include?(offset) }
    end
    alias_method :cu_for_offset, :compilation_unit_for_offset

    # get a enumerator to iterate through the {Die}s present in all
    # {CompilationUnit}s
    #
    # By default, the Enumerator returned by this method will yield every
    # {Die} in every {CompilationUnit} in the order they were declared in.  If
    # `top` is set to true, the Enumerator will instead only yield those {Die}s
    # that are children of the root {Die} in each {CompilationUnit}.
    #
    # @param top [Boolean] set to true to only return the children of the root
    #   die
    # @param root [Boolean] set to true to yield the root DIE of each
    #   CompilationUnit prior to its children
    def dies(top: false, root: false)
      Enumerator.new do |yielder|
        cus.each do |cu|
          if top
            yielder << cu.root_die if root
            cu.root_die.children.each { |die| yielder << die }
          else
            cu.dies.each { |die| yielder << die }
          end
        end
      end
    end

    def die(offset)
      cu = compilation_unit_for_offset(offset) or
        raise Error, "No CU found containing offset %x" % offset
      cu.die(offset)
    end

    def type(name)
      compilation_units.each do |cu|
        type = cu.type(name)
        return type if type
      end
      nil
    end

    def type_die(name)
      compilation_units.each do |cu|
        cu.dies.each do |die|
          return die if die.type_name == name
        end
      end
      nil
    end
  end
end

require_relative "debug_info/header"
require_relative "debug_info/compilation_unit"
