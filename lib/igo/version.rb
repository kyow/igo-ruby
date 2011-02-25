# -*- encoding: utf-8 -*-
module Igo
  #
  #バージョンクラス
  #
  class Version
    #igo-rubyのRubyGemsバージョンを出力する
    def self.igo_ruby
      version_file = File.dirname(__FILE__) + '/../../VERSION'
      version = ""
      open(version_file) { |igo_ruby_version|
        version = igo_ruby_version.gets
      }
      return version
    end
  end
end