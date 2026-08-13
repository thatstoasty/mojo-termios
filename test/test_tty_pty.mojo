"""End-to-end tests against a real TTY.

`os.openpty()` hands back a genuine pseudo-terminal pair in-process, so these
run unattended in CI on both macOS and Linux without needing a controlling
terminal. Attributes set through this library are read back with CPython's
`termios` module, which makes these tests an ABI check as well as a behavioural
one: if the `Termios` struct layout drifted from the platform's C struct, the
flag and control-character comparisons below would disagree.
"""
from std.python import Python, PythonObject
from std.testing import assert_equal, assert_false, assert_true, TestSuite

from termios import c
from termios.c import ControlFlag, LocalFlag, OutputFlag, SpecialCharacter
from termios.terminal import FlowOption, FlushOption, WhenOption, tcflow, tcflush, tcgetattr, tcsetattr
from termios.tty import is_terminal_raw, set_cbreak, set_raw


struct _Pty(Movable):
    """An open pseudo-terminal pair, closed on scope exit.

    #### Notes:
    Mojo destroys locals immediately after their last use, and `f(pty.fd())`
    makes `fd()` that last use — so the pair would be closed before `f` runs.
    Every test therefore ends with `_ = pty^` to hold the pair open for the
    whole body. The destructor still runs if an assertion raises first.
    """

    var _os: PythonObject
    var master: Int
    """The master side file descriptor."""
    var slave: Int
    """The slave side file descriptor, i.e. the terminal itself."""

    def __init__(out self) raises:
        """Opens a new pseudo-terminal pair.

        Raises:
            Error: If the platform cannot allocate a pseudo-terminal.
        """
        self._os = Python.import_module("os")
        var pair = self._os.openpty()
        self.master = Int(py=pair[0])
        self.slave = Int(py=pair[1])

    def __deinit__(deinit self):
        """Closes both ends of the pair."""
        try:
            _ = self._os.close(self.master)
            _ = self._os.close(self.slave)
        except:
            pass

    def fd(self) -> FileDescriptor:
        """Returns the slave file descriptor, i.e. the terminal itself.

        Returns:
            The slave side file descriptor.
        """
        return FileDescriptor(self.slave)


def _reference_attributes(fd: Int) raises -> PythonObject:
    """Reads the terminal attributes via CPython, as `[if, of, cf, lf, isp, osp, cc]`.

    Control characters are normalised to `Int`, since CPython yields `bytes`
    for the character slots and `int` for the `VMIN`/`VTIME` slots.

    Args:
        fd: The file descriptor to read.

    Returns:
        The attribute list, with `cc` entries as ints.
    """
    var attributes = Python.import_module("termios").tcgetattr(fd)
    var normalise = Python.evaluate("lambda cc: [x if isinstance(x, int) else ord(x) for x in cc]")
    attributes[6] = normalise(attributes[6])
    return attributes


def test_termios_roundtrip_matches_cpython() raises:
    """Every field this library reads must agree with CPython's reading.

    This is the guard against `Termios` struct layout drift — notably the
    `c_line` byte that glibc places between `c_lflag` and `c_cc`, whose absence
    shifted every control character by one on Linux.
    """
    var pty = _Pty()
    var expected = _reference_attributes(pty.slave)
    var actual = tcgetattr(pty.fd())

    assert_equal(Int(actual.c_iflag), Int(py=expected[0]), "c_iflag")
    assert_equal(Int(actual.c_oflag), Int(py=expected[1]), "c_oflag")
    assert_equal(Int(actual.c_cflag), Int(py=expected[2]), "c_cflag")
    assert_equal(Int(actual.c_lflag), Int(py=expected[3]), "c_lflag")
    assert_equal(Int(actual.c_ispeed), Int(py=expected[4]), "c_ispeed")
    assert_equal(Int(actual.c_ospeed), Int(py=expected[5]), "c_ospeed")

    comptime for n in range(c.Termios._CONTROL_CHARACTER_WIDTH):
        assert_equal(Int(actual.c_cc[n]), Int(py=expected[6][n]), String("c_cc[", n, "]"))

    _ = pty^


def test_is_terminal_raw_tracks_raw_state() raises:
    """Regression: this reported `False` for a terminal that was actually raw.

    The predicate required `ICANON` to be *set*, but raw mode clears it.
    """
    var pty = _Pty()
    assert_false(is_terminal_raw(pty.fd()), "a fresh pty is in canonical mode")

    var original = set_raw(pty.fd())
    assert_true(is_terminal_raw(pty.fd()), "terminal should be raw after set_raw")

    tcsetattr(pty.fd(), WhenOption.TCSAFLUSH, original)
    assert_false(is_terminal_raw(pty.fd()), "terminal should be cooked again after restore")

    _ = pty^


def test_set_raw_applies_expected_flags() raises:
    """`set_raw` must actually reach the driver, not just mutate a local copy."""
    var pty = _Pty()
    _ = set_raw(pty.fd())
    var state = tcgetattr(pty.fd())

    assert_equal(state.c_lflag & LocalFlag.ICANON.value, 0, "ICANON cleared")
    assert_equal(state.c_lflag & LocalFlag.ECHO.value, 0, "ECHO cleared")
    assert_equal(state.c_lflag & LocalFlag.ISIG.value, 0, "ISIG cleared")
    assert_equal(state.c_oflag & OutputFlag.OPOST.value, 0, "OPOST cleared")
    assert_equal(state.c_cc[SpecialCharacter.VMIN.value], 1, "VMIN")
    assert_equal(state.c_cc[SpecialCharacter.VTIME.value], 0, "VTIME")

    _ = pty^


def test_set_raw_sets_eight_bit_characters() raises:
    """Regression: `CS8` held macOS's 768, which is `PARENB|PARODD` on Linux.

    Applying it there enabled odd parity and left the character size at CS5.
    """
    var pty = _Pty()
    _ = set_raw(pty.fd())
    var state = tcgetattr(pty.fd())

    assert_equal(state.c_cflag & ControlFlag.CSIZE.value, ControlFlag.CS8.value, "8-bit characters")
    assert_equal(state.c_cflag & ControlFlag.PARENB.value, 0, "parity disabled")

    _ = pty^


def test_set_cbreak_leaves_signals_and_output_intact() raises:
    """Unlike raw mode, cbreak only disables echo and canonical input."""
    var pty = _Pty()
    var before = tcgetattr(pty.fd())
    _ = set_cbreak(pty.fd())
    var state = tcgetattr(pty.fd())

    assert_equal(state.c_lflag & LocalFlag.ICANON.value, 0, "ICANON cleared")
    assert_equal(state.c_lflag & LocalFlag.ECHO.value, 0, "ECHO cleared")
    assert_equal(state.c_lflag & LocalFlag.ISIG.value, before.c_lflag & LocalFlag.ISIG.value, "ISIG untouched")
    assert_equal(state.c_oflag & OutputFlag.OPOST.value, before.c_oflag & OutputFlag.OPOST.value, "OPOST untouched")

    _ = pty^


def test_set_raw_returns_restorable_original() raises:
    """The returned attributes must round-trip the terminal back to its prior state."""
    var pty = _Pty()
    var before = _reference_attributes(pty.slave)

    var original = set_raw(pty.fd())
    tcsetattr(pty.fd(), WhenOption.TCSAFLUSH, original)

    var after = _reference_attributes(pty.slave)
    for i in range(4):
        assert_equal(Int(py=after[i]), Int(py=before[i]), String("flag word ", i, " restored"))

    _ = pty^


def test_tcflush_accepts_every_queue_selector() raises:
    """Regression: selectors held Linux's 0/1/2, so every call on macOS was EINVAL."""
    var pty = _Pty()
    tcflush(pty.fd(), FlushOption.TCIFLUSH)
    tcflush(pty.fd(), FlushOption.TCOFLUSH)
    tcflush(pty.fd(), FlushOption.TCIOFLUSH)

    _ = pty^


def test_tcflow_accepts_every_action() raises:
    """Regression: `FlowOption` exposed TCOFLUSH/TCIOFLUSH instead of TCIOFF/TCION."""
    var pty = _Pty()
    tcflow(pty.fd(), FlowOption.TCOOFF)
    tcflow(pty.fd(), FlowOption.TCOON)
    tcflow(pty.fd(), FlowOption.TCIOFF)
    tcflow(pty.fd(), FlowOption.TCION)

    _ = pty^


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
