#!/usr/bin/env ruby

# frozen_string_literal: true

require "bundler/setup"
require "elf_utils"

f = ElfUtils.open(ARGV[0])
debug_info = f.section(".debug_info")

all_types = []
debug_info.cus.each_with_index do |cu, i|
  STDERR.puts "cu[%3d] 0x%-8x (%4dkb)  %s" %
    [i, cu.offset, cu.size >> 10, cu.root_die[:name]]
  cu.dies.each do |die|
    next unless die.type?
    next unless die[:name]

    case die.tag
    when :structure_type
      next unless die.children?
    when :typedef
      inner = die[:type].tag
      next unless %i{structure_type union_type enumeration_type}
        .include? inner
    when :union_type, :enumeration_type
      # noop, we want these
    else
      next
    end

    name = die.type_name
    type = die.ctype or binding.pry

    all_types << [name, type, die]
  end
end

types = {}
methods = {}
variants = Hash.new { |h,name| h[name] = Hash.new { |h,type| h[type] = [] } }
all_types.each do |name, type, die|
  next if types.has_key?(type)

  short_name = name.split[-1]

  if methods.has_key?(short_name)
    variants[short_name][type] << die
    next
  end

  types[type] = short_name
  methods[short_name] = type
end

printer = CTypes::Exporter::new($stdout)
printer.type_lookup = lambda { |t| types[t] }
printer << "module Types\n"
printer.nest(2) do
  printer << "extend CTypes::Helpers\n\n"
  methods.each do |name, type|
    printer << "def self.#{name}"
    printer.break
    printer.nest(2) do
      printer << "@#{name} ||= "
      type.export_type(printer)
      printer.break
    end
    printer << "end\n\n"
  end
end
printer << "end\n"
