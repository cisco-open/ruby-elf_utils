module ElfUtils
  RSpec.describe Section::DebugLine do
    describe "#line_number_program" do
      context_for_each_dwarf_filetype do |path|
        let(:debug_line) { dwarf_file.section(".debug_line") }

        it "will return a LineNumberProgram for a valid offset" do
          expect(debug_line.line_number_program(0)).to be_a(Section::DebugLine::LineNumberProgram)
        end
      end
    end
  end
end
