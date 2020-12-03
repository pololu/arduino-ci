# CI for Arduino Libraries

`arduino-ci` allows you to quickly add continuous integration (CI) tests to Arduino libraries. It uses `arduino-cli` to install dependencies and then it compiles every example with every board.

# Dependencies

* Linux-like operating system
* nix: https://nixos.org/guides/install-nix.html

# Usage

Run `arduino-ci/ci` from the directory of an Arduino library. It will have a non-zero exit code if a compilation fails.

# Customization

There are two ways to customize `arduino-ci`.

* `.aduino-ci.yaml` config file in the top-level directory of your library (*recommended*)
* environment variables (for quick tests)

Yaml configurations are applied first and environment variables are applied last.

## `.arduino-ci.yaml` configuration file

The configuration file supports this top-level mapping:

* `skip_boards` - skips default boards (list)
* `add_boards` -  adds additional boards (list)
* `only_boards` -  use only these boards (list)
* `skip_additional_urls` - skips default additional_urls (list)
* `add_additional_urls` -  adds additional additional_urls (list)
* `only_additional_urls` -  use only these additional_urls (list)
* `library_archives` - additional library archives to download (list, format: `name=uri=hash`) For example: `PololuMenu=https://github.com/pololu/pololu-menu-arduino/archive/1.0.0.tar.gz=0a1lg5pbylcrl1fc69237z6acwr8cgpbdx8bl8jx3lz4vkvjx6yr`.

## Environment variables

Environment variables should only be used to quickly override settings when testing something out.

* `ARDUINO_CI_SKIP_BOARDS` - skips default boards (comma separated)
* `ARDUINO_CI_ADD_BOARDS` -  adds additional boards (comma separated)
* `ARDUINO_CI_ONLY_BOARDS` -  use only these boards (comma separated)
* `ARDUINO_CI_SKIP_ADDITIONAL_URLS` - skips default additional_urls (comma separated)
* `ARDUINO_CI_ADD_ADDITIONAL_URLS` -  adds additional additional_urls (comma separated)
* `ARDUINO_CI_ONLY_ADDITIONAL_URLS` -  use only these additional_urls (comma separated)
* `ARDUINO_CI_LIBRARY_ARCHIVES` - additional library archives to download (semi-colon separated, format: `name=uri=hash`) For example: `ARDUINO_CI_LIBRARY_ARCHIVES="PololuMenu=https://github.com/pololu/pololu-menu-arduino/archive/1.0.0.tar.gz=0a1lg5pbylcrl1fc69237z6acwr8cgpbdx8bl8jx3lz4vkvjx6yr"`.
