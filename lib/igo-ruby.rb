# coding: utf-8
#
#= 形態素解析エンジンIgoのRuby実装
#解析結果がほぼMeCab互換の形態素解析エンジン"Igo"のRuby実装
#
#Copyright:: Copyright (c) 2010, 2011, kyow
#Authors:: K.Nishi
#License:: MIT License ただし、使用する辞書のライセンスに関しては、辞書配布元のそれに準ずる
#
#== 注意
#igo-rubyには辞書ファイルを生成する機能はありません。
#Igoで生成した辞書ファイルを使用してください。
#
#== 公開
#* RubyGems
#  * igo-ruby[https://rubygems.org/gems/igo-ruby]
#* ソース(github)
#  * {kyow/igo-ruby}[https://github.com/kyow/igo-ruby]
#
#== 参照
#* Igo
#  1. {Igo - Java形態素解析器}[http://igo.sourceforge.jp/index.html]
#  2. {Igo}[http://sourceforge.jp/projects/igo/releases/]
#* Igo-python
#  1. {igo-python 0.3a}[http://pypi.python.org/pypi/igo-python/0.3a]
#  2. {Igo Japanease morphological analyzer for python}[https://launchpad.net/igo-python/]
#

$:.unshift(File.dirname(__FILE__))

require 'nkf'
require 'kconv'

#
#== Igoモジュール
#
module Igo
  autoload :Tagger, 'igo/tagger'
  autoload :Version, 'igo/version'
end
