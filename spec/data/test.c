/*
 * SPDX-FileCopyrightText: 2025 Cisco
 * SPDX-License-Identifier: MIT
 */
int global_int __attribute__((used)) = 42;
char global_buf[256] __attribute__((used)) = { 0 };

/* We want to confirm that ElfUtils can find the correct ctype for symbols with
 * the same name.  So create a static variable here with the same name as one
 * in types.c, but a different type */
static char duplicate_variable[32] __attribute__((used)) = "hello world";

unsigned
fib(unsigned i) {
    if (i == 0) {
        return 0;
    }
    if (i == 1) {
        return 1;
    }
    return fib(i - 1) + fib(i - 2);
}

void
variable_length_array(unsigned n) {
    unsigned array_variable_length[n];
    for (int i = 0; i < n; i++) {
        array_variable_length[i] = fib(i);
    }
}

int
main(int argc, char *argv[]) {
    return fib(10);
}
