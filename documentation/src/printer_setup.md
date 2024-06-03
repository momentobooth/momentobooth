# Printer

Printing your photos and having a physical reminder of an awesome event is one of the most fun parts of having a photo booth. Therefore MomentoBooth has well-configurable printer support! For an overview of the available settings to tune printing, see the [printer hardware settings](settings_hardware.md#printing) and [template settings](settings_templating.md).

Getting the print settings right requires quite a bit of trial and error. Ideally a print shows the full collage without parts being cut-off or white borders. For this purpose you probably want to use borderless printing.

## Print system
MomentoBooth supports two methods of printing. "Native" printing using the [printing package](https://pub.dev/packages/printing), and printing to a CUPS server. The choice between these systems will depend on your set-up.

## Recommended settings for Canon Selphy CP1300/CP1500

The Canon Selphy series of cheap and compact photo printers. The Selphy printers are quite convenient for photo booth purposes, as long as the volume of prints is not too big, since they have a limited and ink roll paper storage volume.

Here are settings that are known to be approximately right for using this type of printer (using native printing method).

| Property | Value |
|---|---|
| [Collage aspect ratio](settings_templating.md#collage-aspect-ratio) | 1.48 |
| [Collage padding](settings_templating.md#collage-padding) | 10 |
| [Page height](settings_hardware.md#page-height) | 148 |
| [Page width](settings_hardware.md#page-width) | 100 |
| [Printer margin top](settings_hardware.md#page-margins-used-for-printing) | 0.0 |
| [Printer margin right](settings_hardware.md#page-margins-used-for-printing) | 1.6 |
| [Printer margin bottom](settings_hardware.md#page-margins-used-for-printing) | 0.5 |
| [Printer margin left](settings_hardware.md#page-margins-used-for-printing) | 1.6 |
| [Use printer settings](settings_hardware.md#use-printer-settings-for-printing) | On |

Make sure to set the default settings of the printer to **portrait mode**, **borderless**, and the right paper-size.

## Recommended settings for Kodak 6850

Another photo printer that has been used is the Kodak 6850. This printer can handle a lot larger volume with its higher paper/ink capacity and speed.

The Kodak has been tested with the CUPS printing method, where the following settings work well with 4x6 paper size selected.

| Property | Value |
|---|---|
| [Collage aspect ratio](settings_templating.md#collage-aspect-ratio) | 1.49 |
| [Collage padding](settings_templating.md#collage-padding) | 10 |
| [Printer margin top](settings_hardware.md#page-margins-used-for-printing) | 0.0 |
| [Printer margin right](settings_hardware.md#page-margins-used-for-printing) | 0.0 |
| [Printer margin bottom](settings_hardware.md#page-margins-used-for-printing) | 1.5 |
| [Printer margin left](settings_hardware.md#page-margins-used-for-printing) | 0.0 |

For small prints use, 1 column, 2 rows, and rotated images with 4x6 paper size.\
For tiny prints, use 1 column, 2 rows, and rotated images with 2x6 paper size.\
For split prints, use 2x6 paper size.
