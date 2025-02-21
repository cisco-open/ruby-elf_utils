module ElfUtils
  RSpec.describe Section::DebugInfo::Die do
    extend CTypes::Helpers
    describe "#int_type" do
      {
        {size: 0, signed: false} => string(0),
        {size: 0, signed: true} => string(0),
        {size: 1, signed: true} => int8,
        {size: 1, signed: false} => uint8,
        {size: 2, signed: true} => int16,
        {size: 2, signed: false} => uint16,
        {size: 4, signed: true} => int32,
        {size: 4, signed: false} => uint32,
        {size: 8, signed: true} => int64,
        {size: 8, signed: false} => uint64,
        {size: 16, signed: true} => array(uint64, 2),
        {size: 16, signed: false} => array(uint64, 2),
        {size: 32, signed: true} => array(uint64, 4),
        {size: 32, signed: false} => array(uint64, 4)
      }.each do |args, type|
        it "(size: %d, signed: %p) => %p" %
          [args[:size], args[:signed], type] do
          cu = double
          expect(cu).to receive(:endian).and_return(:big)
          die = described_class.new(
            cu:,
            offset: nil,
            tag: nil,
            children: false,
            abbrev: nil
          )
          expect(die.send(:int_type, **args)).to eq(type.with_endian(:big))
        end
      end
    end

    context_for_each_dwarf_filetype do |path|
      let(:expected_die_ranges) do
        die_range_regexp = %r{
          ^(0x\h+):\s+DW_TAG
          |
          DW_AT_low_pc\s+\((0x\h+)\)
          |
          DW_AT_high_pc\s+\((0x\h+)\)
        }x

        buf = llvm_dwarfdump(path, "debug-info")
        ranges = {}
        die = {}
        buf.scan(die_range_regexp) do |offset, low, high|
          if offset
            offset = offset.to_i(0)
            die = {offset:}
            ranges[offset] = nil
          elsif low
            die[:low] = low.to_i(0)
          elsif high
            ranges[die[:offset]] = [die[:low]..(high.to_i(0) - 1)]
          end
        end
        ranges
      end
      describe "#addr_range" do
        it "will return the address range for DIEs with valid address ranges" do
          skip "no relocation support" unless
              dwarf_file.section(".rela.debug_info").nil?
          die_ranges = dwarf_file.debug_info
            .dies
            .each_with_object({}) do |die, o|
              o[die.offset] = die.addr_ranges
              o
            end
          expect(die_ranges).to eq(expected_die_ranges)
        end
      end
    end
  end
end
