# jekyll-rmagick

A tiny Jekyll plugin to process images using [RMagick](https://rmagick.github.io/)'s ImageMagick bindings.

I made this for my personal blog since I grew tired of manually processing images for the sizes I need.

### Installation
Install [ImageMagick](https://www.imagemagick.org) for your platform.
```
gem install rmagick
cp jekyll-rmagick.rb YOUR_JEKYLL_DIR/_plugins
mkdir YOUR_JEKYLL_DIR/_img
```

### Configuration
Add a `jekyll-rmgaick` section to `_config.yml`.
```yaml
jekyll-rmagick:
    source_dir: _img
    prefix: image
    spec:
        -
            meta: sm
            width: 640
            height: 320
        -
            meta: md
            width: 1280
            height: 800
```
Each generated image will be made available in the post data under the key `[prefix]-[meta]` according to configuration.

#### Extra Options
| option | value | desc |
|--------|-------|------|
| brightness-mod|0.0-1.0| decrease brightness of images (useful for overlaying text)|

### Usage
1. Place image file for the post in `source-dir`
2. Add to the frontmatter of an article
```yaml
img_src: filename.jpg
```
3. The generator will create an image for each defined **spec** and place them in `_site/assets` directory.
4. Include your images in your template (e.g.)
```html
<img src="{{ page.image-md }}"/>
```

### Known Issues
- If the image you specified doesn't exist, it will crash. If the image you specified isn't an image, it will crash. If you try to break it, it will crash.

### TODO
- Parse target image types from configuration instead of hard-coding
- Error Handling
