# The MIT License
#
# (c) 2016 Trevor Summerfield
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.


# jekyll-rmagick takes frontmatter-defined image sources and processes the images,
# adding variables for the processed files to be used in templates.

require 'rmagick'
require 'fileutils'
require 'pathname'

include Magick

module Jekyll

    module ImageGen

        # Workaround to prevent Jekyll from writing processed images itself
        class ImageFile < Jekyll::StaticFile
            def write(dest)
                # Do nothing - images are already written during generation
            end
        end

        # Jekyll plugin for processing images using RMagick.
        # Generates resized versions of images specified in post frontmatter.
        class Generator < Jekyll::Generator

            PATH_FORMAT = "%{post_slug}-%{prefix}-%{size}.png"

            def symbolize_keys(hash)
                # Converts string keys to symbols for template interpolation
                hash.transform_keys(&:to_sym)
            end

            def format_output_path(dest, post_slug, prefix, image_path, size)
                # Formats the output filename using the path format template
                params = symbolize_keys(image_hash(post_slug, prefix, image_path, size))
                Pathname.new(dest % params).to_s
            end

            def image_hash(post_slug, prefix, image_path, size)
                # Extracts path components for filename generation
                {
                  'post_slug' => post_slug,
                  'prefix'    => prefix,
                  'path'      => image_path,
                  'basename'  => File.basename(image_path),
                  'filename'  => File.basename(image_path, '.*'),
                  'size'      => size,
                }
            end

            def generate(site)
                # Validate jekyll-rmagick configuration
                jekyll_rmagick_config = site.config['jekyll-rmagick']
                return unless jekyll_rmagick_config

                source_dir = jekyll_rmagick_config['source_dir']
                return unless source_dir

                prefix = jekyll_rmagick_config['prefix'] || 'image'
                sizes = jekyll_rmagick_config['spec']
                return unless sizes && sizes.is_a?(Array)

                # Set up source and destination directories
                dest = File.join(site.config['destination'], 'assets')
                src = File.join(site.config['source'], source_dir)
                FileUtils.mkdir_p dest

                # Process each post
                site.posts.docs.each do |post|
                    if post.data['img_src']
                        # Build source file path
                        source_file = File.join(src, post.data['img_src'])
                        unless File.exist?(source_file)
                            Jekyll.logger.warn "jekyll-rmagick: Source file #{source_file} does not exist"
                            next
                        end

                        begin
                            # Load and prepare original image
                            original = ImageList.new(source_file)
                            original.strip!

                            # Generate each size variant
                            sizes.each do |spec|
                                next unless spec['meta'] && spec['width'] && spec['height']

                                # Build output paths
                                post_slug = post.data['slug'] || post.basename.sub(/\A\d{4}-\d{2}-\d{2}-/, '')
                                filename = format_output_path(PATH_FORMAT, post_slug, prefix, source_file, spec['meta'])
                                output_file = File.join(dest, filename)
                                rel_path = File.join('/assets', filename)

                                # Create resized copy
                                image = original.copy
                                image.resize!(spec['width'], spec['height'])

                                # Apply brightness modulation if configured and valid
                                if jekyll_rmagick_config['brightness-mod'] && jekyll_rmagick_config['brightness-mod'].is_a?(Numeric) && (0.0..1.0).include?(jekyll_rmagick_config['brightness-mod'])
                                    image[0] = image[0].modulate(jekyll_rmagick_config['brightness-mod'], 1.0, 1.0) if image.length > 0
                                end

                                # Write image with specified quality
                                quality = jekyll_rmagick_config['quality'] || 100
                                image.write(output_file) { self.quality = quality }

                                # Clean up image resources
                                image.destroy!

                                # Register with Jekyll's static files
                                site.static_files << ImageFile.new(site, site.source, '/assets', filename)

                                # Store relative path in post data
                                post.data[prefix + "-" + spec['meta']] = rel_path
                            end

                        rescue => e
                            Jekyll.logger.error "jekyll-rmagick: Failed to process image #{source_file}: #{e.message}"
                            next
                        end
                    end
                end
            end

        end

    end
end
