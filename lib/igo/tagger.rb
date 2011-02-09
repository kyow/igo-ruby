# coding: utf-8
#形態素解析と分かち書きを行う機能の実装

require 'igo/dictionary'
require 'igo/trie'

module Igo
  #
  #形態素クラス
  #
  class Morpheme
    attr_accessor :surface, :feature, :start
    
    #surface:: 形態素の表層形
    #feature:: 形態素の素性
    #start:: テキスト内でも形態素の出現開始位置
    def initialize(surface, feature, start)
      @surface = surface
      @feature = feature
      @start = start
    end
end

  #
  #形態素解析を行うクラス
  #
  class Tagger
    def self.__BOS_NODES
      return [ViterbiNode.make_BOSEOS]
    end
    
    #dir:: 辞書ファイルのディレクトリパス
    def initialize(dir)
      @wdc = WordDic.new(dir)
      @unk = Unknown.new(dir)
      @mtx = Matrix.new(dir)
    end
    
    #形態素解析を行う
    #text:: 解析対象テキスト
    #result:: 解析結果の形態素が追加される配列
    #return:: 解析結果の形態素配列
    def parse(text, result=[])
      vn = impl(text, result)
      txt = text.unpack("U*")
      while vn
        surface = txt.slice(vn.start, vn.length).pack("U*")
      
        s = @wdc.word_data(vn.word_id)
      
        feature = NKF.nkf('-W16L0 --utf8', s)
        result.push(Morpheme.new(surface, feature, vn.start))
        vn = vn.prev
      end
      return result
    end
  
    #分かち書きを行う
    #text:: 分かち書きされるテキスト
    #result:: 分かち書き結果の文字列が追加される配列
    #return:: 分かち書き結果の文字列の配列
    def wakati(text, result=[])
      vn = impl(text, result)
      txt = text.unpack("U*")
    
      while vn
        a = txt.slice(vn.start, vn.length).pack("U*")
        result.push(a)
        vn = vn.prev
      end
      return result
    end
  
    private
  
    def impl(text, result=[])
      txs = text.unpack("U*")
      len = txs.size
    
      node_ary = [Tagger.__BOS_NODES]
      for i in 0..(len-1)
        node_ary.push([])
      end
    
      for i in 0..(len-1)
        per_result = []
      
        unless node_ary[i].empty?
          @wdc.search(text, i, per_result)
          @unk.search(text, i, @wdc, per_result)
          prevs = node_ary[i]
        
          for j in 0..(per_result.size - 1)
            vn = per_result[j]
            if(vn.is_space)
              node_ary[i + vn.length] = prevs
            else
              node_ary[i + vn.length].push(set_min_cost_node(vn, prevs))
            end
          end
        end
      end
    
      cur = set_min_cost_node(ViterbiNode.make_BOSEOS, node_ary[len]).prev
    
      # reverse
      head = nil
      while cur.prev
        tmp = cur.prev
        cur.prev = head
        head = cur
        cur = tmp
      end
      return head
    end
  
    def set_min_cost_node(vn, prevs)
      f = vn.prev = prevs[0]
      vn.cost = f.cost + @mtx.link_cost(f.right_id, vn.left_id)
    
      for i in 1..(prevs.size - 1)
        p = prevs[i]
        cost = p.cost + @mtx.link_cost(p.right_id, vn.left_id)
        if(cost < vn.cost)
          vn.cost = cost
          vn.prev = p
        end
      end
      vn.cost += @wdc.cost(vn.word_id)
      return vn
    end
  end

end