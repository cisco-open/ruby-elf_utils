require "open3"
require "jsonpath"

module ElfUtils
  RSpec.describe ElfFile do
    describe "#open" do
      it "will raise an error for a non-ELF file" do
        expect { ElfFile.open(__FILE__) }.to raise_error(InvalidFormat)
      end

      context_for_each_elf_filetype do
        it "will not raise an error when opening a valid ELF file" do
          ElfFile.open(path)
        end
      end
    end

    describe "#elf_class" do
      context_for_each_elf_filetype do
        it "will not raise an error when opening a valid ELF file" do
          value = path.include?("_32") ? :elf32 : :elf64
          expect(elf_file.elf_class).to eq(value)
        end
      end
    end

    describe "#shstrtab" do
      context_for_each_elf_filetype do
        it "will return the .shstrtab section" do
          expect(elf_file.shstrtab).to be_a(Section::Strtab)
        end
      end
    end

    describe "#sections" do
      context_for_each_elf_filetype do
        it "will include the .text section" do
          expect(elf_file.sections).to include(
            have_attributes(name: ".text", flags: [:alloc, :execinstr])
          )
        end
        it "will include the .data section" do
          expect(elf_file.sections).to include(
            have_attributes(name: ".data", flags: [:write, :alloc])
          )
        end
        it "will include the .symtab section" do
          expect(elf_file.sections).to include(
            have_attributes(name: ".symtab")
              .and(be_a(Section::Symtab))
          )
        end
      end
    end

    describe "#symbol" do
      context_for_each_elf_filetype do
        it "will return a `Symbol` when symbol exists" do
          expect(elf_file.symbol(:main)).to be_a(ElfUtils::Symbol)
        end
        it "will return nil when symbol does not exist" do
          expect(elf_file.symbol(:does_not_exist)).to be_nil
        end
      end
    end

    describe "#symbol_at_addr" do
      context_for_each_elf_filetype do
        it "will return a `Symbol` when a symbol at that address exists" do
          main = elf_file.symbol(:main)

          # verify the start address
          expect(elf_file.symbol_at_addr(main.addr)).to eq(main)

          # verify the end address
          addr = main.addr + main.size - 1
          expect(elf_file.symbol_at_addr(addr)).to eq(main)
        end
        it "will return nil when no symbol matches the address" do
          expect(elf_file.symbol_at_addr(0xffffffff)).to be_nil
        end
      end
    end

    describe "#segments" do
      context_for_each_elf_filetype do
        let(:elf_segments) do
          json, _s = Open3.capture2("llvm-readelf --elf-output-style=JSON -l %s" %
                                path)
          JsonPath.new("$..ProgramHeader").on(json)
        end
        it "will return the expected segments" do
          skip "no program headers in object files" if path.end_with?(".o")

          matcher = elf_segments.map do |seg|
            # llvm 15 or 16 changed the json output here; check for newer
            # "Name" field first.
            name, value = if seg["Type"].has_key?("Name")
              [seg["Type"]["Name"][3..], [seg["Type"]["Value"]]]
            else
              [seg["Type"]["Value"][3..], [seg["Type"]["RawValue"]]]
            end
            have_attributes(
              type:
                eq(name.downcase.to_sym) | eq(("unknown_%x" % value).to_sym),
              addr: seg["VirtualAddress"],
              offset: seg["Offset"],
              size: seg["MemSize"],
              filesize: seg["FileSize"],
              align: seg["Alignment"]
            )
          end
          expect(elf_file.segments).to include(*matcher)
        end
      end
    end
  end
end
