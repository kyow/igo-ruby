# coding: utf-8
require 'rubygems'
#require 'igo-ruby'
require File.dirname(__FILE__) + '/../lib/igo-ruby'

puts "version -> #{Igo::Version.igo_ruby}"

tagger = Igo::Tagger.new(File.dirname(__FILE__) + '/../../ipadic')
t = tagger.parse('吾輩は猫である。名前はまだ無い。')

puts "parse 1st. ->"
t.each{|m|
  puts "#{m.surface} #{m.feature} #{m.start}"
}

t = tagger.parse('二回目の解析', t)
puts "parse 2nd. ->"
t.each{|m|
  puts "#{m.surface} #{m.feature} #{m.start}"
}

puts "wakati 1st. ->"
t = tagger.wakati('どこで生れたかとんと見当がつかぬ。')
puts t.join(' ')

puts "wakati 2nd. ->"
t = tagger.wakati('二回目の解析', t)
puts t.join(' ')

