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

### Usage
1. Place image file for the post in `/_img`
2. Add to the frontmatter of an article
```yaml
img_src: filename.jpg
```
3. The generator will add `image` and `image-large` properties to the post, after resizing the images and placing them in the `_site/assets` directory.
4. Include your images in your template (e.g.)
```html
<img src="{{ page.image_large }}"/>
```

### Known Issues
- If the image you specified doesn't exist, it will crash. If the image you specified isn't an image, it will crash. If you try to break it, it will crash.

### TODO
- Parse target image types from configuration instead of hard-coding
- Configurable filtering (brightness adjustment, etc.)
- Error Handling
