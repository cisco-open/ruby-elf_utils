module ElfUtils
  RSpec.describe Section do
    describe "#relocate" do
      context_for_each_elf_filetype do
        let(:load_segment) do
          elf_file.load_segments.first
        end

        it "will update `Segment#addr`" do
          # test doesn't apply if there are no load segments
          next if load_segment.nil?
          load_segment.relocate(0x40000000)
          expect(load_segment.addr).to eq(0x40000000)
        end

        it "will update `Section#addr` for sections in segment" do
          next if load_segment.nil?
          section_matchers = load_segment.sections.map do |section|
            have_attributes(
              name: section.name,
              addr: 0x40000000 + (section.addr - load_segment.addr)
            )
          end
          load_segment.relocate(0x40000000)
          expect(load_segment.sections).to contain_exactly(*section_matchers)
        end
      end
    end

    describe "#sections" do
      context_for_each_elf_filetype do |path|
        it "will return the sections in the segment" do
          buf = `llvm-readelf --section-mapping #{path}`
          matchers = buf.scan(/^\s+(\d+)(.*)/).map do |idx, names|
            sections = names.split
            if sections.empty?
              be_empty
            else
              contain_exactly(*sections.map { |n| have_attributes(name: n) })
            end
          end

          aggregate_failures "segment sections" do
            elf_file.segments.each_with_index do |segment, i|
              expect(segment.sections).to matchers[i]
            end
          end
        end
      end
    end
  end
end
