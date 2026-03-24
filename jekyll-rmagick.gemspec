# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "jekyll-rmagick"
  spec.version       = "0.1.2"
  spec.authors       = ["Trevor Summerfield"]
  spec.email         = ["trevor@trevorsummerfield.com"] # Placeholder as it's not in the files

  spec.summary       = "Jekyll plugin for processing images using RMagick."
  spec.description   = "Processes images using RMagick based on frontmatter specs in Jekyll posts."
  spec.homepage      = "https://github.com/tsums/jekyll-rmagick"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 3.0.0")

  spec.metadata["allowed_push_host"] = "https://rubygems.pkg.github.com/tsums"
  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["github_repo"]      = "ssh://github.com/tsums/jekyll-rmagick"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "jekyll", "~> 4.0"
  spec.add_dependency "rmagick", "~> 4.0"
  spec.add_dependency "observer"
end
