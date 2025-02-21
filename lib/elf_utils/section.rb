module ElfUtils
  module Section
    def self.from_header(elf_file, header)
      case header.sh_type
      when :strtab
        return Section::Strtab.new(elf_file, header)
      when :symtab
        return Section::Symtab.new(elf_file, header)
      when :dynsym
        return Section::Dynsym.new(elf_file, header)
      end

      name = elf_file.shstrtab[header.sh_name]
      case name
      when ".debug_info"
        Section::DebugInfo.new(elf_file, header)
      when ".debug_abbrev"
        Section::DebugAbbrev.new(elf_file, header)
      when ".debug_str"
        Section::Strtab.new(elf_file, header)
      when ".debug_str_offsets"
        Section::DebugStrOffsets.new(elf_file, header)
      when ".debug_aranges"
        Section::DebugArange.new(elf_file, header)
      when ".debug_line"
        Section::DebugLine.new(elf_file, header)
      when ".debug_line_str"
        Section::Strtab.new(elf_file, header)
      when ".debug_addr"
        Section::DebugAddr.new(elf_file, header)
      when ".debug_ranges"
        Section::DebugRanges.new(elf_file, header)
      else
        Section::Base.new(elf_file, header)
      end
    end
  end
end

require_relative "section/base"
require_relative "section/strtab"
require_relative "section/symtab"
require_relative "section/dynsym"
require_relative "section/debug_info"
require_relative "section/debug_abbrev"
require_relative "section/debug_str_offsets"
require_relative "section/debug_arange"
require_relative "section/debug_line"
require_relative "section/debug_addr"
require_relative "section/debug_ranges"
