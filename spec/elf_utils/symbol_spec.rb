module ElfUtils
  RSpec.describe Symbol do
    describe "#ctype" do
      # only using the executables here because they're the ones that contain
      # symbols from test.c and types.c
      context_for_each_executable do |path, endian|
        # An ELF file can contain multiple object symbols with the same
        # name, but different addresses.  This happens when two source files
        # declare static variables with the same name.
        # This test case verifies that the Symbol#ctype method gets the correct
        # CType from the DWARF .debug_info section.
        it "will return the correct type when duplicate symbols exist" do
          var_name = "duplicate_variable"
          symbols = elf_file
            .symbols
            .select { |sym| sym.name == var_name }
          expect(symbols.size).to eq(2),
            "`duplicate_variable` should be defined twice"

          # We need to get the DIE for the variable from the compilation unit
          # for each source file
          # first get it from types.c
          die_types_c = elf_file
            .debug_info
            .compilation_unit("spec/data/types.c")
            .root_die
            .children
            .find { |die| die[:name] == var_name }
          expect(die_types_c).to_not be_nil,
            "failed to find `#{var_name}` die in `types.c` CU"

          # now get it from test.c
          die_test_c = elf_file
            .debug_info
            .compilation_unit("spec/data/test.c")
            .root_die
            .children
            .find { |die| die[:name] == var_name }
          expect(die_test_c).to_not be_nil,
            "failed to find `#{var_name}` die in `test.c` CU"

          symbols.each do |symbol|
            ctype = symbol.ctype
            expect(ctype).to_not be_nil
            if symbol.addr == die_test_c.location
              expect(symbol.ctype).to eq(die_test_c[:type].ctype)
            elsif symbol.addr == die_types_c.location
              expect(symbol.ctype).to eq(die_types_c[:type].ctype)
            else
              args = [
                die_test_c.location,
                die_test_c.offset,
                die_types_c.location,
                die_types_c.offset
              ]
              raise <<~ERR % args
                symbol address did not match any known variable location:
                  symbol:       #{symbol.inspect}
                  DIE(test.c):  location=0x%08x, DIE offset=0x%08x
                  DIE(types.c); location=0x%08x, DIE offset=0x%08x
              ERR
            end
          end
        end
      end
    end

    describe "#source_location" do
      context_for_each_dwarf_filetype do |path, endian|
        it "will return the source file and line of a function" do
          skip "no relocation support" if
              dwarf_file.section(".rel.debug_info") ||
                dwarf_file.section(".rela.debug_info")

          file = "spec/data/test.c"
          line = get_line_number(file, /^fib\(/)
          expect(line).to_not be_nil
          sym = dwarf_file.symbol("fib")
          expect(sym.source_location).to include(
            file: end_with(file),
            line:
          )
        end

        it "will return the source file and line of a variable" do
          skip "no relocation support" if
              dwarf_file.section(".rel.debug_info") ||
                dwarf_file.section(".rela.debug_info")

          file = "spec/data/test.c"
          line = get_line_number(file, /^char global_buf/)
          expect(line).to_not be_nil
          sym = dwarf_file.symbol("global_buf")
          expect(sym.source_location).to include(
            file: end_with(file),
            line:
          )
        end
      end
    end
  end
end
