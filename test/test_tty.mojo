"""Tests for `termios.tty` mode-building helpers.

These exercise the pure `Termios`-mutating functions (`cfmakeraw`,
`cfmakecbreak`) which require no real TTY, so they run in CI.
"""
from std.testing import assert_equal, TestSuite

from termios import c
from termios.c import ControlFlag, InputFlag, LocalFlag, OutputFlag, SpecialCharacter
from termios.tty import cfmakeraw, cfmakecbreak


def _all_ones() -> c.tcflag_t:
    """Returns a flag word with every bit set."""
    return ~c.tcflag_t(0)


def test_cfmakeraw_clears_input_flags() raises:
    var mode = c.Termios()
    mode.c_iflag = _all_ones()
    cfmakeraw(mode)

    comptime cleared = (
        InputFlag.IGNBRK.value
        | InputFlag.BRKINT.value
        | InputFlag.IGNPAR.value
        | InputFlag.PARMRK.value
        | InputFlag.INPCK.value
        | InputFlag.ISTRIP.value
        | InputFlag.INLCR.value
        | InputFlag.IGNCR.value
        | InputFlag.ICRNL.value
        | InputFlag.IXON.value
        | InputFlag.IXANY.value
        | InputFlag.IXOFF.value
    )
    assert_equal(mode.c_iflag & cleared, 0)


def test_cfmakeraw_disables_opost() raises:
    var mode = c.Termios()
    mode.c_oflag = _all_ones()
    cfmakeraw(mode)
    assert_equal(mode.c_oflag & OutputFlag.OPOST.value, 0)


def test_cfmakeraw_sets_8bit_char_size() raises:
    var mode = c.Termios()
    mode.c_cflag = _all_ones()
    cfmakeraw(mode)

    # Parity generation and the character-size mask must be cleared,
    # then CS8 set back on.
    assert_equal(mode.c_cflag & ControlFlag.PARENB.value, 0)
    assert_equal(mode.c_cflag & ControlFlag.CS8.value, ControlFlag.CS8.value)


def test_cfmakeraw_clears_local_flags() raises:
    var mode = c.Termios()
    mode.c_lflag = _all_ones()
    cfmakeraw(mode)

    comptime cleared = (
        LocalFlag.ECHO.value
        | LocalFlag.ECHOE.value
        | LocalFlag.ECHOK.value
        | LocalFlag.ECHONL.value
        | LocalFlag.ICANON.value
        | LocalFlag.IEXTEN.value
        | LocalFlag.ISIG.value
        | LocalFlag.NOFLSH.value
        | LocalFlag.TOSTOP.value
    )
    assert_equal(mode.c_lflag & cleared, 0)


def test_cfmakeraw_sets_min_and_time() raises:
    var mode = c.Termios()
    cfmakeraw(mode)
    assert_equal(mode.c_cc[SpecialCharacter.VMIN.value], 1)
    assert_equal(mode.c_cc[SpecialCharacter.VTIME.value], 0)


def test_cfmakeraw_preserves_unrelated_cflags() raises:
    # CREAD is not touched by raw mode and must survive.
    var mode = c.Termios()
    mode.c_cflag = ControlFlag.CREAD.value
    cfmakeraw(mode)
    assert_equal(mode.c_cflag & ControlFlag.CREAD.value, ControlFlag.CREAD.value)


def test_cfmakecbreak_clears_echo_and_canon() raises:
    var mode = c.Termios()
    # Include ISIG to confirm cbreak leaves unrelated local flags intact.
    mode.c_lflag = LocalFlag.ECHO.value | LocalFlag.ICANON.value | LocalFlag.ISIG.value
    cfmakecbreak(mode)

    assert_equal(mode.c_lflag & LocalFlag.ECHO.value, 0)
    assert_equal(mode.c_lflag & LocalFlag.ICANON.value, 0)
    # ISIG untouched.
    assert_equal(mode.c_lflag & LocalFlag.ISIG.value, LocalFlag.ISIG.value)


def test_cfmakecbreak_sets_min_and_time() raises:
    var mode = c.Termios()
    cfmakecbreak(mode)
    assert_equal(mode.c_cc[SpecialCharacter.VMIN.value], 1)
    assert_equal(mode.c_cc[SpecialCharacter.VTIME.value], 0)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
