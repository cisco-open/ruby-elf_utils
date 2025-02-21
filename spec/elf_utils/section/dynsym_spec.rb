module ElfUtils
  RSpec.describe Section::Dynsym do
    describe "#symbols" do
      context_for_each_elf_filetype do
        it "will return symbols present in section" do
          dynsym = elf_file.section(".dynsym") or
            skip "no .dynsym section present"
          expect(dynsym.symbols.find("main")).to_not be_nil
        end
      end
    end
  end
end
