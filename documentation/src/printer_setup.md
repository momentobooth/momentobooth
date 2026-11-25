# Printer

Printing your photos and having a physical reminder of an awesome event is one of the most fun parts of having a photo booth. Therefore MomentoBooth has well-configurable printer support! Which printer prints which print size, on what media and in which layout is set up on the [Print routing](settings_print_routing.md) settings page. This page walks you through setting it up, with some common set-ups as examples. For collage dimensions, also see the [template settings](settings_templating.md).

Getting the print settings right requires quite a bit of trial and error. Ideally a print shows the full collage without parts being cut-off or white borders. For this purpose you probably want to use borderless printing.

## Print systems

MomentoBooth supports two ways of printing, and you can combine them in one set-up:

- **Native** printing uses the [printing package](https://pub.dev/packages/printing) to print to the printers installed on your computer, like any other application does. This is the easiest way to get started.
- **CUPS** printing sends the prints to a queue on a CUPS server, which can run on the same computer or elsewhere on the network. The server is configured in the [hardware settings](settings_hardware.md#cups-server). With CUPS, MomentoBooth can list the media sizes each queue supports, so you do not have to enter the paper size yourself. On Windows, native printers list the papers of their driver too.

## Basic set-up

1. Install the printer on your computer (native), or add it as a queue to your CUPS server (CUPS), and print a test page from there to be sure it works.
1. Open the settings with the menubar or `Ctrl+S` and go to the **Print routing** page. A new installation already has the _Normal_ output of the source connected to a single printer node. If the printer was connected after opening the page, click **Refresh printers** in the side panel.
1. Configure the printer node:
   1. Give it a **Label**, e.g. the name of the printer and the paper, so you can recognise it in the routes overview.
   1. Choose the **Backend**: _Native_ or _CUPS_.
   1. Select the **Printer** (native) or **Queue** (CUPS).
   1. For a CUPS printer, select the **Media**; the size follows from it. For a native printer on Windows, select the **Paper** in the same way. For a native printer on macOS or Linux, enter the **Size** of the paper in mm.
   1. Turn on **Borderless** when the printer prints up to the edge of the paper, e.g. a photo printer with borderless paper. Leave it off for a printer that leaves a white border.
1. Check the **Routes** in the side panel: _Normal_ should list your printer, and the **Problems** list should be empty.
1. Make sure the project setting [Enable printing](settings_project.md#enable-printing) is on.
1. Measure the margins: click the ruler button in the margins row of the printer node to print a calibration page. On every side, the first ruler mark you can see on the print is the margin of that side. Enter these values as the **Margins** of the printer node, and print another calibration page to check them: on every side, the inner dashed line beside the pink line should be visible and the outer one not. See [calibration page](settings_print_routing.md#calibration-page).
1. Take a photo and print it, and check that the collage comes out in full. On borderless media, its [collage padding](settings_templating.md#collage-padding) is cut off by the printer; otherwise the padding is printed around the collage, to cut off by hand. The last printed sheet is also saved as `latest-print.pdf` in the `Prints` folder of the project.

Print sizes that are not routed to a printer are not offered in the print dialog. So with the basic set-up, users can only choose the normal print size.

## Example set-ups

The examples below show only the relevant part of the routing. Arrows are connections; each printer node is a printer configuration with its own printer or queue and media size.

### One printer for normal prints

The basic set-up: every normal print goes to one printer, so the Normal output of the source connects straight to the printer node.

```mermaid
graph LR
    S["Source"] -- Normal --> P["Printer: Selphy 100×148"]
```

### Two printers sharing the work

When one printer cannot keep up, put a round-robin node between the source and the printers. Copies are distributed over the printers in turn: when a user prints four copies, each printer prints two of them.

```mermaid
graph LR
    S["Source"] -- Normal --> R["Round-robin"]
    R --> P1["Printer: Selphy 1"]
    R --> P2["Printer: Selphy 2"]
    M["Margins"] -.-> P1
    M -.-> P2
```

When both printers are of the same type, connect a margins node to the margins input of both printers, so you only have to measure the margins once. If one of the printers is not configured yet, it is skipped and the other one prints everything.

### Small prints, tiled 2×2

Small and tiny prints put several copies of a photo on one sheet, e.g. to hand out to a group. Route the _Small_ output through a tile layout node with 2 columns and 2 rows to a printer, and every sheet holds four copies of the photo. The print dialog shows how many copies a user gets at a time.

```mermaid
graph LR
    S["Source"] -- Normal --> P1["Printer: 4×6"]
    S -- Small --> T["Tile layout: 2 columns, 2 rows"]
    T -- Sheet --> P2["Printer: 4×6 (small)"]
```

A printer node accepts photos as well as tiled sheets, so the tile layout could also be connected to the first printer node. A separate printer node, using the same printer or queue, is needed when the tiled prints use different media or margins. The photos are turned to fill the tiles best automatically, so the grid decides how they lie: with 1 column and 2 rows on portrait media, landscape photos lie horizontally, one above the other. See [tile layout](settings_print_routing.md#tile-layout) for more examples.

### A normal print plus a tiled copy

A duplicate node sends every copy to all its outputs. This way a user gets a normal print and a sheet with small copies to share, from one press of the print button.

```mermaid
graph LR
    S["Source"] -- Normal --> D["Duplicate"]
    D --> P1["Printer: 4×6"]
    D --> T["Tile layout: 1 column, 2 rows"]
    T -- Sheet --> P2["Printer: 2×6"]
```

For a landscape collage, the user gets a 4×6" print with the collage turned to fill it, and a 2×6" strip with two smaller copies, also turned:

```mermaid
block-beta
    columns 4
    block:normal:2
        columns 1
        n1["<br><br>4×6:<br>collage<br><br><br>"]
    end
    space
    block:strip
        columns 1
        t1["<br>2×3<br><br>"]
        t2["<br>2×3<br><br>"]
    end
```

### Split prints for three-photo collages

This "print size" can only be used with photo printers that have a cutting mechanism.

A collage of three photos holds the photos twice, side by side, so it can be printed as two strips. When the _Split_ output is routed, a three-photo collage printed at normal size follows the _Split_ route: the left and right halves are printed as two separate pages, e.g. on 2×6" media. When _Split_ is not routed, the collage follows the _Normal_ route and is printed as a whole, to be cut apart afterwards.

```mermaid
graph LR
    S["Source"] -- Normal --> P1["Printer: Kodak 4×6"]
    S -- Split --> P2["Printer: Kodak 2×6"]
```

Each half of the collage is printed on a page of its own:

```mermaid
block-beta
    columns 3
    block:collage
        columns 2
        cl["<br><br>Left<br>half<br><br><br>"] cr["<br><br>Right<br>half<br><br><br>"]
    end
    space
    block:pages
        columns 2
        page1["<br><br>Page 1<br><br><br>"] page2["<br><br>Page 2<br><br><br>"]
    end
    collage --> pages
```

Split prints are always printed in halves, so tile layouts on their route are not used.

### Saving paper on a regular printer

Not everyone has a photo printer, and apart from a compact one like the Canon Selphy, buying one for a single event is usually not worth it. A regular inkjet or laser printer will do as well, but prints on A4 or Letter paper, of which a single print leaves most unused. Route the _Normal_ output through a stack node to that printer, and the copies of a print are put together on as few sheets as possible, to be cut apart afterwards.

```mermaid
graph LR
    S["Source"] -- Normal --> K["Stack: 2 columns"]
    K -- Stack --> P["Printer: A4"]
```

With 2 columns, three copies of a landscape collage fit at the top of an A4 sheet. The rest of the sheet can be fed into the printer again for the next print, if the printer accepts shorter paper. See [stack](settings_print_routing.md#stack) for how the copies are placed.

When guests mostly print a single copy, we suggest setting _Print_ on the stack to _When full_. The stack then collects the copies of several guests and only prints a sheet once it is full. You may also set an _Idle (min)_ time to limit the maximum waiting time, an incompletely filled sheet will still print after this period. See [collecting copies](settings_print_routing.md#collecting-copies).

## Recommended settings for Canon Selphy CP1300/CP1500

The Canon Selphy series of cheap and compact photo printers. The Selphy printers are quite convenient for photo booth purposes, as long as the volume of prints is not too big, since they have a limited and ink roll paper storage volume.

Here are settings that are known to be approximately right for using this type of printer, with a native printer node.

| Property | Value |
|---|---|
| [Collage aspect ratio](settings_templating.md#collage-aspect-ratio) | 1.48 |
| [Collage padding](settings_templating.md#collage-padding) | 10 |
| Printer node: Backend | Native |
| Printer node: Size (mm) | W 100 × H 148 |
| Printer node: Borderless | On |
| Printer node: Margins | Measured with a [calibration page](settings_print_routing.md#calibration-page) |
| [Use printer settings for native printers](settings_hardware.md#use-printer-settings-for-native-printers) | On |

Make sure to set the default settings of the printer to **portrait mode**, **borderless**, and the right paper-size.

## Recommended settings for Kodak 6850

Another photo printer that has been used is the Kodak 6850. This printer can handle a lot larger volume with its higher paper/ink capacity and speed.

The Kodak has been tested with CUPS printer nodes, where the following settings work well.

| Property | Value |
|---|---|
| [Collage aspect ratio](settings_templating.md#collage-aspect-ratio) | 1.49 |
| [Collage padding](settings_templating.md#collage-padding) | 10 |
| Printer node: Backend | CUPS |
| Printer node: Media | 4×6 |
| Printer node: Borderless | On |
| Printer node: Margins | Measured with a [calibration page](settings_print_routing.md#calibration-page) |

For the other print sizes, add a printer node per media size, all with the Kodak's queue:

- **Small:** a tile layout with 1 column and 2 rows, to a printer node with 4×6 media.
- **Tiny:** a tile layout with 1 column and 2 rows, to a printer node with 2×6 media.
- **Split:** directly to a printer node with 2×6 media.
