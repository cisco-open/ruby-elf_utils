module ElfUtils
  RSpec.describe Section::DebugAbbrev do
    describe "#abbreviation_table" do
      context_for_each_dwarf_filetype do |path|
        let(:debug_abbrev) { dwarf_file.section(".debug_abbrev") }

        let(:table_matchers) do
          # regex for parsing llvm-dwarfdump output
          regex = %r{
          ^
          (?:
           Abbrev\ table\ for\ offset:\ (?<offset>0x\h+)
          |
          # some abbreviation entries have no attributes; ex: `const void`
          \[(?<code>\d+)\]
            \ DW_TAG_(?<tag>\S+)
            \tDW_CHILDREN_(?<children>yes|no)
            \n\n
          |
          \[(?<code>\d+)\]
            \ DW_TAG_(?<tag>\S+)
            \tDW_CHILDREN_(?<children>yes|no)
            \n
            \t(?<attrs>.*?)
            \n\n
          )
          }mx

          # dump the debug-abbrev section
          buf, _ = Open3.capture2("llvm-dwarfdump --debug-abbrev #{path}")

          # we'll construct a hash of table offset => matcher
          matchers = {}
          table = nil
          buf.scan(regex) do
            captures = Regexp.last_match.named_captures

            if (offset = captures["offset"])
              matchers[offset.to_i(16)] = (table = [])
              next
            end

            attrs = if (attr_buf = captures["attrs"])
              attr_buf.scan(/DW_AT_(\w+)\tDW_FORM_(\w+)/)
                .map do |name, form|
                  have_attributes(name: name.to_sym, form: form.to_sym)
                end
            else
              []
            end

            table << have_attributes(
              code: captures["code"].to_i,
              tag: captures["tag"].to_sym,
              children: (captures["children"] == "no") ? 0 : 1,
              attribute_specifications: contain_exactly(*attrs)
            )
          end

          # give them the matchers
          matchers
        end

        it "will return the abbreviation table at that offset" do
          table_matchers.each do |offset, matcher|
            table = debug_abbrev.abbreviation_table(offset)
            expect(table.declarations.values)
              .to contain_exactly(*matcher)
          end
        end
      end
    end
  end
end
