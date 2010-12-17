require 'igo/util'

#
#Stringクラスの拡張
#
class String
  # 文字列がパラメタの接頭辞で開始するかどうかを返却する
  #prefix:: 接頭辞
  #return:: true - 接頭辞で開始する
  def starts_with?(prefix)
    prefix = prefix.to_s
    self[0, prefix.length] == prefix
  end
end

module Igo

  #
  #DoubleArrayのノード用の定数などが定義されているクラス
  #
  class Node
    #
    #BASEノード用のメソッドが定義されているクラス
    #
    class Base
      #BASEノードに格納するID値をエンコードする
      def self.ids(nid)
        return (-1 * nid) - 1
      end
    end
  
    #
    #CHECKノード用の定数が定義されているクラス
    #
      class Chck
      #文字列の終端文字コード
      #この文字はシステムにより予約されており、辞書内の形態素の表層形および解析対象テキストに含まれていた場合の動作は未定義
      TERMINATE_CODE = 0
      #文字列の終端を表す文字定数
      TERMINATE_CHAR = TERMINATE_CODE.chr
      #CHECKノードが未使用であることを示す文字コード
      #この文字はシステムにより予約されており、辞書内の形態素の表層形および解析対象テキストに含まれていた場合の動作は未定義
      VACANT_CODE = 1
      #使用可能な文字の最大値
      CODE_LIMIT = 0xffff
    end
  end

  #
  #文字列を文字のストリームとして扱うためのクラス
  #* readメソッドで個々の文字を順に読み込み、文字列の終端に達した場合にはNode::Chck::TERMINATE_CODEが返される。
  #
  class KeyStream
  
    def initialize(key, start = 0)
      @s = key
      @cur = start
      @len = key.unpack("U*").size
    end
    
    def compare_to(ks)
      return rest.compare_to(ks.rest)
    end
  
    #このメソッドは動作的には、rest().starts_with?(prefix.substring(beg, len))と等価。
    #ほんの若干だが、パフォーマンスを改善するために導入。
    #簡潔性のためになくしても良いかもしれない。
    def start_with(prefix, beg, len)
      s = @s
      c = @cur
      if @len - c < len
        return false
      end
      word = s.unpack("U*")[c]
      if word.nil?
        return (prefix.slice(beg, len-beg) == nil)
      else
        [word].pack("U*").starts_with?(prefix.slice(beg, len-beg))
      end
    end
  
    def rest
      return @s.slice(@cur, @s.length)
    end
  
    def read
  
      if eos?
        return Node::Chck::TERMINATE_CODE
      else
        r = @s.unpack("U*")[@cur]
        result = [r].pack("U*")
        @cur += 1
        return r
      end
    end
  
    def eos?
      return (@cur == @len) ? true : false
    end
  end

  #
  # DoubleArray検索用のクラス
  #
  class Searcher
    #保存されているDoubleArrayを読み込んで、このクラスのインスタンスを作成する
    #path:: DoubleArrayが保存されているファイルのパス
    def initialize(path)
      fmis = FileMappedInputStream.new(path)
      node_size = fmis.get_int()
      tind_size = fmis.get_int()
      tail_size = fmis.get_int()
      @key_set_size = tind_size
      @begs = fmis.get_int_array(tind_size)
      @base = fmis.get_int_array(node_size)
      @lens = fmis.get_short_array(tind_size)
      @chck = fmis.get_char_array(node_size)
      @tail = fmis.get_string(tail_size)
      fmis.close
    end
  
    #DoubleArrayに格納されているキーの数を返却
    #return:: DoubleArrayに格納されているキーの数
    def size
      return @key_set_size
    end
  
    #キーを検索する
    #key:: 検索対象のキー文字列
    #return:: キーが見つかった場合はそのIDを、見つからなかった場合は-1を返す
    def search(key)
      base = @base
      chck = @chck
      node = @base[0]
      kin = KeyStream.new(key)
    
      while true
        code = kin.read
        idx = node + code
        node = base[idx]
      
        if(chck[idx] == code)
          if(node >= 0)
            next
          elsif(kin.eos? or key_exists?(kin, node))
            return Node::Base.ids(node)
          end
          return -1
        end
      end
    end
  
    #common-prefix検索を行う
    #* 条件に一致するキーが見つかる度に、callback.callメソッドが呼び出される
    #key:: 検索対象のキー文字列
    #start:: 検索対象となるキー文字列の最初の添字
    #callback:: 一致を検出した場合に呼び出されるコールバックメソッド
    def each_common_prefix(key, start, callback)
      base = @base
      chck = @chck
      node = @base[0]
      offset = -1
      kin = KeyStream.new(key, start)
    
      while true
        code = kin.read
        offset += 1
        terminal_index = node
      
        if(chck[terminal_index] == Node::Chck::TERMINATE_CODE)
          callback.call(start, offset, Node::Base.ids(base[terminal_index]))
        
          if(code == Node::Chck::TERMINATE_CODE)
            return
          end
        end
      
        idx = node + code
        node = base[idx]
      
        if(chck[idx] == code)
          if(node >= 0)
            next
          else
            call_if_key_including(kin, node, start, offset, callback)
          end
        end
        return
      end
    end
  
    private
  
    def call_if_key_including(kin, node, start, offset, callback)
      node_id = Node::Base.ids(node)
      if(kin.start_with(@tail, @begs[node_id], @lens[node_id]))
        callback.call(start, offset + @lens[node_id] + 1, node_id)
      end
    end
  
    def key_exists?(kin, node)
      nid = Node.Base.ids(node)
      beg = @begs[nid]
      s = @tail.slice(beg, beg + @lens[nid])
      return kin.rest == s ? true : false
    end
  end
end
