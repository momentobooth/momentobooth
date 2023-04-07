import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class PhotoCollage extends StatefulWidget {

  final double aspectRatio;

  const PhotoCollage({
    super.key,
    required this.aspectRatio,
  });

  @override
  State<PhotoCollage> createState() => PhotoCollageState();

}

class PhotoCollageState extends State<PhotoCollage> {

  final GlobalKey _globalKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _globalKey,
      child: Align(
        child: AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: LayoutGrid(
            areas: '''
                header1 header2
                content1 content2
                content3 content4
                content5 content6
              ''',
            rowSizes: [auto, auto, auto, auto],
            columnSizes: [1.fr, 1.fr],
            columnGap: 12,
            rowGap: 12,
            children: [
              Center(child: Text("Powered by Casper die echt teringsnel Flutter geleerd heeft")).inGridArea('header1'),
              Center(child: SvgPicture.asset("assets/svg/logo.svg", color: Colors.white)).inGridArea('header2'),
              Center(child: Image.asset("assets/bitmap/sample-background.jpg")).inGridArea('content1'),
              Center(child: Image.asset("assets/bitmap/sample-background.jpg")).inGridArea('content2'),
              Center(child: Image.asset("assets/bitmap/sample-background.jpg")).inGridArea('content3'),
              Center(child: Image.asset("assets/bitmap/sample-background.jpg")).inGridArea('content4'),
              Center(child: Image.asset("assets/bitmap/sample-background.jpg")).inGridArea('content5'),
              Center(child: Image.asset("assets/bitmap/sample-background.jpg")).inGridArea('content6'),
            ],
          ),
        ),
      ),
    );
  }

  Object? export() async {
    try {
      print('export: start');
      RenderRepaintBoundary? boundary = _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        //print('export: boundary == null');
        throw 'Could not retrieve RenderRepaintBoundary';
      }

      ui.Image image = await boundary.toImage(pixelRatio: 4.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        //print('export: byteData == null');
        throw 'Could not get ByteData from Image';
      }

      var dir1 = await getApplicationDocumentsDirectory();
      var dir2 = join(dir1.path, 'export.png');
      print(dir2);
      File(dir2).writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

      //print("Data has ${byteData.lengthInBytes} length!");
    } catch (e) {
      //print(e);
    }
  }

}
