module ElfUtils
  RSpec.describe Section::DebugInfo do
    describe "#compilation_units" do
      context_for_each_dwarf_filetype do |path|
        let(:debug_info) { dwarf_file.section(".debug_info") }

        let(:known_cus) do
          regex = %r{
          ^(?:
            (?<cu_offset>0x\h+):\s
            Compile\ Unit:\ length\ =\ (?<len>0x\h+),\s
            format\ =\ DWARF(?<format>32|64),\s
            version\ =\ (?<version>0x\h+),\s
            (?:unit_type\ =\ DW_UT_compile,\s)?
            abbr_offset\ =\ (?<abbr_offset>0x\h+),\s
            addr_size\ =\ (?<addr_size>0x\h+)\s
            \(next\ unit\ at\ (?<next_offset>0x\h+)\)
          |
            (?<tag_offset>0x\h+):\s+DW_TAG_(?<tag>\w+)
          |
            \s+DW_AT_(?<attr_name>\w+)\s+\((?<attr_value>.*?)(:?\)|:)
          )
          }x

          # dump the debug-info section
          buf = llvm_dwarfdump(path, "debug-info")

          # we'll construct an array of CU matchers
          cus = {}
          cu = nil
          tag = nil
          buf.scan(regex) do
            captures = Regexp.last_match.named_captures
              .delete_if { |k, v| v.nil? }

            if captures["attr_name"]
              tag[:attrs] << captures["attr_name"].to_sym
            elsif captures["tag_offset"]
              cu[:dies] << tag = {
                offset: captures["tag_offset"].to_i(16),
                tag: captures["tag"].to_sym,
                attrs: []
              }
            elsif captures["cu_offset"]
              cu = {
                offset: captures["cu_offset"].to_i(16),
                format: (captures["format"] == "32") ? :dwarf32 : :dwarf64,
                abbr_offset: captures["abbr_offset"].to_i(16),
                addr_size: captures["addr_size"].to_i(16),
                size: captures["len"].to_i(16),
                dies: []
              }
              cus[cu[:offset]] = cu
            end
          end

          cus
        end

        it "will find the expected compilation units" do
          cus = debug_info.compilation_units

          # ensure we have exactly the CUs we'd expect
          matcher = known_cus
            .map { |offset,| have_attributes(offset: offset) }
          expect(cus).to contain_exactly(*matcher)

          # go through each CU
          known_cus.each do |offset, known_cu|
            # ensure the CU has all of the expected fields
            cu = cus.find { |cu| cu.offset == offset }
            known_dies = known_cu.delete(:dies)
            expect(cu).to have_attributes(known_cu)

            # ensure the CU has all of the expected DIEs
            known_attrs = []
            die_matchers = known_dies.map do |die|
              known_attrs << [die[:offset], die.delete(:attrs)]
              have_attributes(die)
            end
            expect(cu.dies).to contain_exactly(*die_matchers)
          end
        end

        it "will contain the expected DIEs within the compilation units" do
          skip "no relocation support" unless
              dwarf_file.section(".rela.debug_info").nil?

          cus = debug_info.compilation_units

          # go through each CU
          known_cus.each do |offset, known_cu|
            cu = cus.find { |cu| cu.offset == offset }

            # ensure each DIE has the expected attributes
            known_cu[:dies].each do |known|
              expect(cu.die(known[:offset]).attrs)
                .to contain_exactly(*known[:attrs])
            end
          end
        end
      end
    end
  end
end
