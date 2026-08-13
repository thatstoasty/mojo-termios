"""Tests for `termios.terminal` option enums."""
from std.testing import assert_equal, assert_not_equal, TestSuite

from std.sys import CompilationTarget

from termios.terminal import FlowOption, FlushOption, WhenOption


def test_when_option_values() raises:
    # These are the one group that genuinely does match across platforms.
    assert_equal(WhenOption.TCSANOW.value, 0)
    assert_equal(WhenOption.TCSADRAIN.value, 1)
    assert_equal(WhenOption.TCSAFLUSH.value, 2)
    assert_equal(WhenOption.TCSASOFT.value, 16)


def test_flush_option_values() raises:
    # macOS numbers these 1/2/3; Linux numbers them 0/1/2.
    comptime base = Int32(1) if CompilationTarget.is_macos() else Int32(0)
    assert_equal(FlushOption.TCIFLUSH.value, base)
    assert_equal(FlushOption.TCOFLUSH.value, base + 1)
    assert_equal(FlushOption.TCIOFLUSH.value, base + 2)


def test_flow_option_values() raises:
    # macOS numbers these 1..4; Linux numbers them 0..3.
    comptime base = Int32(1) if CompilationTarget.is_macos() else Int32(0)
    assert_equal(FlowOption.TCOOFF.value, base)
    assert_equal(FlowOption.TCOON.value, base + 1)
    assert_equal(FlowOption.TCIOFF.value, base + 2)
    assert_equal(FlowOption.TCION.value, base + 3)


def test_flow_and_flush_options_are_distinct() raises:
    # FlowOption used to carry TCOFLUSH/TCIOFLUSH copy-pasted from FlushOption.
    assert_not_equal(FlowOption.TCIOFF.value, FlushOption.TCOFLUSH.value)
    assert_not_equal(FlowOption.TCION.value, FlushOption.TCIOFLUSH.value)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
