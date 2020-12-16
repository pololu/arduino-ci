#!/usr/bin/env nix-shell
#!nix-shell -I nixpkgs=channel:nixos-20.09 -i ruby -p ruby arduino-cli python3

class String
  def red;            "\e[31m#{self}\e[0m" end
  def green;          "\e[32m#{self}\e[0m" end
  def magenta;        "\e[35m#{self}\e[0m" end
end

config_file_path=".arduino-ci.yaml"
config = {}
if File.file?(config_file_path)
  require 'yaml'
  config = YAML.load_file(config_file_path)
end

boards = %w(
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
boards -= (config["skip_boards"] || [])
boards -= (ENV["ARDUINO_CI_SKIP_BOARDS"]&.split(',') || [])
boards += (config["add_boards"] || [])
boards += (ENV["ARDUINO_CI_ADD_BOARDS"]&.split(',') || [])
boards = (config["only_boards"] || boards)
boards = (ENV["ARDUINO_CI_ONLY_BOARDS"]&.split(',') || boards)

get_core = ->(b) { b.split(':')[0..1].join(':') }
cores = boards.map { |b| get_core[b] }.uniq

additional_urls = []
additional_urls << "https://arduino.esp8266.com/stable/package_esp8266com_index.json" if cores.include? "esp8266:esp8266"
additional_urls -= (config["skip_additional_urls"] || [])
additional_urls -= (ENV["ARDUINO_CI_SKIP_ADDITIONAL_URLS"]&.split(',') || [])
additional_urls += (config["add_additional_urls"] || [])
additional_urls += (ENV["ARDUINO_CI_ADD_ADDITIONAL_URLS"]&.split(',') || [])
additional_urls = (config["only_additional_urls"] || additional_urls)
additional_urls = (ENV["ARDUINO_CI_ONLY_ADDITIONAL_URLS"]&.split(',') || additional_urls)

system("arduino-cli core update-index --additional-urls=\"#{additional_urls.join(",")}\"")
system("arduino-cli core install --additional-urls=\"#{additional_urls.join(",")}\" #{cores.join(" ")}")

env="ARDUINO_DIRECTORIES_USER=\"$PWD/out\""
lib = "$PWD/out/libraries"
`rm -rf "#{lib}"`
`mkdir -p "#{lib}"`
`ln -s "$PWD" "#{lib}/OurLibrary"`

library_archive_deps=[]
library_archives = (config["library_archives"] || []) + (ENV["ARDUINO_CI_LIBRARY_ARCHIVES"]&.split(';') || [])
library_archives.each do |library_archive|
  match = /^([^=]*)=([^=]*)=(.*)$/.match(library_archive)
  unless match
    puts "error: badly formatted library_archive: #{library_archive}".red
    exit 1
  end
  name = match[1]
  library_archive_deps << name
  uri = match[2]
  wanted_hash = match[3]

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

    cpp_extra_flags =
      if get_core[b] == "Intel:arc32"
        # See https://github.com/arduino/ArduinoCore-arc32/issues/599 for why this workaround seems necessary
        'compiler.cpp.extra_flags=-D__ARDUINO_CI -D__CPU_ARC__ -DCLOCK_SPEED=32 -DCONFIG_SOC_GPIO_32 -DCONFIG_SOC_GPIO_AON -DINFRA_MULTI_CPU_SUPPORT -DCFW_MULTI_CPU_SUPPORT -DHAS_SHARED_MEM -I{build.system.path}/libarc32_arduino101/common -I{build.system.path}/libarc32_arduino101/drivers -I{build.system.path}/libarc32_arduino101/bootcode -I{build.system.path}/libarc32_arduino101/framework/include'
      else
       'compiler.cpp.extra_flags=-D__ARDUINO_CI'
      end

    compile_args= %W(
      --warnings all
       --fqbn "#{b}"
       --output-dir "./out/#{e}"
       --build-properties '#{cpp_extra_flags}'
       "#{e}"
    )
    compile_results["#{e} for #{b}"] = system("#{env} arduino-cli compile #{compile_args.join(" ")}")
  end
end

puts
puts "Compilation results".magenta
compile_results.each_pair do |key, value|
  puts "#{value ? "SUCCESS".green : "   FAIL".red} compiling #{key}"
end

exit compile_results.values.all?
