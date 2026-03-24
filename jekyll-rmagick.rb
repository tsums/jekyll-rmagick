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

        # Workaround - We need Jekyll to not mess with our files.
        # we write them directly during the Generator phase, and when it tries to
        # write them itself, they noop.
        class ImageFile < Jekyll::StaticFile
            def write(dest)
                # do nothing
            end
        end

        class Generator < Jekyll::Generator

            PATH_FORMAT = "%{filename}-%{size}.%{extension}"

            def symbolize_keys(hash)
                hash.transform_keys(&:to_sym)
            end

            def format_output_path(dest, image_path, size)
                params = symbolize_keys(image_hash(image_path, size))
                Pathname.new(dest % params).to_s
            end

            def image_hash(image_path, size)
                {
                  'path'      => image_path,
                  'basename'  => File.basename(image_path),
                  'filename'  => File.basename(image_path, '.*'),
                  'extension' => File.extname(image_path).delete('.'),
                  'size'      => size,
                }
            end

            def generate(site)

                jekyll_rmagick_config = site.config['jekyll-rmagick']
                return unless jekyll_rmagick_config

                source_dir = jekyll_rmagick_config['source_dir']
                return unless source_dir

                prefix = jekyll_rmagick_config['prefix'] || 'image'
                sizes = jekyll_rmagick_config['spec']
                return unless sizes && sizes.is_a?(Array)

                dest = File.join(site.config['destination'], 'assets')
                src = File.join(site.config['source'], source_dir)
                FileUtils.mkdir_p dest

                site.posts.each do |post|
                    if post.data['img_src']

                        source_file = File.join(src, post.data['img_src'])
                        unless File.exist?(source_file)
                            site.logger.warn "jekyll-rmagick: Source file #{source_file} does not exist"
                            next
                        end

                        begin
                            original = ImageList.new(source_file)
                            original.strip!

                            sizes.each do |spec|
                                next unless spec['meta'] && spec['width'] && spec['height']

                                filename = format_output_path(PATH_FORMAT, source_file, spec['meta'])
                                output_file = File.join(dest, filename)
                                rel_path = File.join('/assets', filename)
                                image = original.copy
                                image.resize!(spec['width'], spec['height'])

                                if jekyll_rmagick_config['brightness-mod'] && jekyll_rmagick_config['brightness-mod'].is_a?(Numeric) && (0.0..1.0).include?(jekyll_rmagick_config['brightness-mod'])
                                    image.modulate!(jekyll_rmagick_config['brightness-mod'])
                                end

                                quality = jekyll_rmagick_config['quality'] || 75
                                image.write(output_file) { self.quality = quality }
                                image.destroy!
                                site.static_files << ImageFile.new(site, site.source, '/assets', filename)
                                post.data[prefix + "-" + spec['meta']] = rel_path

                            end

                        rescue => e
                            site.logger.error "jekyll-rmagick: Failed to process image #{source_file}: #{e.message}"
                            next
                        end

                    end
                end
            end

        end

    end
end
