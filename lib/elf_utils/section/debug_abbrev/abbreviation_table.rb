class ElfUtils::Section::DebugAbbrev
  class AbbreviationTable
    def initialize(buf)
      @declarations = {}
      @abbrevs = {}

      # XXX CTypes needs a terminated array where we check the remaining bytes
      # before decoding.
      until buf[0].ord == 0
        decl, buf = ElfUtils::Types::Dwarf::AbbreviationDeclaration.unpack_one(buf)
        @declarations[decl.code] = decl
        @abbrevs[decl.code] = Abbreviation.new(self, decl)
      end
    end
    attr_reader :declarations

    def [](code)
      @abbrevs[code]
    end

    def entries
      @abbrevs.values
    end
  end
end

require_relative "abbreviation"
