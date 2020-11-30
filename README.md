# Pololu CI for Arduino Libraries

This allows central management of the CI tests of Pololu's Arduino libraries. It uses arduino-cli to install dependencies and then it compiles every example with every board.

# Dependencies

* Linux-like operating system
* nix: https://nixos.org/guides/install-nix.html

# Usage

`ci.rb` is executable. Run it directly from the directory of an Arduino library. It will have a non-zero exit code if a compilation fails.

# Customization

Environment variables can be used to customize the tests:

* `ARDUINO_SKIP_CORES` - skips default cores (comma separated)
* `ARDUINO_ADD_CORES` -  adds additional cores (comma separated)
* `ARDUINO_ONLY_CORES` -  use only these cores (comma separated)
* `ARDUINO_SKIP_BOARDS` - skips default boards (comma separated)
* `ARDUINO_ADD_BOARDS` -  adds additional boards (comma separated)
* `ARDUINO_ONLY_BOARDS` -  use only these boards (comma separated)
* `ARDUINO_SKIP_ADDITIONAL_URLS` - skips default additional_urls (comma separated)
* `ARDUINO_ADD_ADDITIONAL_URLS` -  adds additional additional_urls (comma separated)
* `ARDUINO_ONLY_ADDITIONAL_URLS` -  use only these additional_urls (comma separated)
