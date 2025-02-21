module ElfUtils
  RSpec.describe Section do
    describe "#relocate" do
      context_for_each_elf_filetype do
        let(:section) { elf_file.section(".text") }
        it "will update `Section#addr`" do
          section.relocate(0x40000000)
          expect(section.addr).to eq(0x40000000)
        end
        it "will update `Symbol#addr` for symbols in `Section`" do
          symbol = section.symbol("main")
          orig_addr = symbol.addr
          offset = 0x40000000 - section.addr
          section.relocate(0x40000000)
          expect(symbol.addr).to eq(orig_addr + offset)
        end
      end
    end
  end
end
