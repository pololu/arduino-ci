# Centralized CI for Arduino Libraries

This allows central management of the continuous integration (CI) tests of Arduino libraries. It uses arduino-cli to install dependencies and then it compiles every example with every board.

# Dependencies

* Linux-like operating system
* nix: https://nixos.org/guides/install-nix.html

# Usage

`ci.rb` is executable. Run it directly from the directory of an Arduino library. It will have a non-zero exit code if a compilation fails.

# Customization

Environment variables can be used to customize the tests:

* `ARDUINO_CI_SKIP_BOARDS` - skips default boards (comma separated)
* `ARDUINO_CI_ADD_BOARDS` -  adds additional boards (comma separated)
* `ARDUINO_CI_ONLY_BOARDS` -  use only these boards (comma separated)
* `ARDUINO_CI_SKIP_ADDITIONAL_URLS` - skips default additional_urls (comma separated)
* `ARDUINO_CI_ADD_ADDITIONAL_URLS` -  adds additional additional_urls (comma separated)
* `ARDUINO_CI_ONLY_ADDITIONAL_URLS` -  use only these additional_urls (comma separated)
* `ARDUINO_CI_LIBRARY_ARCHIVES` - additional library archives to download (semi-colon separated, format: `name=uri=hash`) For example: `ARDUINO_CI_LIBRARY_ARCHIVES="PololuMenu=https://github.com/pololu/pololu-menu-arduino/archive/1.0.0.tar.gz=0a1lg5pbylcrl1fc69237z6acwr8cgpbdx8bl8jx3lz4vkvjx6yr`.
