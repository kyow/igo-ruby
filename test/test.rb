# coding: utf-8
require 'rubygems'
require 'igo-ruby'
#require File.dirname(__FILE__) + '/../lib/igo-ruby'

puts "version -> #{Igo::Version.igo_ruby}"

tagger = Igo::Tagger.new(File.dirname(__FILE__) + '/../../ipadic')
t = tagger.parse('吾輩は猫である。名前はまだ無い。')
puts "parse ->"
t.each{|m|
  puts "#{m.surface} #{m.feature} #{m.start}"
}
puts "wakati ->"
t = tagger.wakati('どこで生れたかとんと見当がつかぬ。')
puts t.join(' ')

t = tagger.parse('取り敢えずビール')
puts "1.9 character code bug fix ->"
t.each{|m|
  puts "#{m.surface} #{m.feature} #{m.start}"
}

t = tagger.parse('Let’s Dance')
puts "Fix error raised when fullwidth symbol mixed ->"
t.each{|m|
  puts "#{m.surface} #{m.feature} #{m.start}"
}
