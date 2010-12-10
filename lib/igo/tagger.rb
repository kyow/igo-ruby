require 'igo/dictionary'
require 'igo/trie'

module Igo

class Morpheme
  attr_accessor :surface, :feature, :start
  def initialize(surface, feature, start)
    @surface = surface
    @feature = feature
    @start = start
  end
end

# 形態素解析を行う
class Tagger
  def self.__BOS_NODES
    return [ViterbiNode.make_BOSEOS]
  end
  
  def initialize(dir)
    @wdc = WordDic.new(dir)
    @unk = Unknown.new(dir)
    @mtx = Matrix.new(dir)
  end
  
  # 
  def parse(text, result=[])
    vn = impl(text, result)
    txt = text.unpack("U*")
    while vn
      surface = txt.slice(vn.start, vn.length).pack("U*")
      
      s = @wdc.word_data(vn.word_id)
      
#     puts s.size
      feature = NKF.nkf('-W16L0 --utf8', s)
#     feature = @wdc.word_data(vn.word_id)
      result.push(Morpheme.new(surface, feature, vn.start))
      vn = vn.prev
    end
    return result
  end
  
  
  # 分かち書きを行う
  def wakati(text, result=[])
    vn = impl(text, result)
    txt = text.unpack("U*")
    
    while vn
#     puts "s:#{vn.start} len:#{vn.length}"
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
    
#   puts "len=#{len}"
    
    node_ary = [Tagger.__BOS_NODES]
    for i in 0..(len-1)
      node_ary.push([])
    end
    
    for i in 0..(len-1)
      per_result = []
      
#     puts "==> node_ary[#{i}].length = #{!node_ary[i].empty?}"
#     p node_ary
      unless node_ary[i].empty?
        @wdc.search(text, i, per_result)
#       puts "---WDC---"
#       p per_result
        @unk.search(text, i, @wdc, per_result)
#       puts "---UNK---"
#       p per_result
        prevs = node_ary[i]
        
        for j in 0..(per_result.size - 1)
          vn = per_result[j]
#         p vn
          if(vn.is_space)
#           puts "#{j} is space (#{i + vn.length}) i=#{i} len=#{vn.length}"
            node_ary[i + vn.length] = prevs
#           p node_ary
#           node_ary[i + vn.length].push(prevs)
          else
#           puts "#{j} is NOT space (#{i + vn.length}) i=#{i} len=#{vn.length}"
            node_ary[i + vn.length].push(set_min_cost_node(vn, prevs))
#           p node_ary
#           node_ary[i + vn.length] + set_min_cost_node(vn, prevs)
          end
#         p node_ary
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
    
#   return cur.reverse
    
  end
  
  def set_min_cost_node(vn, prevs)
    f = vn.prev = prevs[0]
#   puts "=> set_min_cost_node"
#   p f

    vn.cost = f.cost + @mtx.link_cost(f.right_id, vn.left_id)
    
#   puts "#{vn.cost} #{f.cost} #{f.right_id} #{vn.left_id} #{@mtx.link_cost(f.right_id, vn.left_id)} #{}"
    
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