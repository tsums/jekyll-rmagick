# frozen_string_literal: true

require "jekyll"
require "rspec"
require "pathname"

# Add the mock rmagick to the load path
$LOAD_PATH.unshift(File.expand_path("support", __dir__))

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

  # Helper to create a test post
  def create_post(title: "Test Post", img_src: "sample_image.jpg", content: "Test content", filename: "2024-01-01-test.md")
    frontmatter = [
      "---",
      "layout: default",
      "title: #{title}"
    ]
    frontmatter << "img_src: #{img_src}" unless img_src.nil? # allows for explicitly passing img_src: "" or skipping it entirely
    frontmatter += [
      "---",
      "",
      content
    ]

    File.write(source_dir("_posts", filename), frontmatter.join("\n"))
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
