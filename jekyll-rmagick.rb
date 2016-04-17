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

            $pathformat = "%{filename}-%{size}.%{extension}"

            def symbolize_keys(hash)
                result = {}
                hash.each_key do |key|
                    result[key.to_sym] = hash[key]
                end
                result
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

                dest = site.config['destination'] + "/assets/"
                src = site.config['source'] + "/" + site.config['jekyll-rmagick']['source_dir'] + "/"

                prefix = site.config['jekyll-rmagick']['prefix']
                sizes = site.config['jekyll-rmagick']['spec']
                FileUtils::mkdir_p dest # directory needs to exist or IM won't put images there.

                site.posts.each do |post|
                    if post.data['img_src']

                        source_file = src + post.data['img_src']
                        image = ImageList.new(source_file)
                        image.strip!

                        sizes.each do |spec|

                            filename = format_output_path($pathformat, source_file, spec['meta'])
                            output_file = dest + filename
                            rel_path = '/assets/' + filename
                            image = image.resize(spec['width'],spec['height'])

                            if site.config['jekyll-rmagick']['brightness_mod']
                                image = image.modulate(site.config['jekyll-rmagick']['brightness_mod'])
                            end

                            image.write(output_file) { self.quality = 75 }
                            site.static_files << ImageFile.new(site, site.source, '/assets', filename)
                            post.data[prefix + "-" + spec['meta']] = '/assets/' + filename

                        end

                    end
                end
            end

        end

    end
end
