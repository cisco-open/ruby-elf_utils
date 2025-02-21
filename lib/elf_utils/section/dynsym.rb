require_relative "../symbol"

module ElfUtils
  class Section::Dynsym < Section::Base
    def symbols
      @symbols ||= begin
        dynstr = @file.section(".dynstr")
        @file.elf_type(:Sym).unpack_all(bytes).map do |sym|
          Symbol.new(@file, sym, dynstr)
        end
      end
    end
  end
end
