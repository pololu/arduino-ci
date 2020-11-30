#!/usr/bin/env nix-shell
#!nix-shell -I nixpkgs=channel:nixos-20.09 -i ruby -p patchelf ruby arduino-cli "python3.withPackages(ps: [ ps.pyserial ])"

class String
  def red;            "\e[31m#{self}\e[0m" end
  def green;          "\e[32m#{self}\e[0m" end
  def magenta;        "\e[35m#{self}\e[0m" end
end

boards = %w(
  esp32:esp32:featheresp32
  esp8266:esp8266:huzzah
  arduino:avr:leonardo
  arduino:avr:mega
  arduino:avr:micro
  arduino:avr:uno
  arduino:avr:yun
  arduino:sam:arduino_due_x
  arduino:samd:arduino_zero_native
  Intel:arc32:arduino_101
  )
boards -= (ENV["ARDUINO_SUBTRACT_BOARDS"]&.split(',') || [])
boards += (ENV["ARDUINO_ADD_BOARDS"]&.split(',') || [])
boards = (ENV["ARDUINO_ONLY_BOARDS"]&.split(',') || boards)

cores = %w(
  arduino:avr
  arduino:sam
  arduino:samd
  Intel:arc32
  esp8266:esp8266
  esp32:esp32
  )
cores -= (ENV["ARDUINO_SUBTRACT_CORES"]&.split(',') || [])
cores += (ENV["ARDUINO_ADD_CORES"]&.split(',') || [])
cores = (ENV["ARDUINO_ONLY_CORES"]&.split(',') || cores)

additional_urls=%w(
  https://arduino.esp8266.com/stable/package_esp8266com_index.json
  https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
)

system("arduino-cli core update-index --additional-urls=\"#{additional_urls.join(",")}\"")
system("arduino-cli core install --additional-urls=\"#{additional_urls.join(",")}\" #{cores.join(" ")}")

# Fixup esp32 dynamically-linked binaries
zlib = `nix-build -I nixpkgs=channel:nixos-20.09 --no-out-link -E '(import <nixpkgs> {}).zlib'`.chomp
needs_patching = %W(
  #{Dir.home}/.arduino15/packages/esp32/tools/xtensa-esp32-elf-gcc/*/bin/*
)
needs_patching.each do |g|
  Dir.glob(g).each do |bin|
    system "patchelf --set-interpreter \"$(< \"$NIX_CC/nix-support/dynamic-linker\")\" --add-needed #{zlib}/lib/libz.so #{bin}"
  end
end

env="ARDUINO_DIRECTORIES_USER=\"$PWD/out\""
lib = "$PWD/out/libraries"
`rm -rf "#{lib}"`
`mkdir -p "#{lib}"`
`ln -s "$PWD" "#{lib}/OurLibrary"`
system("arduino-cli lib update-index")
prefix = "depends="

deps = File.read('library.properties').
         split.
         select { |line| line.start_with? prefix }.
         flat_map { |line| line.delete_prefix(prefix).split(",") }

system("#{env} arduino-cli lib install #{deps.join(" ")}") if deps.any?

compile_results = {}
Dir.glob('examples/*').each do |e|
  boards.each do |b|
    puts "Compiling #{e} for #{b}".magenta
    compile_results["#{e} for #{b}"] = system("#{env} arduino-cli compile --warnings all --fqbn \"#{b}\" \"#{e}\" --output-dir \"./out/#{e}\"")
  end
end

puts
puts "Compilation results".magenta
compile_results.each_pair do |key, value|
  puts "#{value ? "SUCCESS".green : "   FAIL".red} compiling #{key}"
end

exit compile_results.values.all?
