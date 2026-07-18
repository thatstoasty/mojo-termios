"""Tests for `termios.c` types and flag constants."""
from std.testing import assert_equal, TestSuite

from termios import c
from termios.c import ControlFlag, InputFlag, OutputFlag, SpecialCharacter


def test_termios_default_is_zeroed() raises:
    var mode = c.Termios()
    assert_equal(mode.c_iflag, 0)
    assert_equal(mode.c_oflag, 0)
    assert_equal(mode.c_cflag, 0)
    assert_equal(mode.c_lflag, 0)
    assert_equal(mode.c_ispeed, 0)
    assert_equal(mode.c_ospeed, 0)


def test_termios_default_control_chars_zeroed() raises:
    var mode = c.Termios()
    comptime for n in range(c.Termios._CONTROL_CHARACTER_WIDTH):
        assert_equal(mode.c_cc[n], 0)


def test_cs8_is_platform_independent() raises:
    # CS8 is defined as 768 on every platform.
    assert_equal(ControlFlag.CS8.value, 768)


def test_opost_flag_value() raises:
    assert_equal(OutputFlag.OPOST.value, 1)


def test_input_flag_values() raises:
    # A handful of POSIX input flags with fixed cross-platform values.
    assert_equal(InputFlag.IGNBRK.value, 1)
    assert_equal(InputFlag.BRKINT.value, 2)
    assert_equal(InputFlag.ISTRIP.value, 32)
    assert_equal(InputFlag.INLCR.value, 64)


def test_ctimespec_as_nanoseconds() raises:
    # 2 seconds + subsecond component, evaluated per-platform.
    var ts = c._CTimeSpec(tv_sec=2, tv_subsec=5)
    comptime if c.CompilationTarget.is_linux():
        # subsec is nanoseconds on Linux.
        assert_equal(ts.as_nanoseconds(), 2 * c._NSEC_PER_SEC + 5)
    else:
        # subsec is microseconds on macOS.
        assert_equal(ts.as_nanoseconds(), 2 * c._NSEC_PER_SEC + 5 * c._NSEC_PER_USEC)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
