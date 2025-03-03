# Guide for designing templates

This guide will help you create and test templates for your event that features a MomentoBooth photobooth.

First, get the application to run [as described in the getting started guide](getting_started.html#running-the-application). If you haven't done so, read the [general concept](concept.md) behind the capture modes and collages.

> You don't need a webcam or webcam for developing templates, but it is fun to test your creations. If you don't have one, you can select one of the debug options for the live view method.

## Setting up your print layout
If the photobooth setup at your event will feature a printer, you must set up the correct printing layout to ensure your design will fit the paper. If not, skip to [design your templates](#design-your-templates)

### Use existing settings
If you are using an existing setup with known settings, you can import the settings preset file.

1. Open the settings with the menubar or `Ctrl+S` and go to the templating tab.
1. Go to the **import** tab.
1. Import the settings preset you need to use and hit _accept_.

If pre-exported template guide images are available, you can use those. If not, follow the guide below.

### Create new settings
1. Open the settings with the menubar or `Ctrl+S` and go to the templating tab.
1. Set the right [aspect ratio](/settings_templating.html#collage-aspect-ratio) and [padding](/settings_templating.html#collage-padding) according to the printer that you will use (see e.g. [recommended settings for printers](printer_setup.html)). When not using a printer, you can leave these as-is. Set the [output resolution multiplier](/settings_output.html#output-resolution-multiplier) to a sufficient value, e.g. `4`.
1. Go to the output tab and set the output format to `png`.
1. Get template guide image files
   1. Go back to the templating tab, scroll down to the template preview, and turn off the back- and foreground. You can choose if you want to include the middle ground with placeholder images.
   1. Hit `export`.
   1. You will find your guide images in the collage export folder you set-up in the getting started guide.
1. Optionally, go to the output tab again and set the output format back to `jpg`.

## Design your templates
Using the guide images, you can design your templates using your favourite image editor.

The guide images have the following structure:
- The **red border** in the guide image is the *padding for printing*, this part will be cut-off, so don't put important elements here. Note that it will still show up in the digital images.
- The **white border** shows the *gap size* to clearly distinguish the border regions. This part *is* printed.

To use your templates:
1. Place your files in the templates subdirectory of your project folder. See the [templates page](/template_setup.html) on how to name your files.
1. You can check the result using the template preview in the templates tab, by shooting a collage, or using the manual collage screen (see menubar, or use `Ctrl+M`). If you made changes to your templates, go to a different settings tab and back to the templates tab to reload the images.
