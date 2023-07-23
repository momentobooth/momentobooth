# Templates

MomentoBooth works with a simple templating system to thematize your photos.

A collage output is constructed of 3 layers:

* Background template image
* Collage photos
* Foreground template image

The application will search for template files in the configured template directory. Different templates can be supplied for different collage layouts (1 photo, 2 photos, 3 photos, 4 photos, 0 no photos selected yet).

The template search & selection for a 3 photo collage, for example, works as follows:

1. Is there a `background-3.png`?
2. Is there a `background-3.jpg`?
3. Is there a `background.png`?
4. Is there a `background.jpg`?
5. No background.

The same is repeated for `foreground`.

A general background and foreground can thus be specified which are overriden by collage-specific back- and foregrounds.
