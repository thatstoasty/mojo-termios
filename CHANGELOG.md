# Changelog

All notable changes to `mojo-termios` are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] — 0.2.3

### Changed

- **Breaking:** the public API now takes `std.io.RawFileDescriptor` instead of
  `FileDescriptor`. This affects `tcgetattr`, `tcsetattr`, `tcsendbreak`,
  `tcdrain`, `tcflush`, `tcflow`, `set_raw`, `set_cbreak`, and
  `is_terminal_raw`.
- Mojo requirement pinned to exactly `1.2.0` (`mojo` and `mojo-compiler`
  dependencies), replacing the `>=1.1.0,<1.2.0` range.
- README badge and install snippet updated for Mojo 1.2.0 and tag `v0.2.3`.

### Tests

- PTY tests hold master/slave descriptors as `Int32` and build
  `RawFileDescriptor` values from them.

## [0.2.2] — Mojo 1.1.0 support

### Changed

- **Breaking:** platform-specific constants are now resolved with
  `std.sys.info.platform_map` instead of `CompilationTarget.is_macos()`
  ternaries. Covers `NCCS`, `tcflag_t`, `c_speed_t`, `ControlFlag`,
  `LocalFlag`, `InputFlag`, `SpecialCharacter`, `Termios._LINE_DISCIPLINE_WIDTH`,
  `FlowOption`, and `FlushOption`. Values are unchanged; a target that is
  neither macOS nor Linux is now a compile-time error rather than silently
  taking the Linux branch.
- Mojo requirement moved to `>=1.1.0,<1.2.0` for `mojo` and `mojo-compiler`.
- README badge and install snippet updated for Mojo 1.1.0 and tag `v0.2.2`.

### Fixed

- `tcflag_t` now carries its own doc string instead of repeating the
  `CompilationTarget` note.

### Internal

- CI uses pixi `v0.77.1` with caching enabled (was `v0.70.2`, uncached).
- `.gitignore` ignores `*.mojoc` instead of `*.mojopkg`.

## [0.2.1] — Build backend relaxation

### Changed

- `pixi-build-mojo` build backend constraint relaxed from `0.1.*` to `0.*`.
