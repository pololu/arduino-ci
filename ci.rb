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
boards -= (ENV["ARDUINO_CI_SKIP_BOARDS"]&.split(',') || [])
boards += (ENV["ARDUINO_CI_ADD_BOARDS"]&.split(',') || [])
boards = (ENV["ARDUINO_CI_ONLY_BOARDS"]&.split(',') || boards)

cores = boards.map { |b| b.split(':')[0..1].join(':') }.uniq

additional_urls = []
additional_urls << "https://arduino.esp8266.com/stable/package_esp8266com_index.json" if cores.include? "esp8266:esp8266"
additional_urls << "https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json" if cores.include? "esp32:esp32"
additional_urls -= (ENV["ARDUINO_CI_SKIP_ADDITIONAL_URLS"]&.split(',') || [])
additional_urls += (ENV["ARDUINO_CI_ADD_ADDITIONAL_URLS"]&.split(',') || [])
additional_urls = (ENV["ARDUINO_CI_ONLY_ADDITIONAL_URLS"]&.split(',') || additional_urls)

system("arduino-cli core update-index --additional-urls=\"#{additional_urls.join(",")}\"")
system("arduino-cli core install --additional-urls=\"#{additional_urls.join(",")}\" #{cores.join(" ")}")

if cores.include? "esp32:esp32"
  # Fixup esp32 dynamically-linked binaries
  zlib = `nix-build -I nixpkgs=channel:nixos-20.09 --no-out-link -E '(import <nixpkgs> {}).zlib'`.chomp
  cpplib = `nix-build -I nixpkgs=channel:nixos-20.09 --no-out-link -E '(import <nixpkgs> {}).stdenv.cc.cc.lib'`.chomp
  Dir.glob("#{Dir.home}/.arduino15/packages/esp32/tools/xtensa-esp32-elf-gcc/*/bin/*").each do |bin|
    system "patchelf --set-interpreter \"$(< \"$NIX_CC/nix-support/dynamic-linker\")\" --add-needed #{zlib}/lib/libz.so --add-needed #{cpplib}/lib/libstdc++.so.6 #{bin}"
  end
end

env="ARDUINO_DIRECTORIES_USER=\"$PWD/out\""
lib = "$PWD/out/libraries"
`rm -rf "#{lib}"`
`mkdir -p "#{lib}"`
`ln -s "$PWD" "#{lib}/OurLibrary"`

library_archive_deps=[]
ENV["ARDUINO_CI_LIBRARY_ARCHIVES"]&.scan(/([^=]*)=([^=]*)=([^;]*)/) do |match|
  name = match[0]
  library_archive_deps << name
  uri = match[1]
  wanted_hash = match[2]

  path=`nix-prefetch-url --unpack --print-path --name #{name} #{uri} #{wanted_hash}`.chomp
  if path.empty?
    got_hash=`nix-prefetch-url --unpack --name #{name} #{uri}`.chomp
    puts "Hash mismatch for #{match}"
    puts "Wanted: #{wanted_hash}"
    puts "   Got: #{got_hash}"
    exit 1
  end
  store_path = path.lines.last.inspect
  `ln -s #{store_path} #{lib}/#{name}`
end

system("arduino-cli lib update-index")
prefix = "depends="
deps = File.read('library.properties').
         split.
         select { |line| line.start_with? prefix }.
         flat_map { |line| line.delete_prefix(prefix).split(",") } - library_archive_deps
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
