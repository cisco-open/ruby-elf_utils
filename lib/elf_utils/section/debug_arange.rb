module ElfUtils
  class Section::DebugArange < Section::Base
    extend CTypes::Helpers

    Tuple32 = struct(addr: uint32, size: uint32)
    Tuple64 = struct(addr: uint64, size: uint64)

    class Entry < CTypes::Struct
      layout do
        attribute :length, uint32
        attribute :version, uint16
        attribute :debug_info_offset, uint32
        attribute :addr_size, uint8
        attribute :seg_desc_size, uint8
        pad 4 # XXX not needed for dwarf64
        attribute :tuple_bytes, string(trim: false)
        size { |hdr| offsetof(:version) + hdr[:length] }
      end

      def tuples
        @tuples ||= begin
          type = (addr_size == 4) ? Tuple32 : Tuple64
          type.unpack_all(self[:tuple_data], endian: @file.endian)
        end
      end
    end

    def entries
      @entries ||= Entry.unpack_all(bytes, endian: @file.endian)
    end

    def ranges
      @ranges ||= begin
        ranges = []
        entries.each do |entry|
          tuple_type = (entry.addr_size == 4) ? Tuple32 : Tuple64
          tuple_type
            .unpack_all(entry.tuple_bytes, endian: @file.endian)
            .each do |tuple|
              next if tuple.addr == 0 && tuple.size == 0
              range = tuple.addr...(tuple.addr + tuple.size)
              ranges << [range, entry.debug_info_offset]
            end
        end
        ranges
      end
    end

    def cu_offset(addr)
      ranges.each { |range, offset| return offset if range.include?(addr) }
      nil
    end
  end
end
