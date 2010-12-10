# ユーティリティ

class FileMappedInputStream
  def initialize(path)
    @path = path
    @cur = 0
    @file = open(path, "r+b")
  end
  
  def get_int()
    return @file.read(4).unpack("i*")[0]
  end
  
  def get_int_array(count)
    return @file.read(count * 4).unpack("i*")
  end
  
  def self.get_int_array(path)
    fmis = FileMappedInputStream.new(path)
    array = fmis.get_int_array((File::stat(path).size)/4)
    fmis.close
    return array
  end
  
  def get_short_array(count)
    return @file.read(count * 2).unpack("s*")
  end
  
  def get_char_array(count)
    return @file.read(count * 2).unpack("S!*")
  end
  
  def get_string(count)
    return @file.read(count * 2)
  end
  
  def self.get_string(path)
    fmis = FileMappedInputStream.new(path)
    str = fmis.get_string((File::stat(path).size)/2)
    fmis.close
    
    return str
  end
  
  def size
    return File::stat(@path).size
  end
  
  def close
    @file.close
  end
  
  def self.get_char_array(path)
    fmis = FileMappedInputStream.new(path)
    array = fmis.get_char_array(fmis.size / 2)
    fmis.close
    return array
  end
  
  private
  
  def __map(size)
    @file.pos = @cur
    @cur += size
    return @file.read(size)
  end
end
