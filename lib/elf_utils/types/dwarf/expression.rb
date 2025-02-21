module ElfUtils
  class Types::Dwarf::Expression
    def initialize(cu, bytes)
      @cu = cu
      @bytes = bytes
    end

    def evaluate(addr_type:, stack: [0])
      return @result if @result

      buf = @bytes
      until buf.empty?
        op, buf = Types::Dwarf::Operation.unpack_one(buf)
        case op
        when :plus_uconst
          a = stack.pop
          b, buf = Types::ULEB128.unpack_one(buf)
          stack.push(a + b)
        when :addr
          v, buf = addr_type.unpack_one(buf)
          stack.push(v)
        when :addrx
          index, buf = Types::ULEB128.unpack_one(buf)
          stack.push(@cu.debug_addr_get!(index))
        when nil
          # noop
        else
          raise Error, "unsupported DWARF operation: %p" % [op]
        end
      end
      @result = stack.freeze
    end
  end
end
