require_relative "dwarf"

module ElfUtils
  module Types::Dwarf32
    extend Types::Dwarf
  end
end

require_relative "dwarf32/v2"
require_relative "dwarf32/v3"
require_relative "dwarf32/v4"
require_relative "dwarf32/v5"
