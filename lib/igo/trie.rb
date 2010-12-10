require 'igo/util'

class String
  def starts_with?(prefix)
    prefix = prefix.to_s
    self[0, prefix.length] == prefix
  end
end

class Node
  class Base
    def self.ids(nid)
      return (-1 * nid) - 1
    end
  end
  
  class Chck
    TERMINATE_CODE = 0
    TERMINATE_CHAR = TERMINATE_CODE.chr
    VACANT_CODE = 1
    CODE_LIMIT = 0xffff
  end
end

class KeyStream
  
  def initialize(key, start = 0)
    @s = key
    @cur = start
    @len = key.unpack("U*").size
  end
  
  def compare_to(ks)
    return rest.compare_to(ks.rest)
  end
  
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

# DoubleArray検索用のクラス
class Searcher
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
  
  def size
    return @key_set_size
  end
  
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

