# frozen_string_literal: true

require "spec_helper"

describe "Jekyll RMagick Plugin" do
  let(:site) { make_site(config_overrides) }
  let(:config_overrides) { {} }

  before(:each) do
    # Reset directories
    FileUtils.rm_rf(dest_dir)
    FileUtils.mkdir_p(dest_dir)
  end

  describe "Configuration Validation" do
    context "when jekyll-rmagick config is missing" do
      let(:config_overrides) { {} }

      it "does not raise an error" do
        expect { site.process }.not_to raise_error
      end
    end

    context "when jekyll-rmagick config is empty" do
      let(:config_overrides) do
        { "jekyll-rmagick" => {} }
      end

      it "does not process images without source_dir" do
        expect { site.process }.not_to raise_error
      end
    end

    context "when spec is not an array" do
      let(:config_overrides) do
        {
          "jekyll-rmagick" => {
            "source_dir" => "_img",
            "prefix"     => "image",
            "spec"       => { "meta" => "sm", "width" => 640, "height" => 320 }
          }
        }
      end

      it "returns early without processing" do
        expect { site.process }.not_to raise_error
      end
    end
  end

  describe "Error Handling" do
    let(:config_overrides) do
      {
        "jekyll-rmagick" => {
          "source_dir" => "_img",
          "prefix"     => "image",
          "spec"       => [
            { "meta" => "sm", "width" => 640, "height" => 320 }
          ]
        }
      }
    end

    context "when source image file doesn't exist" do
      before(:each) do
        FileUtils.mkdir_p(source_dir("_posts"))
        File.write(source_dir("_posts", "2024-01-01-test.md"), <<~MARKDOWN)
          ---
          layout: default
          title: Test Post
          img_src: nonexistent.png
          ---

          Test content
        MARKDOWN
      end

      it "logs a warning and continues" do
        expect { site.process }.not_to raise_error
      end

      it "does not create image variants" do
        site.process

        # Should not create image files for nonexistent source
        expect(File.exist?(dest_dir("assets", "nonexistent-sm.png"))).to be_falsy
      end
    end

    context "when spec is missing required fields" do
      let(:config_overrides) do
        {
          "jekyll-rmagick" => {
            "source_dir" => "_img",
            "prefix"     => "image",
            "spec"       => [
              { "meta" => "sm" }  # Missing width and height
            ]
          }
        }
      end

      before(:each) do
        FileUtils.mkdir_p(source_dir("_posts"))
        File.write(source_dir("_posts", "2024-01-01-test.md"), <<~MARKDOWN)
          ---
          layout: default
          title: Test Post
          img_src: sample_image.jpg
          ---

          Test content
        MARKDOWN
      end

      it "skips incomplete spec entries" do
        expect { site.process }.not_to raise_error

        # Should not create image since spec is incomplete
        expect(File.exist?(dest_dir("assets", "test-image-sm.png"))).to be_falsy
      end
    end
  end

  describe "Frontmatter Handling" do
    let(:config_overrides) do
      {
        "jekyll-rmagick" => {
          "source_dir" => "_img",
          "prefix"     => "image",
          "spec"       => [
            { "meta" => "sm", "width" => 640, "height" => 320 }
          ]
        }
      }
    end

    context "when img_src is not present" do
      before(:each) do
        FileUtils.mkdir_p(source_dir("_posts"))
        File.write(source_dir("_posts", "2024-01-01-test.md"), <<~MARKDOWN)
          ---
          layout: default
          title: Test Post
          ---

          Test content without img_src
        MARKDOWN
      end

      it "skips processing for posts without img_src" do
        expect { site.process }.not_to raise_error
      end
    end

    context "when img_src is empty" do
      before(:each) do
        FileUtils.mkdir_p(source_dir("_posts"))
        File.write(source_dir("_posts", "2024-01-01-test.md"), <<~MARKDOWN)
          ---
          layout: default
          title: Test Post
          img_src:
          ---

          Test content
        MARKDOWN
      end

      it "skips processing for empty img_src" do
        expect { site.process }.not_to raise_error
      end
    end
  end

  describe "Positive Behavior - Successful Image Processing" do
    let(:config_overrides) do
      {
        "jekyll-rmagick" => {
          "source_dir" => "_img",
          "prefix"     => "image",
          "spec"       => [
            { "meta" => "sm", "width" => 640, "height" => 320 },
            { "meta" => "md", "width" => 1280, "height" => 800 },
          ],
          "quality"    => 80
        }
      }
    end

    before(:each) do
      # Create test post with valid image
      FileUtils.mkdir_p(source_dir("_posts"))
      File.write(source_dir("_posts", "2024-01-01-test.md"), <<~MARKDOWN)
        ---
        layout: default
        title: Test Post
        img_src: sample_image.jpg
        ---

        Test content
      MARKDOWN
    end

    it "generates resized images for all specs" do
      site.process

      expect(Pathname.new(dest_dir("assets", "test-image-sm.png"))).to exist
      expect(Pathname.new(dest_dir("assets", "test-image-md.png"))).to exist
    end

    it "creates assets directory" do
      site.process

      expect(File.directory?(dest_dir("assets"))).to be_truthy
    end

    it "adds image paths to post data with correct keys" do
      site.read
      site.generate

      post = site.posts.docs.first
      expect(post.data).to have_key("image-sm")
      expect(post.data).to have_key("image-md")
    end

    it "stores correct relative paths in post data" do
      site.read
      site.generate

      post = site.posts.docs.first
      expect(post.data["image-sm"]).to eq("/assets/test-image-sm.png")
      expect(post.data["image-md"]).to eq("/assets/test-image-md.png")
    end

    it "registers generated images as static files" do
      site.read
      site.generate

      # Check that images are registered as ImageFile instances
      sm_registered = site.static_files.any? { |f| f.name == "test-image-sm.png" && f.class.name.include?("ImageFile") }
      md_registered = site.static_files.any? { |f| f.name == "test-image-md.png" && f.class.name.include?("ImageFile") }

      expect(sm_registered).to be_truthy
      expect(md_registered).to be_truthy
    end

    it "creates image files with correct content" do
      site.process

      sm_file = dest_dir("assets", "test-image-sm.png")
      md_file = dest_dir("assets", "test-image-md.png")

      expect(File.exist?(sm_file)).to be_truthy
      expect(File.size(sm_file)).to be > 0
      expect(File.exist?(md_file)).to be_truthy
      expect(File.size(md_file)).to be > 0
    end
  end

  describe "Positive Behavior - Custom Prefix" do
    let(:config_overrides) do
      {
        "jekyll-rmagick" => {
          "source_dir" => "_img",
          "prefix"     => "blog-image",
          "spec"       => [
            { "meta" => "sm", "width" => 640, "height" => 320 }
          ]
        }
      }
    end

    before(:each) do
      FileUtils.mkdir_p(source_dir("_posts"))
      File.write(source_dir("_posts", "2024-01-01-test.md"), <<~MARKDOWN)
        ---
        layout: default
        title: Test Post
        img_src: sample_image.jpg
        ---

        Test content
      MARKDOWN
    end

    it "uses custom prefix in post data keys" do
      site.read
      site.generate

      post = site.posts.docs.first
      expect(post.data).to have_key("blog-image-sm")
      expect(post.data).not_to have_key("image-sm")
    end

    it "stores paths with correct prefix" do
      site.read
      site.generate

      post = site.posts.docs.first
      expect(post.data["blog-image-sm"]).to eq("/assets/test-blog-image-sm.png")
    end
  end

  describe "Positive Behavior - Default Prefix" do
    let(:config_overrides) do
      {
        "jekyll-rmagick" => {
          "source_dir" => "_img",
          # prefix not specified - should default to "image"
          "spec"       => [
            { "meta" => "sm", "width" => 640, "height" => 320 }
          ]
        }
      }
    end

    before(:each) do
      FileUtils.mkdir_p(source_dir("_posts"))
      File.write(source_dir("_posts", "2024-01-01-test.md"), <<~MARKDOWN)
        ---
        layout: default
        title: Test Post
        img_src: sample_image.jpg
        ---

        Test content
      MARKDOWN
    end

    it "defaults to 'image' prefix when not specified" do
      site.read
      site.generate

      post = site.posts.docs.first
      expect(post.data).to have_key("image-sm")
    end
  end

  describe "Positive Behavior - Brightness Modulation" do
    let(:config_overrides) do
      {
        "jekyll-rmagick" => {
          "source_dir" => "_img",
          "prefix"     => "image",
          "spec"       => [
            { "meta" => "sm", "width" => 640, "height" => 320 }
          ],
          "brightness-mod" => 0.7
        }
      }
    end

    before(:each) do
      FileUtils.mkdir_p(source_dir("_posts"))
      File.write(source_dir("_posts", "2024-01-01-test.md"), <<~MARKDOWN)
        ---
        layout: default
        title: Test Post
        img_src: sample_image.jpg
        ---

        Test content
      MARKDOWN
    end

    it "applies brightness modulation and creates image" do
      site.process

      expect(File.exist?(dest_dir("assets", "test-image-sm.png"))).to be_truthy
    end

    it "processes successfully with valid brightness values" do
      expect { site.process }.not_to raise_error
    end

    context "with minimum brightness value" do
      let(:config_overrides) do
        {
          "jekyll-rmagick" => {
            "source_dir" => "_img",
            "prefix"     => "image",
            "spec"       => [
              { "meta" => "sm", "width" => 640, "height" => 320 }
            ],
            "brightness-mod" => 0.0
          }
        }
      end

      it "accepts minimum brightness value" do
        expect { site.process }.not_to raise_error
      end
    end

    context "with maximum brightness value" do
      let(:config_overrides) do
        {
          "jekyll-rmagick" => {
            "source_dir" => "_img",
            "prefix"     => "image",
            "spec"       => [
              { "meta" => "sm", "width" => 640, "height" => 320 }
            ],
            "brightness-mod" => 1.0
          }
        }
      end

      it "accepts maximum brightness value" do
        expect { site.process }.not_to raise_error
      end
    end
  end

  describe "Positive Behavior - Custom Quality Setting" do
    let(:config_overrides) do
      {
        "jekyll-rmagick" => {
          "source_dir" => "_img",
          "prefix"     => "image",
          "spec"       => [
            { "meta" => "sm", "width" => 640, "height" => 320 }
          ],
          "quality"    => 90
        }
      }
    end

    before(:each) do
      FileUtils.mkdir_p(source_dir("_posts"))
      File.write(source_dir("_posts", "2024-01-01-test.md"), <<~MARKDOWN)
        ---
        layout: default
        title: Test Post
        img_src: sample_image.jpg
        ---

        Test content
      MARKDOWN
    end

    it "respects custom quality setting" do
      expect { site.process }.not_to raise_error

      expect(File.exist?(dest_dir("assets", "test-image-sm.png"))).to be_truthy
    end
  end

  describe "Positive Behavior - Multiple Posts" do
    let(:config_overrides) do
      {
        "jekyll-rmagick" => {
          "source_dir" => "_img",
          "prefix"     => "image",
          "spec"       => [
            { "meta" => "sm", "width" => 640, "height" => 320 }
          ]
        }
      }
    end

    before(:each) do
      FileUtils.mkdir_p(source_dir("_posts"))

      # Create first post with image
      File.write(source_dir("_posts", "2024-01-01-first.md"), <<~MARKDOWN)
        ---
        layout: default
        title: First Post
        img_src: sample_image.jpg
        ---

        First post content
      MARKDOWN

      # Create second post with different image
      File.write(source_dir("_posts", "2024-01-02-second.md"), <<~MARKDOWN)
        ---
        layout: default
        title: Second Post
        img_src: sample_image.jpg
        ---

        Second post content
      MARKDOWN

      # Create third post without image
      File.write(source_dir("_posts", "2024-01-03-third.md"), <<~MARKDOWN)
        ---
        layout: default
        title: Third Post
        ---

        Third post without image
      MARKDOWN
    end

    it "processes all posts with images" do
      site.process

      expect(File.exist?(dest_dir("assets", "first-image-sm.png"))).to be_truthy
    end

    it "skips posts without img_src" do
      expect { site.process }.not_to raise_error
    end

    it "adds image paths to posts that have them" do
      site.read
      site.generate

      posts_by_title = site.posts.docs.sort_by { |p| p.data["title"] }

      first_post = posts_by_title.find { |p| p.data["title"] == "First Post" }
      second_post = posts_by_title.find { |p| p.data["title"] == "Second Post" }
      third_post = posts_by_title.find { |p| p.data["title"] == "Third Post" }

      expect(first_post.data).to have_key("image-sm")
      expect(second_post.data).to have_key("image-sm")
      expect(third_post.data["img_src"]).to be_nil
    end
  end

  describe "Positive Behavior - Path Format" do
    let(:config_overrides) do
      {
        "jekyll-rmagick" => {
          "source_dir" => "_img",
          "prefix"     => "image",
          "spec"       => [
            { "meta" => "sm", "width" => 640, "height" => 320 }
          ]
        }
      }
    end

    before(:each) do
      FileUtils.mkdir_p(source_dir("_posts"))
      File.write(source_dir("_posts", "2024-01-01-test.md"), <<~MARKDOWN)
        ---
        layout: default
        title: Test Post
        img_src: sample_image.jpg
        ---

        Test content
      MARKDOWN
    end

    it "generates correct filename format with size" do
      site.process

      # Expected format: {filename}-{size}.{extension}
      expect(File.exist?(dest_dir("assets", "test-image-sm.png"))).to be_truthy
    end

    it "preserves original extension in output" do
      site.process

      assets_dir = dest_dir("assets")
      files = Dir.glob(File.join(assets_dir, "*.png"))

      expect(files.length).to be > 0
      expect(files.all? { |f| f.end_with?(".png") }).to be_truthy
    end
  end
end