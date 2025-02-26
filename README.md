# ElfUtils

[![Version](https://img.shields.io/gem/v/elf_utils.svg)](https://rubygems.org/gems/elf_utils)
[![GitHub](https://img.shields.io/badge/github-elf__utils-blue.svg)](http://github.com/cisco-open/ruby-elf_utils)
[![Documentation](https://img.shields.io/badge/docs-rdoc.info-blue.svg)](https://rubydoc.info/gems/elf_utils/frames)

[![Contributor-Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-fbab2c.svg)](CODE_OF_CONDUCT.md)
[![Maintainer](https://img.shields.io/badge/Maintainer-Cisco-00bceb.svg)](https://opensource.cisco.com)

ElfUtils is a Ruby gem for parsing ELF files and DWARF debugging information.

ElfUtils supports 32-bit & 64-bit ELF format, both big and little endian.  It
also supports DWARF versions 2, 3, 4, and 5.  The handling of both ELF and
DWARF formats **is not currently exhaustive**, but is sufficient to perform
many common tasks such as calculating symbol address, finding symbol source
location, extracting variable data types.

If you encounter a place where the format support is incomplete, please open
an issue.  We test against the generated binaries in [spec/data/](spec/data),
but need more real-world examples to ensure proper format coverage.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add elf_utils

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install elf_utils

## Usage
ElfUtils covers a lot of ELF & DWARF functionality.  The best source for usage
will be the documentation.  This is a small example of using ElfUtils to
read a complex type from the memory of a running process, given an executable
with DWARF debugging information to determine types.

```ruby
require "elf_utils"

# open an ELF file, in this case an executable
elf_file = ElfUtils.open("a.out")

# get the Symbol instance for a global variable
symbol = elf_file.symbol(:some_global_var)      # => #<ElfUtils::Symbol ...>

# get the address of the symbol
addr = symbol.addr                              # => 0x40001000

# relocate the load segments to account for ASLR.  Addresses for load segments
# extracted from /proc/pid/map.
elf_file.load_segments[0].relocate(text_addr)
elf_file.load_segments[1].relocate(data_addr)

# get the address of the symbol after relocation
addr = symbol.addr                              # => 0x90301000

# get the data type for the symbol; requires DWARF debug information
type = symbol.ctype                             # => #<CTypes::Struct ...>

# open the memory for a process running this executable, and read the value of
# the global variable.
value = File.open(File.join("/proc", pid, "mem")) do |mem|
    # read the raw bytes for the variable
    bytes = mem.pread(type.size, addr)          # => "\xef\x99\xde... "

    # unpack the bytes
    type.unpack_one(bytes)                      # => { field: val, ... }
end
```

### bin/dump_ctypes.rb
[bin/dump_ctypes.rb] reads the `.debug_info` section of an ELF file, and
generates ruby code to create each data type found in the binary.  This is
particularly useful for exporting types for use with foreign-function interface
(FFI).

```sh
~/src/elf_utils> bundle exec ./bin/dump_ctypes.rb spec/data/complex_64be-dwarf64-v5 > types.rb
cu[  0] 0x0        (   0kb)  spec/data/test.c
cu[  1] 0xdb       (   1kb)  spec/data/types.c
~/src/elf_utils> head types.rb
module Types
  extend CTypes::Helpers

  def self.with_bitfield
    @with_bitfield ||= CTypes::Struct.builder()
      .name("with_bitfield")
      .endian(:big)
      .attribute(bitfield {
          field :a, offset: 31, bits: 1, signed: false
          field :b, offset: 29, bits: 2, signed: true
```

## Roadmap

See the [open issues](https://github.com/cisco-open/ruby-elf_utils/issues) for
a list of proposed features (and known issues).

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake spec` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and the created tag, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

Running the test suite requires a recent version of llvm be installed.  The
tests use `llvm-readelf` and `llvm-dwarfdump` for verification.

## Contributing

Contributions are what make the open source community such an amazing place to
learn, inspire, and create. Any contributions you make are **greatly
appreciated**. For detailed contributing guidelines, please see
[CONTRIBUTING.md](CONTRIBUTING.md)

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT). License. See
[LICENSE.txt](LICENSE.txt) for more information.
