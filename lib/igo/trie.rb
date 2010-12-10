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
#   puts "c = #{c} len = #{len}"
#   p s.unpack("U*")[c]
#   p [s.unpack("U*")[c]].pack("U*")
    word = s.unpack("U*")[c]
    if word.nil?
      return (prefix.slice(beg, len-beg) == nil)
    else
      [word].pack("U*").starts_with?(prefix.slice(beg, len-beg))
    end
#   return [s.unpack("U*")[c]].pack("U*").starts_with?(prefix.slice(beg, len-beg))
  end
  
  def rest
    return @s.slice(@cur, @s.length)
  end
  
  def read
#   puts "CUR=#{@cur}"
  
    if eos?
#     puts "EOS!!"
      return Node::Chck::TERMINATE_CODE
    else
      r = @s.unpack("U*")[@cur]
#     puts [r].pack("U*").tosjis
      result = [r].pack("U*")
#     result = @s.unpack("U*")[@cur]
      @cur += 1
      return r
#     p = @cur
#     @cur += 1
#     return @s[p]
    end
  end
  
  def eos?
#   puts "eos? #{@cur} == #{@len}"
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

#p @begs[0]
#p @base[0]
#p @lens[0]
#print @tail.tosjis
#print @tail[0].tosjis

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
    
#   puts "each_common_prefix"
    while true
      code = kin.read
      offset += 1
      terminal_index = node
#     terminal_index = node + Node::Chck::TERMINATE_CODE
#puts  "code #{code.tosjis}"
      
      if(chck[terminal_index] == Node::Chck::TERMINATE_CODE)
        callback.call(start, offset, Node::Base.ids(base[terminal_index]))
        
#       puts "code -> #{code} #{Node::Chck::TERMINATE_CHAR}"
        
        if(code == Node::Chck::TERMINATE_CODE)
#         puts code
#         puts "(1)"
          return
        end
      end
      
      # TODO
#puts  "code #{code.tosjis}"
#     p code
      idx = node + code
      node = base[idx]
      
#     code = [code].pack('U*')
      
      if(chck[idx] == code)
        if(node >= 0)
          next
        else
#         id = Node.Base.ids(node)
#         if(kin.start_with(@tail, @begs[id], lens[id]))
#           callback.call(start, offset+@lens[id]+1, id)
#         end

          call_if_key_including(kin, node, start, offset, callback)
        end
      end
#     puts code
#     puts "(2)"
      return
    end
  end
  
  private
  
  def call_if_key_including(kin, node, start, offset, callback)
#   puts "call_if_key_including"
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

