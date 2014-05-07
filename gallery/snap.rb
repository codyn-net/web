#!/usr/bin/ruby

template = File.read(ARGV[0])
ncol = File.read(ARGV[1]).split("\n")[0].split(" ").length - 1

repl = ''

(0..(ncol - 1)).each do |i|
	repl += "\\addplot table[x index=0, y index=#{i + 1}] {../../../#{ARGV[1]}};\n"
end

puts(template.gsub('{{PLOTS}}', repl))
