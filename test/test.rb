# coding: utf-8
require 'rubygems'
require File.dirname(__FILE__) + '/../lib/igo-ruby'

tagger = Igo::Tagger.new(File.dirname(__FILE__) + '/../../ipadic')
t = tagger.parse('吾輩は猫である。名前はまだ無い。')
puts "parse ->"
t.each{|m|
  puts "#{m.surface} #{m.feature} #{m.start}"
}
puts "wakati ->"
t = tagger.wakati('どこで生れたかとんと見当がつかぬ。')
puts t.join(' ')
