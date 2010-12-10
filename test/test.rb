require 'rubygems'
require 'igo-ruby'
tagger = Igo::Tagger.new('../../ipadic')
t = tagger.parse('吾輩は猫である。名前はまだ無い。')
t.each{|m|
  puts "#{m.surface} #{m.feature} #{m.start}"
}
t = tagger.wakati('どこで生れたかとんと見当がつかぬ。')
puts t.join(' ')
