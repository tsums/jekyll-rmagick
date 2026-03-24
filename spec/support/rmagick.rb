module Magick
  class ImageList
    def initialize(path)
      @path = path
      @images = [MockImage.new]
    end

    def length
      @images.length
    end

    def size
      @images.size
    end

    def [](index)
      @images[index]
    end

    def []=(index, value)
      @images[index] = value
    end

    def strip!
    end

    def copy
      self.class.new(@path)
    end

    def resize!(width, height)
    end

    def write(path, &block)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, "mock image data")
    end

    def destroy!
    end
  end

  class MockImage
    def modulate(*args)
      self
    end
  end

  def self.include(mod)
  end
end
