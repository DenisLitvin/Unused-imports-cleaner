#!/usr/bin/env ruby -w

class String
  def starts_with?(prefix)
    prefix.respond_to?(:to_str) && self[0, prefix.length] == prefix
  end
end

HEADER_REGEX = /^#import\s+["<](.*)[">]/

BUILD_DIR = File.expand_path("Path to xcproject")
BUILD_CMD = 'xcodebuild...'

Dir.chdir(ARGV.shift.to_s)

Dir.glob("*.m*") {|filename|
FILE_TO_MINIMIZE = filename
unless File.readable?(FILE_TO_MINIMIZE)
  puts "Usage: import_minimizer.rb FileToMinimize.m"
  puts "\t file path must be relative to #{BUILD_DIR} (or an absolute path)"
  exit 1
end

# Dir.chdir(BUILD_DIR)

lines        = open(FILE_TO_MINIMIZE, "r").each_line.to_a
line_no      = 0
counter      = 0

puts "testing #{FILE_TO_MINIMIZE}"
printf ". checking for duplicates"
seen_headers = []
while line_no < lines.length
  line = lines[line_no]
  line_no += 1

  next unless line.starts_with? "#import "

  header = line[HEADER_REGEX, 1]

  if seen_headers.include?(header)
    lines[line_no-1] = "// #{line.strip}  // -- duplicate\n"
    counter += 1
  end

  seen_headers << header
end
puts " - found: #{counter}"

line_no = 0
while line_no < lines.length
  line = lines[line_no]

  unless line.starts_with? "#import "
    line_no += 1
    next
  end

  orig_line = line
  header = line[HEADER_REGEX, 1]

  printf ". checking import: #{header}"

  lines[line_no] = "// #{orig_line.strip}  // -- not needed\n"
  open(FILE_TO_MINIMIZE, "w+") { |f| f.write(lines.join) }
  `#{BUILD_CMD}`
  if ($?.exitstatus != 0)
    lines[line_no] = orig_line
    puts "  -  needed"
  else
    puts "  -  NOT needed"
    counter += 1
  end

  line_no += 1
end
puts "\nFound #{counter} #import's that are not needed / duplicates"

open(FILE_TO_MINIMIZE, "w+") { |f| f.write(lines.join) }
}
