# frozen_string_literal: true

require_relative "elf_utils/version"

# ElfUtils for working with ELF & DWARF files
#
# ElfUtils provides a user-friendly wrapper around core ELF & DWARF types to
# make it easier to extract common information from ELF files.  The {ElfFile}
# and {Symbol} classes are the primary interface into ELF file contents.  For
# complex tasks not currently provided there, you can directly access the
# ELF and DWARF structures from {ElfFile#sections}, {ElfFile#segments}, and
# {ElfFile#debug_info}.
#
# ElfUtils supports 32-bit & 64-bit ELF formats, both little and big endian.
# ElfUtils supports DWARF v2, v3, v4, and v5, but not exhaustively.
#
# Here are some quick examples of ElfUtils functionality.
#
# @example Get the source of a function from a binary with DWARF debug info
#   ElfUtils.open("spec/data/complex_64be-dwarf64-v5") do |elf_file|
#     elf_file.symbol("main").source_location
#   end  # => {:file=>"spec/data/test.c", :line=>25 (0x19), :column=>0}
#
# @example Get the address of a variable in memory
#   ElfUtils.open("spec/data/complex_64be-dwarf64-v5") do |elf_file|
#     symbol = elf_file.symbol("global_buf")  # => #<ElfUtils::Symbol ... >
#     symbol.addr                             # => 0x000206d0
#
#     # adjust the load segment location for ASLR
#     symbol.section.load_segment.relocate(0x10000000)
#     symbol.addr                             # => 0x10000090
#   end
#
# @example Extract the initial value for a variable from an elf file
#   # open the elf file
#   elf_file = ElfUtils.open("spec/data/complex_64be-dwarf64-v5")
#
#   # lookup the symbol for a global variable, and get its type
#   symbol = elf_file.symbol("struct_with_bitfield")  # => #<ElfUtils::Symbol>
#   ctype = symbol.ctype                              # => #<CTypes::Type ...>
#
#   # read the bytes for the symbol from the elf file
#   buf = symbol.section.bytes[symbol.section_offset, symbol.size]
#                                                     # => "\xE0\x80\x00\x00"
#
#   # unpack the bytes into a human-readable structure
#   value = ctype.unpack(buf)                         # => { a: 1, b: -1, c: 1}
#
# @see ElfFile
# @see Symbol
module ElfUtils
  class Error < StandardError; end

  class InvalidFormat < Error; end

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
  # @example Open an ELF file and print all symbols
  #   elf_file = ElfUtils.open("spec/data/complex_64be-dwarf64-v5")
  #   pp(elf_file.symbols)
  #   elf_file.close
  #
  # @example print all symbols using a block invocation
  #   ElfUtils.open("spec/data/complex_64be-dwarf64-v5") do |elf_file|
  #     pp(elf_file.symbols)
  #   end
  #
  def self.open(path, &block)
    ElfFile.open(path, &block)
  end
end

require_relative "elf_utils/types"
require_relative "elf_utils/elf_file"
require_relative "elf_utils/elf_utils"
