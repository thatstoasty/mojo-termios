"""Validates every constant and the `Termios` layout against the real libc.

CPython's `termios` module is compiled against the same system headers as the
library under test, so it is used here as platform-independent ground truth.
This catches constants that were hardcoded to one platform's value — the class
of bug where `CS8` was 768 (macOS) on Linux too, and `FlushOption` used Linux's
0/1/2 numbering on macOS.
"""
from std.python import Python, PythonObject
from std.sys import CompilationTarget
from std.sys.info import size_of
from std.testing import assert_equal, TestSuite

from termios import c
from termios.c import ControlFlag, InputFlag, LocalFlag, OutputFlag, SpecialCharacter
from termios.terminal import FlowOption, FlushOption, WhenOption


def _libc() raises -> PythonObject:
    """Returns CPython's `termios` module, built against the system headers."""
    return Python.import_module("termios")


def _assert_matches_libc[T: Intable](name: StaticString, ours: T) raises:
    """Asserts `ours` equals the same-named constant in CPython's `termios`.

    Parameters:
        T: Anything convertible to `Int` for comparison.

    Args:
        name: The libc constant name, e.g. "CS8".
        ours: The value this library defines for it.
    """
    var expected = Int(py=_libc().__getattribute__(String(name)))
    assert_equal(Int(ours), expected, String("constant ", name, " disagrees with libc"))


def test_control_flags_match_libc() raises:
    _assert_matches_libc("CREAD", ControlFlag.CREAD.value)
    _assert_matches_libc("CLOCAL", ControlFlag.CLOCAL.value)
    _assert_matches_libc("PARENB", ControlFlag.PARENB.value)
    _assert_matches_libc("CSIZE", ControlFlag.CSIZE.value)
    # Regression: CS8 was unconditionally 768, which is PARENB|PARODD on Linux.
    _assert_matches_libc("CS8", ControlFlag.CS8.value)


def test_local_flags_match_libc() raises:
    _assert_matches_libc("ICANON", LocalFlag.ICANON.value)
    _assert_matches_libc("ECHO", LocalFlag.ECHO.value)
    _assert_matches_libc("ECHOE", LocalFlag.ECHOE.value)
    _assert_matches_libc("ECHOK", LocalFlag.ECHOK.value)
    _assert_matches_libc("ECHONL", LocalFlag.ECHONL.value)
    _assert_matches_libc("ISIG", LocalFlag.ISIG.value)
    _assert_matches_libc("IEXTEN", LocalFlag.IEXTEN.value)
    _assert_matches_libc("NOFLSH", LocalFlag.NOFLSH.value)
    _assert_matches_libc("TOSTOP", LocalFlag.TOSTOP.value)


def test_input_flags_match_libc() raises:
    _assert_matches_libc("IGNBRK", InputFlag.IGNBRK.value)
    _assert_matches_libc("BRKINT", InputFlag.BRKINT.value)
    _assert_matches_libc("IGNPAR", InputFlag.IGNPAR.value)
    _assert_matches_libc("PARMRK", InputFlag.PARMRK.value)
    _assert_matches_libc("INPCK", InputFlag.INPCK.value)
    _assert_matches_libc("ISTRIP", InputFlag.ISTRIP.value)
    _assert_matches_libc("INLCR", InputFlag.INLCR.value)
    _assert_matches_libc("IGNCR", InputFlag.IGNCR.value)
    _assert_matches_libc("ICRNL", InputFlag.ICRNL.value)
    _assert_matches_libc("IXON", InputFlag.IXON.value)
    _assert_matches_libc("IXANY", InputFlag.IXANY.value)
    _assert_matches_libc("IXOFF", InputFlag.IXOFF.value)


def test_output_flags_match_libc() raises:
    _assert_matches_libc("OPOST", OutputFlag.OPOST.value)


def test_special_character_indexes_match_libc() raises:
    _assert_matches_libc("VEOF", SpecialCharacter.VEOF.value)
    _assert_matches_libc("VEOL", SpecialCharacter.VEOL.value)
    _assert_matches_libc("VERASE", SpecialCharacter.VERASE.value)
    _assert_matches_libc("VINTR", SpecialCharacter.VINTR.value)
    _assert_matches_libc("VKILL", SpecialCharacter.VKILL.value)
    _assert_matches_libc("VMIN", SpecialCharacter.VMIN.value)
    _assert_matches_libc("VQUIT", SpecialCharacter.VQUIT.value)
    _assert_matches_libc("VSTART", SpecialCharacter.VSTART.value)
    _assert_matches_libc("VSTOP", SpecialCharacter.VSTOP.value)
    _assert_matches_libc("VSUSP", SpecialCharacter.VSUSP.value)
    _assert_matches_libc("VTIME", SpecialCharacter.VTIME.value)


def test_when_options_match_libc() raises:
    _assert_matches_libc("TCSANOW", WhenOption.TCSANOW.value)
    _assert_matches_libc("TCSADRAIN", WhenOption.TCSADRAIN.value)
    _assert_matches_libc("TCSAFLUSH", WhenOption.TCSAFLUSH.value)
    _assert_matches_libc("TCSASOFT", WhenOption.TCSASOFT.value)


def test_flush_options_match_libc() raises:
    # Regression: these were hardcoded to Linux's 0/1/2, so every `tcflush`
    # call on macOS (where they are 1/2/3) failed with EINVAL.
    _assert_matches_libc("TCIFLUSH", FlushOption.TCIFLUSH.value)
    _assert_matches_libc("TCOFLUSH", FlushOption.TCOFLUSH.value)
    _assert_matches_libc("TCIOFLUSH", FlushOption.TCIOFLUSH.value)


def test_flow_options_match_libc() raises:
    # Regression: FlowOption used to declare TCOFLUSH/TCIOFLUSH — names and
    # values copy-pasted from FlushOption — instead of TCIOFF/TCION.
    _assert_matches_libc("TCOOFF", FlowOption.TCOOFF.value)
    _assert_matches_libc("TCOON", FlowOption.TCOON.value)
    _assert_matches_libc("TCIOFF", FlowOption.TCIOFF.value)
    _assert_matches_libc("TCION", FlowOption.TCION.value)


def test_nccs_matches_libc() raises:
    _assert_matches_libc("NCCS", c.NCCS)
    assert_equal(c.Termios._CONTROL_CHARACTER_WIDTH, Int(py=_libc().NCCS))


def test_termios_size_matches_c_struct() raises:
    """`Termios` is passed by pointer to libc, so its size must match exactly.

    macOS: 4 * u64 flags + cc_t[20] + 2 * u64 speeds, padded = 72.
    Linux: 4 * u32 flags + cc_t c_line + cc_t[32] + 2 * u32 speeds, padded = 60.
    """
    comptime expected = 72 if CompilationTarget.is_macos() else 60
    assert_equal(size_of[c.Termios](), expected)


def test_line_discipline_field_is_linux_only() raises:
    """Linux's glibc `struct termios` has a `c_line` byte before `c_cc`."""
    comptime expected = 0 if CompilationTarget.is_macos() else 1
    assert_equal(c.Termios._LINE_DISCIPLINE_WIDTH, expected)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
