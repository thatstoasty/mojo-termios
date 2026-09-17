"""POSIX terminal attribute control via `tcgetattr`/`tcsetattr` wrappers."""
import std.sys._libc as libc
from std.sys.info import platform_map
from std.ffi import get_errno, ErrNo

from termios import c


@fieldwise_init
struct WhenOption(TrivialRegisterPassable, Writable):
    """TTY when values."""

    var value: Int32
    """Value for the option."""
    comptime TCSANOW = Self(0)
    """Change attributes immediately."""
    comptime TCSADRAIN = Self(1)
    """Change attributes after transmitting all queued output."""
    comptime TCSAFLUSH = Self(2)
    """Change attributes after transmitting all queued output and discarding all queued input."""
    comptime TCSASOFT = Self(16)
    """Change attributes without changing the terminal state."""


@fieldwise_init
struct FlowOption(TrivialRegisterPassable, Writable):
    """TTY flow control actions, for use with `tcflow`."""

    var value: Int32
    """Value for the option."""
    comptime TCOOFF = platform_map[macos=Self(1), linux=Self(0)]()
    """Suspends output."""
    comptime TCOON = platform_map[macos=Self(2), linux=Self(1)]()
    """Restarts suspended output."""
    comptime TCIOFF = platform_map[macos=Self(3), linux=Self(2)]()
    """Transmits a STOP character, which stops the terminal device from transmitting data to the system."""
    comptime TCION = platform_map[macos=Self(4), linux=Self(3)]()
    """Transmits a START character, which starts the terminal device transmitting data to the system."""


@fieldwise_init
struct FlushOption(TrivialRegisterPassable, Writable):
    """TTY queue selectors, for use with `tcflush`."""

    var value: Int32
    """Value for the option."""
    comptime TCIFLUSH = platform_map[macos=Self(1), linux=Self(0)]()
    """Flushes data received, but not read."""
    comptime TCOFLUSH = platform_map[macos=Self(2), linux=Self(1)]()
    """Flushes data written, but not transmitted."""
    comptime TCIOFLUSH = platform_map[macos=Self(3), linux=Self(2)]()
    """Flushes both data received, but not read. And data written, but not transmitted."""


def tcgetattr(file: FileDescriptor) raises ErrNo -> c.Termios:
    """Return the tty attributes for file descriptor.
    This is a wrapper around `c.tcgetattr()`.

    Args:
        file: File descriptor.

    Raises:
        * ErrNo: If the status returned from `tcgetattr` != 0.

    Returns:
        Termios struct.
    """
    var terminal_attributes = c.Termios()
    # TODO: tcgetattr expects a mutable pointer, dunno why.
    if c.tcgetattr(Int32(file.value), Pointer(to=terminal_attributes)) != 0:
        raise get_errno()

    return terminal_attributes


def tcsetattr(file: FileDescriptor, optional_actions: WhenOption, terminal_attributes: c.Termios) raises ErrNo -> None:
    """Set the tty attributes for file descriptor `file` from the attributes,
    which is a list like the one returned by c.tcgetattr(). The when argument determines when the attributes are changed:
    This is a wrapper around `c.tcsetattr()`.

    Args:
        file: File descriptor.
        optional_actions: When to change the attributes.
        terminal_attributes: Termios struct containing the attributes to set.

    Raises:
        * ErrNo: If the status returned from `tcsetattr` != 0.

    #### Notes:
    * `WhenOption.TCSANOW`: Change attributes immediately.
    * `WhenOption.TCSADRAIN`: Change attributes after transmitting all queued output.
    * `WhenOption.TCSAFLUSH`: Change attributes after transmitting all queued output and discarding all queued input.
    """
    if c.tcsetattr(Int32(file.value), optional_actions.value, Pointer(to=terminal_attributes)) != 0:
        raise get_errno()


def tcsendbreak(file: FileDescriptor, duration: c.c_int) raises ErrNo -> None:
    """Send a break on file descriptor `file`.
    A zero duration sends a break for 0.25 - 0.5 seconds; a nonzero duration has a system dependent meaning.

    Args:
        file: File descriptor.
        duration: Duration of break.

    Raises:
        * Error: [EBADF] If the file descriptor is invalid or not a terminal.
        * Error: [ENOTTY] If the file associated with `file` is not a terminal.
        * Error: [EIO] If the process group of the writing process is orphaned, and the writing process is not ignoring or blocking SIGTTOU.
    """
    if c.tcsendbreak(Int32(file.value), duration) != 0:
        raise get_errno()


def tcdrain(file: FileDescriptor) raises ErrNo -> None:
    """Wait until all output written to the object referred to by `file` has been transmitted.

    Args:
        file: File descriptor of the file to drain.

    Raises:
        * ErrNo: If the status returned from `tcflush` != 0.
    """
    if c.tcdrain(Int32(file.value)) != 0:
        raise get_errno()


def tcflush(file: FileDescriptor, queue_selector: FlushOption) raises ErrNo -> None:
    """Discard queued data on file descriptor `file`.

    Args:
        file: File descriptor to flush.
        queue_selector: Queue selector option.

    Raises:
        * ErrNo: If the status returned from `tcflush` != 0.

    #### Notes:
    * The queue selector specifies which queue:
        - `FlushOption.TCIFLUSH` for the input queue.
        - `FlushOption.TCOFLUSH` for the output queue.
        - `FlushOption.TCIOFLUSH` for both queues.
    """
    if c.tcflush(Int32(file.value), queue_selector.value) != 0:
        raise get_errno()


def tcflow(file: FileDescriptor, action: FlowOption) raises ErrNo -> None:
    """Suspend or resume input or output on file descriptor `file`.

    Args:
        file: File descriptor to suspend or resume I/O.
        action: Action to perform.

    Raises:
        * ErrNo: If the status returned from `tcflow` != 0.

    #### Notes:
    * `FlowOption.TCOOFF`: Suspends output.
    * `FlowOption.TCOON`: Restarts suspended output.
    * `FlowOption.TCIOFF`: Transmits a STOP character, which stops the terminal device from transmitting data to the system.
    * `FlowOption.TCION`: Transmits a START character, which starts the terminal device transmitting data to the system.
    """
    if c.tcflow(Int32(file.value), action.value) != 0:
        raise get_errno()


# Not available from libc
# def tc_getwinsize(file_descriptor: c.c_int) raises -> winsize:
#     """Return the window size of the terminal associated to file descriptor file_descriptor as a winsize object. The winsize object is a named tuple with four fields: ws_row, ws_col, ws_xpixel, and ws_ypixel.
#     """
#     var winsize_p = winsize()
#     var status = tcgetwinsize(file_descriptor, Pointer(to=winsize_p))
#     if status != 0:
#         raise Error("Failed tcgetwinsize." + String(status))

#     return winsize_p


# def tc_setwinsize(file_descriptor: c.c_int, winsize: Int32) raises -> Int32:
#     var status = tcsetwinsize(file_descriptor, winsize)
#     if status != 0:
#         raise Error("Failed tcsetwinsize." + String(status))

#     return status
