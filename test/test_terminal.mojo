"""Tests for `termios.terminal` option enums."""
from std.testing import assert_equal, TestSuite

from termios.terminal import WhenOption, FlushOption


def test_when_option_values() raises:
    assert_equal(WhenOption.TCSANOW.value, 0)
    assert_equal(WhenOption.TCSADRAIN.value, 1)
    assert_equal(WhenOption.TCSAFLUSH.value, 2)
    assert_equal(WhenOption.TCSASOFT.value, 16)


def test_flush_option_values() raises:
    # FlushOption values are fixed across platforms.
    assert_equal(FlushOption.TCIFLUSH.value, 0)
    assert_equal(FlushOption.TCOFLUSH.value, 1)
    assert_equal(FlushOption.TCIOFLUSH.value, 2)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
