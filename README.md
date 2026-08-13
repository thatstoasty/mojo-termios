# mojo-termios

`mojo-termios` provides FFI bindings for Termios.

![Mojo Version](https://img.shields.io/badge/Mojo%F0%9F%94%A5-1.0.0-orange)
![Build Status](https://github.com/thatstoasty/mojo-termios/actions/workflows/build.yml/badge.svg)
![Test Status](https://github.com/thatstoasty/mojo-termios/actions/workflows/test.yml/badge.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Adding the `termios` package to your project

First, you'll need to enable the `pixi-build` preview by adding this to the `workspace` section of your `pixi.toml` file.

```bash
preview = ["pixi-build"]
```

### Building it from source

There's two ways to build `termios` from source: directly from the Git repository or by cloning the repository locally.

#### Building from source: Git

Run the following commands in your terminal:

```bash
pixi add termios -g "https://github.com/thatstoasty/mojo-termios.git" --tag "v0.1.1" && pixi install
```

#### Building from source: Local

```bash
# Clone the repository to your local machine
git clone https://github.com/thatstoasty/mojo-termios.git

# Add the package to your project from the local path
pixi add -s ./path/to/mojo-termios && pixi install
```
