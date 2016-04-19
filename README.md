# jekyll-rmagick

A tiny Jekyll plugin to process images using [RMagick](https://rmagick.github.io/)'s ImageMagick bindings.

I made this for my personal blog after I grew tired of manually processing images for the sizes I need. I use this to associate a header image with each post, which is then displayed in different sizes on the index and post pages. This way the source repository need only contain one large master image, and it automates the creation of posts.

This is not a tool for complex image processing or inclusion within the body of a post.

### Installation
Install [ImageMagick](https://www.imagemagick.org) for your platform.
```
gem install rmagick
cp jekyll-rmagick.rb YOUR_JEKYLL_DIR/_plugins
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
Place these under the `jekyll-rmagick` header in config.

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
- Error Handling
