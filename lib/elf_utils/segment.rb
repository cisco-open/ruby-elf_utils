module ElfUtils
  module Segment
    def self.from_header(elf_file, header)
      Segment::Base.new(elf_file, header)
    end
  end
end

require_relative "segment/base"
