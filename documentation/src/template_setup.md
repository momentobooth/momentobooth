# Templates

MomentoBooth works with a simple templating system to thematize your photos.

A collage output is constructed of 3 layers:

* Background template image
* Collage photos
* Foreground template image

Together with the shape and resolution modifying settings in [templating settings](settings_templating.md) the template-images define the look of your collage photos. It is recommended to get the template settings right before designing your template images. This avoids extra work to incorporate a different resolution, padding, or aspect ratio.

> [!TIP]
> See the [guide for desiging templates](template_design_guide.md) for a step-by-step tutorial on how to design your templates.

## Template-file selection
The application will search for template files in the configured template directory. Different templates can be supplied for different collage layouts (1 photo, 2 photos, 3 photos, 4 photos, 0 no photos selected yet).

The template search & selection for a 3 photo collage, for example, works as follows:

1. Is there a `back-template-3.png`?
2. Is there a `back-template-3.jpg`?
3. Is there a `back-template.png`?
4. Is there a `back-template.jpg`?
5. No background.

The same is repeated for the foreground with `front-template`.

A general background and foreground can thus be specified which are overriden by collage-specific back- and foregrounds.
