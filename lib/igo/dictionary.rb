#require 'trie'
#require 'util'
#require 'nkf'

# 辞書

class ViterbiNode
  attr_accessor :cost, :prev, :word_id, :start, :length, :left_id, :right_id, :is_space
  def initialize(word_id, start, length, left_id, right_id, is_space)
    @cost = 0
    @prev = nil
    @word_id = word_id
    @start = start
    @length = length
    @left_id = left_id
    @right_id = right_id
    @is_space = is_space
#   puts "==viterbinode #{word_id} #{start} #{length} #{left_id} #{right_id} #{is_space}"
  end
  
  def self.make_BOSEOS
    return ViterbiNode.new(0, 0, 0, 0, 0, false)
  end
end

class CharCategory
  def initialize(data_dir)
    @categories = CharCategory.read_categories(data_dir)
    fmis = FileMappedInputStream.new(data_dir + "/code2category")
    @char2id = fmis.get_int_array(fmis.size / 4 / 2)
    @eql_masks = fmis.get_int_array(fmis.size / 4 /2)
    fmis.close
  end
  
  def category(code)
    return @categories[@char2id[code]]
  end
  
  def compatible?(code1, code2)
#   puts @eql_masks[code1] & @eql_masks[code2]
    return (@eql_masks[code1] & @eql_masks[code2]) != 0
  end
  
  def self.read_categories(data_dir)
    data = FileMappedInputStream::get_int_array(data_dir + "/char.category")
    size = data.size / 4
    ary = []
    for i in 0 .. (size - 1)
      ary.push(Category.new(data[i * 4], data[i * 4 + 1], data[i * 4 + 2] == 1, data[i * 4 + 3] == 1))
    end
    return ary
  end
end

class Category
  attr_reader :id, :length, :invoke, :group
  def initialize(i, l, iv, g)
    @id = i
    @length = l
    @invoke = iv
    @group = g
#   puts "==category #{i} #{l} #{iv} #{g}"
  end
end

class Matrix
  def initialize(data_dir)
    fmis = FileMappedInputStream.new(data_dir + "/matrix.bin")
    @left_size = fmis.get_int
    @right_size = fmis.get_int
    @matrix = fmis.get_short_array(@left_size * @right_size)
    fmis.close
  end
  
  def link_cost(left_id, right_id)
    return @matrix[right_id * @right_size + left_id]
  end
end

class Unknown
  def initialize(data_dir)
    @category = CharCategory.new(data_dir)
    @space_id = @category.category(' '.unpack("U*")[0]).id
  end
  
  def search(text, start, wdic, result)
    txt = text.unpack("U*")
    length = txt.size
    ch = txt[start]
    ct = @category.category(ch)
    
#   puts "Unknown.search ch=#{ch} length=#{length} start=#{start}"
#   p ct
#   p result
#   p ct.invoke
    if !result.empty? and !ct.invoke
#     puts "result return"
      return
    end
#   puts "---i"
    
    is_space = (ct.id == @space_id)
    limit = [length, ct.length + start].min
    
#   puts "limit = #{limit} #{length} #{ct.length}"
    
    for i in start..(limit - 1)
#     puts "[a]"
      wdic.search_from_trie_id(ct.id, start, (i - start) + 1, is_space, result)
      
      if((i + 1) != limit and !(@category.compatible?(ch, text[i + 1])))
        return
      end
    end
    
    if ct.group and limit < length
#     puts "[b]"
      for i in limit..(length - 1)
#       puts "[c] COMPATIBLE? #{ch} #{txt[i + 1]}"
        
        if not @category.compatible?(ch, txt[i])
#         puts "[d] #{i} #{start}"
          wdic.search_from_trie_id(ct.id, start, i - start, is_space, result)
          return
        end
      end
#     puts "[e] #{length} #{start}"
      wdic.search_from_trie_id(ct.id, start, length - start, is_space, result)
    end
  end
end

class WordDic
  def initialize(data_dir)
    @trie = Searcher.new(data_dir + "/word2id")
    @data = FileMappedInputStream.get_string(data_dir + "/word.dat")
    @indices = FileMappedInputStream.get_int_array(data_dir + "/word.ary.idx")
    
    fmis = FileMappedInputStream.new(data_dir + "/word.inf")
    word_count = fmis.size / (4 + 2 + 2 + 2)
    @data_offsets = fmis.get_int_array(word_count)
    @left_ids     = fmis.get_short_array(word_count)
    @right_ids    = fmis.get_short_array(word_count)
    @costs        = fmis.get_short_array(word_count)
    fmis.close
  end
  
  def cost(word_id)
    return @costs[word_id]
  end
  
  def search(text, start, result)
    indices = @indices
    left_ids = @left_ids
    right_ids = @right_ids
    
    @trie.each_common_prefix(text, start, Proc.new { |start, offset, trie_id|
      ed = @indices[trie_id + 1]
      
      for i in indices[trie_id]..(ed - 1)
        result.push(ViterbiNode.new(i, start, offset, @left_ids[i], right_ids[i], false))
      end
    })
  end
  
  def search_from_trie_id(trie_id, start, word_length, is_space, result)
    ed = @indices[trie_id + 1]
    for i in @indices[trie_id]..(ed - 1)
      result.push(ViterbiNode.new(i, start, word_length, @left_ids[i], @right_ids[i], is_space))
    end
  end
  
  def word_data(word_id)
#  s = UTFConverter.utf16to8(@data)
    
#   st = format("%x", @data_offsets[word_id] * 2)
#   ed = format("%x", @data_offsets[word_id + 1] * 2)
    
#   puts "WORD DATA: #{word_id} = #{st} : #{ed}"
#   p   s
#   puts "nkf= " + NKF.nkf('-W16L0 --utf8', s)
#   p [s].pack("U*")
    return @data.slice(@data_offsets[word_id]*2..@data_offsets[word_id + 1]*2 - 1)
#   return NKF.nkf('-W16L0 --utf8', s)
  end
end

