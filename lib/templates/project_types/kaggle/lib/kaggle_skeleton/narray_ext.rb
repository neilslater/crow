require 'narray'

# KaggleSkeleton adds support for Marshal to NArray.
# Code originally from http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/194510
class NArray
  def _dump(*_ignored)
    Marshal.dump typecode: typecode, shape: shape, data: to_s
  end

  def self._load(buf)
    h = Marshal.load buf
    typecode = h[:typecode]
    shape = h[:shape]
    data = h[:data]
    to_na data, typecode, *shape
  end
end
