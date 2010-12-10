$:.unshift(File.dirname(__FILE__))

require 'nkf'
require 'jcode'
require 'kconv'

module Igo
  autoload :Tagger, 'igo/tagger'
end
