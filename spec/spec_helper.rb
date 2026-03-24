# frozen_string_literal: true

require "jekyll"
require "rspec"
require "pathname"

# Mock RMagick since it may not be installed in test environment
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
      # Mock strip
    end

    def copy
      self.class.new(@path)
    end

    def resize!(width, height)
      # Mock resize
    end

    def modulate(value)
      MockImage.new
    end

    def write(path, &block)
      # Mock write - create empty file
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, "mock image data")
    end

    def destroy!
      # Mock destroy
    end
  end

  class MockImage
    def modulate(*args)
      self
    end
  end

  # Mock include
  def self.include(mod)
    # No-op
  end
end

# Mock the require
def require(name)
  super unless name == 'rmagick'
end

require File.expand_path("../jekyll-rmagick.rb", __dir__)

ENV["JEKYLL_LOG_LEVEL"] = "error"

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = "random"

  # Directories for test fixtures
  SOURCE_DIR = File.expand_path("fixtures", __dir__)
  DEST_DIR   = File.expand_path("tmp/dest", __dir__)
  TMP_DIR    = File.expand_path("tmp", __dir__)

  def source_dir(*files)
    File.join(SOURCE_DIR, *files)
  end

  def dest_dir(*files)
    File.join(DEST_DIR, *files)
  end

  def tmp_dir(*files)
    File.join(TMP_DIR, *files)
  end

  # Create a Jekyll site with test configuration
  def jekyll_config(overrides = {})
    Jekyll.configuration(
      Jekyll::Utils.deep_merge_hashes(
        {
          "source"      => source_dir,
          "destination" => dest_dir,
          "plugins_dir" => source_dir("_plugins"),
          "verbose"     => false,
        },
        overrides
      )
    )
  end

  # Helper to create a site with configuration
  def make_site(overrides = {})
    config = jekyll_config(overrides)
    Jekyll::Site.new(config)
  end

  # Clean up test directories before/after tests
  config.before(:suite) do
    FileUtils.rm_rf(TMP_DIR)
    FileUtils.mkdir_p(source_dir("_posts"))
    FileUtils.mkdir_p(source_dir("_img"))
  end

  config.after(:suite) do
    FileUtils.rm_rf(TMP_DIR)
  end

  config.before(:each) do
    # Completely clean up test directories before each test
    FileUtils.rm_rf(TMP_DIR)
    FileUtils.mkdir_p(dest_dir)
    FileUtils.rm_rf(source_dir("_posts"))
    FileUtils.mkdir_p(source_dir("_posts"))
    FileUtils.mkdir_p(source_dir("_img"))
  end
end