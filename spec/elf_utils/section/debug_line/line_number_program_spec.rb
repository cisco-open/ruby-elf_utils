module ElfUtils
  RSpec.describe Section::DebugLine::LineNumberProgram do
    context_for_each_dwarf_filetype do |path|
      let(:debug_line) { dwarf_file.section(".debug_line") }

      let(:parsed_line_number_programs) do
        header_regex = %r{
          ^debug_line\[(?<offset>0x\h+)\]\n
          Line\ table\ prologue:\n
          \s+total_length:\ (?<unit_length>0x\h+)\n
          \s+format:\ DWARF\d+\n
          \s+version:\ (?<version>\d+)\n
          (?:\s+address_size:\ (?<address_size>\d+)\n)?
          (?:\s+seg_select_size:\ (?<segment_selector_size>\d+)\n)?
          \s+prologue_length:\ (?<header_length>0x\h+)\n
          \s+min_inst_length:\ (?<minimum_instruction_length>\d+)\n
          (?:max_ops_per_inst:\ (?<maximum_operations_per_instruction>\d+)\n)?
          \s+default_is_stmt:\ (?<default_is_stmt>\d)\n
          \s+line_base:\ (?<line_base>-?\d+)\n
          \s+line_range:\ (?<line_range>\d+)\n
          \s+opcode_base:\ (?<opcode_base>\d+)\n
          (?<header_tail>.*?)\n\n
          (?<address_table>.*?)\n\n
        }mx
        file_regex = %r{
          file_names\[\s*(?<index>\d+)\]:\n
          \s+name:\ "(?<path>.*?)"\n
          \s+dir_index:\ (?<directory_index>\d+)\n
          (?:\s+mod_time:\ (?<timestamp>0x\h+)\n)?
          (?:\s+length:\ (?<size>0x\h+)\n)?
          (?:\s+md5_checksum:\ (?<md5>\h+)\n)?
        }mx
        addr_table_regex = %r{
          ^
          (?<address>0x\h+)\s+
          (?<line>\d+)\s+
          (?<column>\d+)\s+
          (?<file>\d+)\s+
          (?<isa>\d+)\s+
          (?<discriminator>\d+)\ *
          (?<flags>.*?)?
          $
        }x

        programs = []
        buf = llvm_dwarfdump(path, "debug-line")
        buf.scan(header_regex) do
          match = Regexp.last_match.named_captures
          match_save = match.dup
          tail = match.delete("header_tail") << "\n"
          addr_table_buf = match.delete("address_table") << "\n"

          header = match
            .delete_if { |_, v| v.nil? }
            .transform_values! { |v| v.to_i(0) }
          offset = header.delete("offset")
          opcodes = tail
            .scan(%r{^standard_opcode_lengths\[DW_LNS_.*?\] = (\d+)$})
            .flatten
            .map(&:to_i)
            .unshift(nil) # because opcodes start at 1
          directories = tail
            .scan(%r{^include_directories\[\s*(\d+)\] = "(.*?)"$})
            .each_with_object([]) do |(i, p), o|
              o[i.to_i] = {path: p}
              o
            end

          files = []
          tail.scan(file_regex) do
            file = Regexp.last_match.named_captures
              .delete_if { |_, v| v.nil? }
              .transform_keys(&:to_sym)
            index = file.delete(:index).to_i
            %i[directory_index timestamp size].each do |field|
              next unless (value = file[field])
              file[field] = value.to_i(0)
            end
            file[:md5] = [file[:md5]].pack("H*") if file.has_key?(:md5)
            files[index] = file
          end

          addr_table = []
          addr_table_buf.scan(addr_table_regex) do
            match = Regexp.last_match
              .named_captures
              .transform_keys(&:to_sym)
            %i[address line column file isa discriminator].each do |k|
              match[k] = match[k].to_i(0)
            end
            # llvm-dwarfdump debug-line added "OpIndex" column which results in
            # the "0" from that field getting added to flags.  Just deleting
            # that from flags for right now.  Not a proper fix, just a
            # work-around.
            match[:flags] = match[:flags].split.map(&:to_sym)
            match[:flags].delete(:"0")
            addr_table << match
          end

          programs << {
            raw: match_save,
            offset:,
            header:,
            opcode_lengths: opcodes,
            directories:,
            file_names: files,
            addr_table:
          }
        end
        programs
      end

      it "#header will return the expected values" do
        parsed_line_number_programs.each do |parsed|
          program = debug_line.line_number_program(parsed[:offset])
          expect(program.header).to have_attributes(parsed[:header])
        end
      end
      it "#standard_opcode_lengths will return the expected values" do
        parsed_line_number_programs.each do |parsed|
          program = debug_line.line_number_program(parsed[:offset])
          expect(program.standard_opcode_lengths)
            .to eq(parsed[:opcode_lengths])
        end
      end

      it "#directories will return the expected values" do
        parsed_line_number_programs.each do |parsed|
          program = debug_line.line_number_program(parsed[:offset])
          expect(program.directories).to eq(parsed[:directories])
        end
      end

      it "#file_names will return the expected values" do
        skip "no relocation support" unless
            dwarf_file.section(".rela.debug_info").nil?
        parsed_line_number_programs.each do |parsed|
          program = debug_line.line_number_program(parsed[:offset])
          expect(program.file_names).to eq(parsed[:file_names])
        end
      end

      it "#address_table will return the expected values" do
        parsed_line_number_programs.each do |parsed|
          program = debug_line.line_number_program(parsed[:offset])
          matcher = parsed[:addr_table].map { |a| have_attributes(a) }
          expect(program.address_table.values).to include(*matcher)
        end
      end

      it "#source_location will return correct location for valid addr" do
      end

      it "#source_location will return nil for unknown addr" do
      end
    end
  end
end
