# frozen_string_literal: true

require "elf_utils"
require "pry-rescue/rspec"
require "open3"

# we're using pry-rescue, and we want to ensure ctrl-c isn't handled by rspec
# when in pry, so we're going to make pry clear/restore the interrupt handler
# rspec installed.
Pry.hooks.add_hook(:before_session, :clear_int_handler) do |_, _, pry_instance|
  pry_instance.instance_variable_set(:@_sigint_orig,
    trap("INT") { raise Interrupt })
end
Pry.hooks.add_hook(:after_session, :restore_int_handler) do |_, _, pry_instance|
  trap("INT", pry_instance.instance_variable_get(:@_sigint_orig))
end

module Helpers
  # return the path to a file in the spec/data directory
  def data_path(path)
    File.expand_path(File.join("data", path), __dir__)
  end

  # standard:disable Lint/MixedRegexpCaptureTypes
  DATA_FILENAME_REGEX = %r{
    (?<bits>32|64)
    (?<endian>le|be)
    -
    (:?
      (?<release>release)
      |
      (:?dwarf(?<dwarf_bits>32|64)-v(?<dwarf_version>\d))
    )
    (?<ext>\.o|\.so)?
  }x
  # standard:enable Lint/MixedRegexpCaptureTypes

  # return human-readable description of data filename
  def data_desc(name)
    raise "unsupported name format: %p" % [name] unless
        (match = name.match(DATA_FILENAME_REGEX))
    buf = "ELF%d" % match[:bits]
    case match[:endian]
    when "be"
      buf << " big-endian"
    when "le"
      buf << " little-endian"
    end
    buf << if match[:release]
      " release"
    else
      " DWARF%d version %d" %
        [match[:dwarf_bits], match[:dwarf_version]]
    end

    case match[:ext]
    when nil
      buf << " executable"
    when ".o"
      buf << " object file"
    when ".so"
      buf << " shared object file"
    end

    buf << " (#{name})"
  end

  # returns an array of test data file path and human-readable description
  def context_for_each_elf_filetype(&block)
    Dir.glob("spec/data/test_*")
      .sort
      .each do |path|
        # For elf file types, we'll just cherry-pick the release file and one
        # of the dwarf files.  There's no difference at the elf layer between
        # the different dwarf versions
        next unless /release|dwarf32-v5/.match?(path)

        context data_desc(File.basename(path)) do
          let(:path) { path }
          let(:elf_file) { ElfUtils.open(path) }

          instance_exec(path, &block)
        end
      end
  end

  # returns an array of test data file path and human-readable description
  def context_for_each_dwarf_filetype(&block)
    Dir.glob("spec/data/{test,complex}_*")
      .sort
      .each do |path|
        next unless /dwarf/.match?(path)
        endian = case path
        when /(32|64)be/
          :big
        when /(32|64)le/
          :little
        else
          raise "unable to determine endian from path: #{path}"
        end
        context data_desc(File.basename(path)) do
          let(:path) { path }
          let(:dwarf_file) { ElfUtils.open(path) }

          instance_exec(path, endian, &block)
        end
      end
  end

  def context_for_each_executable(&block)
    Dir.glob("spec/data/complex_*")
      .sort
      .each do |path|
        endian = case path
        when /(32|64)be/
          :big
        when /(32|64)le/
          :little
        else
          raise "unable to determine endian from path: #{path}"
        end
        context data_desc(File.basename(path)) do
          let(:path) { path }
          let(:elf_file) { ElfUtils.open(path) }

          instance_exec(path, endian, &block)
        end
      end
  end

  def llvm_dwarfdump(path, section)
    @llvm_dwarfdump_cache ||= {}
    @llvm_dwarfdump_cache[[path, section]] ||= begin
      cmd = "llvm-dwarfdump --#{section} #{path}"
      buf, status = Open3.capture2(cmd)
      raise "command failed: #{cmd}\n#{buf}" unless status.success?
      buf.freeze
    end
  end

  def get_line_number(file, pattern)
    @line_number_cache ||= {}
    @line_number_cache[[file, pattern]] ||= File.readlines(file)
      .each_with_index do |buf, index|
      return index + 1 if buf.match?(pattern)
    end
  end
end

RSpec.configure do |config|
  config.include(Helpers)
  config.extend(Helpers)

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
