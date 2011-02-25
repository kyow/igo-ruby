# -*- encoding: utf-8 -*-
#= 辞書クラス群

module Igo
  #
  # Viterbiアルゴリズムで使用されるノードクラス
  #
  class ViterbiNode
    attr_accessor :cost, :prev, :word_id, :start, :length, :left_id, :right_id, :is_space
    def initialize(word_id, start, length, left_id, right_id, is_space)
      @cost = 0            # 始点からノードまでの総コスト
      @prev = nil          # コスト最小の前方のノードへのリンク
      @word_id = word_id   # 単語ID
      @start = start       # 入力テキスト内での形態素の開始位置
      @length = length     # 形態素の表層形の長さ(文字数)
      @left_id = left_id   # 左文脈ID
      @right_id = right_id # 右文脈ID
      @is_space = is_space # 形態素の文字種(文字カテゴリ)が空白かどうか
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
    end
  end

  #
  # 形態素の連接コスト表クラス
  #
  class Matrix
    # コンストラクタ
    # data_dir:: 辞書ファイルのディレクトリパス
    def initialize(data_dir)
      fmis = FileMappedInputStream.new(data_dir + "/matrix.bin")
      @left_size = fmis.get_int
      @right_size = fmis.get_int
      @matrix = fmis.get_short_array(@left_size * @right_size)
      fmis.close
    end
  
    # 形態素同士の連接コストを求める
    # left_id:: 左文脈ID
    # right_id:: 右文脈ID
    def link_cost(left_id, right_id)
      return @matrix[right_id * @right_size + left_id]
    end
  end

  #
  # 未知語の検索を行うクラス
  #
  class Unknown
  
    # コンストラクタ
    #data_dir:: 辞書ファイルのディレクトリパス
    def initialize(data_dir)
      # 文字カテゴリ管理クラス
      @category = CharCategory.new(data_dir)
    
      # 文字カテゴリが空白の文字のID
      @space_id = @category.category(' '.unpack("U*")[0]).id
    end
  
    # 検索
    #text::
    #start::
    #wdic::
    #result::
    def search(text, start, wdic, result)
      txt = text.unpack("U*")
      length = txt.size
      ch = txt[start]
      ct = @category.category(ch)
    
      if !result.empty? and !ct.invoke
        return
      end
    
      is_space = (ct.id == @space_id)
      limit = [length, ct.length + start].min
    
      for i in start..(limit - 1)
        wdic.search_from_trie_id(ct.id, start, (i - start) + 1, is_space, result)
      
        if((i + 1) != limit and !(@category.compatible?(ch, text[i + 1])))
          return
        end
      end
    
      if ct.group and limit < length
        for i in limit..(length - 1)
          if not @category.compatible?(ch, txt[i])
            wdic.search_from_trie_id(ct.id, start, i - start, is_space, result)
            return
          end
        end
        wdic.search_from_trie_id(ct.id, start, length - start, is_space, result)
      end
    end
  end

  class WordDic
    # コンストラクタ
    #data_dir:: 辞書ファイルのディレクトリパス
    def initialize(data_dir)
      @trie = Searcher.new(data_dir + "/word2id")
      @data = FileMappedInputStream.get_string(data_dir + "/word.dat")
      @indices = FileMappedInputStream.get_int_array(data_dir + "/word.ary.idx")
    
      fmis = FileMappedInputStream.new(data_dir + "/word.inf")
      word_count = fmis.size / (4 + 2 + 2 + 2)
      @data_offsets = fmis.get_int_array(word_count)   # 単語の素性データの開始位置
      @left_ids     = fmis.get_short_array(word_count) # 単語の左文脈ID
      @right_ids    = fmis.get_short_array(word_count) # 単語の右文脈ID
      @costs        = fmis.get_short_array(word_count) # 単語のコスト
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
      return @data.slice(@data_offsets[word_id]*2..@data_offsets[word_id + 1]*2 - 1)
    end
  end
end
