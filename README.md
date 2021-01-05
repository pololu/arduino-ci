# CI for Arduino Libraries

`arduino-ci` allows you to quickly add continuous integration (CI) tests to Arduino libraries. It uses `arduino-cli` to install dependencies and then it compiles every example with every board.

# Dependencies

* Linux-like operating system
* nix: https://nixos.org/guides/install-nix.html

# Usage

Run `arduino-ci/ci` from the directory of an Arduino library. It will have a non-zero exit code if a compilation fails. When it runs, it creates an `out` directory with all dependency libraries and the compilation artifacts. We recommended adding the `out` directory to your version control system's ignore file (like .gitignore).

## GitHub Actions example

Add the below code to a file named `.github/workflows/ci.yaml` to your library.

```yaml
name: "CI"
on:
  pull_request:
  push:
jobs:
  ci:
    runs-on: ubuntu-20.04
    steps:
    - name: Checkout this repository
      uses: actions/checkout@v2.3.4
    - name: Cache for arduino-ci
      uses: actions/cache@v2.1.3
      with:
        path: |
          ~/.arduino15
        key: ${{ runner.os }}-arduino
    - name: Install nix
      uses: cachix/install-nix-action@v12
    - run: nix-shell -I nixpkgs=channel:nixpkgs-unstable -p arduino-ci --run "arduino-ci"
```

## GitLab example

Add the below code to a file named `.gitlab-ci.yml` to your library.

```yaml
image: nixos/nix:2.3.6

stages:
  - ci

ci:
  stage: ci
  script:
    - nix-shell -I nixpkgs=channel:nixpkgs-unstable -p arduino-ci --run "arduino-ci"
```

# Defaults

All examples in your library are compiled with the following boards by default:

* esp8266:esp8266:huzzah
* arduino:avr:leonardo
* arduino:avr:mega
* arduino:avr:micro
* arduino:avr:uno
* arduino:avr:yun
* arduino:sam:arduino_due_x
* arduino:samd:arduino_zero_native
* Intel:arc32:arduino_101

`arduino-ci` installs the cores for each of these boards.

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
* `library_archives` - additional library archives to download (list, format: `name=uri=hash`)

### `.arduino-ci.yaml` example

```yaml
only_boards:
  - arduino:avr:leonardo
library_archives:
  - AStar32U4=https://github.com/pololu/a-star-32u4-arduino-library/archive/1.1.0.tar.gz=1z5mi80g2b4f9zbarl2kva2wr0flz8ym9nsb34p3rj5w4sq6zpdx
```

### Determining the hash of a library archive

The easiest way to determine the hash of a library is to start with an invalid hash (`0`):

```yaml
library_archives:
  - AStar32U4=https://github.com/pololu/a-star-32u4-arduino-library/archive/1.1.0.tar.gz=0
```

Then run `arduino-ci`. You should see something like:

```ShellSession
$ ci/ci
Updating index: package_index.json downloaded
Platform arduino:avr@1.8.3 already installed
error: hash '0' has wrong length for hash type 'sha256'
unpacking...
path is '/nix/store/mxa0gfrnjmdr9hximfylykhzs75mshr2-AStar32U4'
Hash mismatch for AStar32U4=https://github.com/pololu/a-star-32u4-arduino-library/archive/1.1.0.tar.gz=0
Wanted: 0
   Got: 1z5mi80g2b4f9zbarl2kva2wr0flz8ym9nsb34p3rj5w4sq6zpdx
```

Use the "Got:" hash:

```yaml
library_archives:
  - AStar32U4=https://github.com/pololu/a-star-32u4-arduino-library/archive/1.1.0.tar.gz=1z5mi80g2b4f9zbarl2kva2wr0flz8ym9nsb34p3rj5w4sq6zpdx
```

Then when you run it, it should work normally.

## Environment variables

Environment variables should only be used to quickly override settings when testing something out.

* `ARDUINO_CI_SKIP_BOARDS` - skips default boards (comma separated)
* `ARDUINO_CI_ADD_BOARDS` -  adds additional boards (comma separated)
* `ARDUINO_CI_ONLY_BOARDS` -  use only these boards (comma separated)
* `ARDUINO_CI_SKIP_ADDITIONAL_URLS` - skips default additional_urls (comma separated)
* `ARDUINO_CI_ADD_ADDITIONAL_URLS` -  adds additional additional_urls (comma separated)
* `ARDUINO_CI_ONLY_ADDITIONAL_URLS` -  use only these additional_urls (comma separated)
* `ARDUINO_CI_LIBRARY_ARCHIVES` - additional library archives to download (semi-colon separated, format: `name=uri=hash`) For example: `ARDUINO_CI_LIBRARY_ARCHIVES="PololuMenu=https://github.com/pololu/pololu-menu-arduino/archive/1.0.0.tar.gz=0a1lg5pbylcrl1fc69237z6acwr8cgpbdx8bl8jx3lz4vkvjx6yr"`.
