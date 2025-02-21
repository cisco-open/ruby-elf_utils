/*
 * SPDX-FileCopyrightText: 2025 Cisco
 * SPDX-License-Identifier: MIT
 */

#include <ruby.h>

static VALUE
uleb128_unpack_one(int argc, VALUE *argv, VALUE self)
{
    if (argc < 1) {
        rb_raise(rb_eArgError,
            "wrong number of arguments (given %d, expected at least 1)", argc);
    }

    char *buf       = StringValuePtr(argv[0]);
    size_t len      = rb_str_length(argv[0]);
    size_t offset   = 0;
    uint64_t result = 0; // ran into conversion issues when using 128bit
    int shift       = 0;

    while (offset < len) {
        uint8_t byte = *(buf + offset++);
        result |= (uint64_t)(byte & 0x7F) << shift;

        // If the MSB is not set, we're done
        if ((byte & 0x80) == 0) {
            // not returning a bigint here because the dry-types enum does not
            // return the correct value for BigInts.
            return rb_ary_new3(2, rb_uint2inum(result),
                rb_str_substr(argv[0], offset, len - offset));
        }

        // Move to the next 7 bits
        shift += 7;
    }

    rb_raise(rb_eRuntimeError, "ULEB128 string did not contain a terminator");
}

// Initialization function called when the extension is loaded
void
Init_elf_utils()
{
    // Define the class, if not defined already, and bind the C function
    VALUE rb_elf_utils = rb_define_module("ElfUtils");
    VALUE rb_types     = rb_define_module_under(rb_elf_utils, "Types");
    VALUE rb_uleb128   = rb_define_module_under(rb_types, "ULEB128");

    // Define the class method (static function) in the class
    rb_define_module_function(
        rb_uleb128, "unpack_one", uleb128_unpack_one, -1);
}
