module ElfUtils
  class Section::DebugAbbrev < Section::Base
    def initialize(*args)
      super
      @abbreviation_tables = {}
    end

    def abbreviation_table(offset)
      @abbreviation_tables[offset] ||= AbbreviationTable.new(bytes[offset..])
    end
  end
end

require_relative "debug_abbrev/abbreviation_table"
require_relative "debug_abbrev/abbreviation"
