module ElfUtils
  class Section::DebugRanges < Section::Base
    include CTypes::Helpers

    # get the range list at a given offset
    def get(offset:, base:)
      array(array(@file.addr_type, 2), terminator: [0, 0])
        .unpack(bytes[offset..])
        .map do |first, last|
          if first == @file.addr_type.max
            # TODO figure out how to generate a test file that makes use of
            # DW_AT_ranges & has a base address range so we can add tests for
            # this.
            base = last
            nil
          else
            (first + base)..(last + base - 1)
          end
        end.compact
    end
  end
end
