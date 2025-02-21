require_relative "../symbol"

module ElfUtils
  class Section::Symtab < Section::Base
    def symbols
      @symbols ||= @file.elf_type(:Sym).unpack_all(bytes).map do |sym|
        Symbol.new(@file, sym)
      end
    end
  end
end
