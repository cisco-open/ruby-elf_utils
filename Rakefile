# frozen_string_literal: true

require "bundler/setup"
require "bundler/gem_tasks"
require "rake/clean"
require "rspec/core/rake_task"
require "standard/rake"
require "rake/extensiontask"

RSpec::Core::RakeTask.new(:spec)

Rake::ExtensionTask.new "elf_utils" do |ext|
  ext.lib_dir = "lib/elf_utils"
end

task default: %i[compile]
task spec: %i[compile spec_data]

desc "Build the test data used in the specs"
task :spec_data

debug = {
  "release" => "-O2",
  "dwarf64-v5" => "-gdwarf-5 -gdwarf64 -O0",
  "dwarf32-v5" => "-gdwarf-5 -gdwarf32 -O0",
  "dwarf64-v4" => "-gdwarf-4 -gdwarf64 -O0",
  "dwarf32-v4" => "-gdwarf-4 -gdwarf32 -O0",
  "dwarf64-v3" => "-gdwarf-3 -gdwarf64 -O0",
  "dwarf32-v3" => "-gdwarf-3 -gdwarf32 -O0",
  "dwarf32-v2" => "-gdwarf-2 -gdwarf32 -O0"
}
target = {
  "32le" => "--target=i386-pc-linux-gnu",
  "64le" => "--target=x86_64-pc-linux-gnu",
  "32be" => "--target=mips-pc-linux-gnu",
  "64be" => "--target=mips64-pc-linux-gnu"
}
file_types = {
  "" => "-fuse-ld=lld -nostdlib", # executable
  ".o" => "-c",                   # object file
  ".so" => "-fPIC -fuse-ld=lld --shared -nostdlib" # shared object file
}

# basic elf/dwarf files
target.each do |target, target_flag|
  file_types.each do |ext, type_flag|
    debug.each do |debug, debug_flag|
      next if debug =~ /64/ && target =~ /32/

      path = "spec/data/test_#{target}-#{debug}#{ext}"
      task spec_data: path
      CLEAN << path
      file path => "spec/data/test.c" do |task|
        sh "#{ENV["CC"] || "clang"} #{debug_flag} #{target_flag} #{type_flag} #{task.source} -o #{task.name}"
      end
    end
  end
end

# DWARF files with multiple compilation units, including the types for testing
target.each do |target, target_flag|
  debug.each do |debug, debug_flag|
    next if debug == "release"
    next if debug =~ /64/ && target =~ /32/

    # grab the flags for an executable build
    type_flag = file_types[""]

    path = "spec/data/complex_#{target}-#{debug}"
    task spec_data: path
    CLEAN << path
    file path => ["spec/data/test.c", "spec/data/types.c"] do |task|
      sh "#{ENV["CC"] || "clang"} #{debug_flag} #{target_flag} #{type_flag} #{task.sources.join(" ")} -o #{task.name}"
    end
  end
end
