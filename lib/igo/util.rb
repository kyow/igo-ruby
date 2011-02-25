# -*- encoding: utf-8 -*-
#= ファイルユーティリティ

module Igo
  #
  #=== ファイルにマッピングされた入力ストリーム
  # ファイルからバイナリデータを取得する場合、必ずこのクラスが使用される。
  #
  class FileMappedInputStream
    # 入力ストリームの初期化
    # path:: 入力ファイルのパス
    def initialize(path)
      @path = path
      @cur = 0
      @file = open(path, "rb")
    end
  
    # int値で読み取り
    def get_int()
      return @file.read(4).unpack("i*")[0]
    end
    
    # int配列で読み取り
    # count:: 読み取りカウント
    def get_int_array(count)
      return @file.read(count * 4).unpack("i*")
    end
  
    # int配列で読み取り
    # path:: 入力ファイルのパス
    def self.get_int_array(path)
      fmis = FileMappedInputStream.new(path)
      array = fmis.get_int_array((File::stat(path).size)/4)
      fmis.close
      return array
    end
  
    # short配列で読み取り
    # count:: 読み取りカウント
    def get_short_array(count)
      return @file.read(count * 2).unpack("s*")
    end
  
    # char配列で読み取り
    # count:: 読み取りカウント
    def get_char_array(count)
      return @file.read(count * 2).unpack("S!*")
    end
  
    # stringで読み取り
    # count:: 読み取りカウント
    def get_string(count)
      return @file.read(count * 2)
    end
  
    # stringで読み取り
    # path:: 入力ファイル
    def self.get_string(path)
      fmis = FileMappedInputStream.new(path)
      str = fmis.get_string((File::stat(path).size)/2)
      fmis.close
    
      return str
    end
  
    # 入力ファイルのサイズを返却する
    def size
      return File::stat(@path).size
    end
  
    # 入力ストリームを閉じる
    #* newした場合、必ずcloseを呼ぶこと
    def close
      @file.close
    end
  
    # char配列で読み取り
    # path:: 入力ファイル
    def self.get_char_array(path)
      fmis = FileMappedInputStream.new(path)
      array = fmis.get_char_array(fmis.size / 2)
      fmis.close
      return array
    end
  
    private
  
    # ファイルマップ
    #* 現在、不使用
    def map(size)
      @file.pos = @cur
      @cur += size
      return @file.read(size)
    end
  end
end