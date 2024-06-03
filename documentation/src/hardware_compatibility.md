# Hardware compatibility

```admonish warning
Make sure to use good quality USB and HDMI cables and preferably connect any USB devices without extension cords. There have been reports of freezes in camera handling due to bad cables. Try different USB ports and/or hubs if any problems arise. Also make sure to power your devices properly for long time usage.
```

## Tested cameras

MomentoBooth utilizes the great [gPhoto2](http://gphoto.org/) library for communicating with supported digital cameras. Due to this MomentoBooth should support a [broad range of cameras](http://www.gphoto.org/proj/libgphoto2/support.php) from a broad range of vendors.

These are the ones that we have tested ourselves or have received a report about. If you have tested a camera which is not on this list, please report on [GitHub](https://github.com/h3x4d3c1m4l/momento-booth/issues/new) and we will happily update can update this list.

| Brand | Model | Live view | Capture | Remarks |
| - | - | - | - | - |
Nikon | D3400[^NikonDSLRHandling] | ✅ | ✅ | Live view stops after 30 minutes, still needs an automatic workaround (manual workaround: press Ctrl/Cmd+R) |
Sony | Alpha 6400[^NoSpecialHandling] | ✅ | ✅ | Also known as ILCE-6400 |

[^NikonDSLRHandling]: Set [Use Special Handling](settings_hardware.html) to 'Nikon DSLR'

[^NoSpecialHandling]: Set [Use Special Handling](settings_hardware.html) to 'None'

## Tested printers

MomentoBooth uses the [printing](https://pub.dev/packages/printing) library for Flutter to print to any printer(s) installed on your computer and as such should offer the same compatibility as applications like your Office suite and web browser.

If you have any printers to add or any special remarks about your printer, please [let us know](https://github.com/h3x4d3c1m4l/momento-booth/issues/new) using a GitHub issue.

| Brand | Model | Works | Remarks |
| - | - | - | - |
| Canon | SELPHY CP1300 | ✅ | Works using USB (recommended) as well as WiFi; look [here](printer_setup.md) for sample settings |
| Canon | SELPHY CP1500 | ✅ | Works using WiFi, not at all using USB (at least on Windows); look [here](printer_setup.md) for sample settings |
| Kodak | 6850 | ✅ | Only has USB; works both with native and CUPS printing; look [here](printer_setup.md) for sample settings |
