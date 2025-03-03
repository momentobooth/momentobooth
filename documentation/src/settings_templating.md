# Templating settings
In the templating settings, you will find the settings related to the generation of collage images such as template images, shape and padding, resolution. This settings tab conveniently also features a template preview section.

## Creative settings
{{#include ./settings/collage_aspect_ratio.md}}
{{#include ./settings/collage_padding.md}}
{{#include ./settings/image_resolution_multiplier.md}}
> The above setting is repeated from [output settings](settings_output.md).

## Template preview
The template preview section allows you to quickly check if your designed template images give the desired results. A placeholder image is inserted for every field that will contain user captures during operation.

Using the buttons you can select which collage type you want to see (no selection, 1, 2, 3, 4 photos) and export the result for further inspection. The background and foreground layers of the collage can be toggled on and off to see the individual effect of those layers, or for generating a clean and transparent reference to design around (see note below).

> Please note that exporting generates the file type specified in the [output settings](settings_output.md). Select `png` for file type if you want lossless images or transparency.

The red border shown in the preview is the printing padding added "collage padding" setting. If set correctly this will not be visible/cut-off on the print. The white border is the standard gap present for the collage grid. The section also shows the template files that are selected for the selected collage after searching the template directory.

> To refresh the templates, switch to another settings tab and back.
