import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_rust_bridge_example/managers/photos_manager.dart';
import 'package:flutter_rust_bridge_example/theme/momento_booth_theme_data.dart';
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

  MomentoBoothThemeData get theme => MomentoBoothThemeData.defaults();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _globalKey,
      child: Align(
        child: AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: Observer(builder: (BuildContext context) { return _layout; },)
        ),
      ),
    );
  }

  Widget get _layout {
    if (PhotosManagerBase.instance.chosen.isEmpty) {
      return _zeroLayout;
    } else if (PhotosManagerBase.instance.chosen.length == 1) {
      return _oneLayout;
    } else if (PhotosManagerBase.instance.chosen.length == 2) {
      return _twoLayout;
    } else if (PhotosManagerBase.instance.chosen.length == 3) {
      return _threeLayout;
    } else if (PhotosManagerBase.instance.chosen.length == 4) {
      return _fourLayout;
    }
    return Container();
  }

  Widget get _zeroLayout {
    return Center(child: AutoSizeText("Select some photos :)", style: theme.titleStyle,),);
  }

  Widget get _oneLayout {
    return LayoutGrid(
      areas: '''
          header
          content
        ''',
      rowSizes: [1.fr, 6.fr],
      columnSizes: [1.fr],
      columnGap: 12,
      rowGap: 12,
      children: [
        Center(child: SvgPicture.asset("assets/svg/logo.svg", color: Colors.white)).inGridArea('header'),
        Center(child: RotatedBox(
          quarterTurns: 1,
          child: Image.memory(PhotosManagerBase.instance.photos[0])),
        ).inGridArea('content'),
      ],
    );
  }

  Widget get _twoLayout {
    return LayoutGrid(
      areas: '''
          header
          content1
          content2
        ''',
      rowSizes: [1.fr, 3.fr, 3.fr],
      columnSizes: [1.fr],
      columnGap: 12,
      rowGap: 12,
      children: [
        Center(child: SvgPicture.asset("assets/svg/logo.svg", color: Colors.white)).inGridArea('header'),
        for (int i = 0; i < PhotosManagerBase.instance.photos.length; i++) ...[
          Center(child: Image.memory(PhotosManagerBase.instance.photos[i])).inGridArea('content${i+1}'),
        ]
      ],
    );
  }

  Widget get _threeLayout {
    return LayoutGrid(
      areas: '''
          header1 header2
          content1 content4
          content2 content5
          content3 content6
        ''',
      rowSizes: [auto, auto, auto, auto],
      columnSizes: [1.fr, 1.fr],
      columnGap: 12,
      rowGap: 12,
      children: [
        Center(child: Text("Powered by Casper die echt teringsnel Flutter geleerd heeft")).inGridArea('header1'),
        Center(child: SvgPicture.asset("assets/svg/logo.svg", color: Colors.white)).inGridArea('header2'),
        for (int i = 0; i < PhotosManagerBase.instance.photos.length; i++) ...[
          Center(child: Image.memory(PhotosManagerBase.instance.photos[i])).inGridArea('content${i+1}'),
          Center(child: Image.memory(PhotosManagerBase.instance.photos[i])).inGridArea('content${i+4}'),
        ]
      ],
    );
  }

  Widget get _fourLayout {
    return LayoutGrid(
      areas: '''
          content1 content2
          header   header
          content3 content4
        ''',
      rowSizes: [3.fr, 1.fr, 3.fr],
      columnSizes: [1.fr, 1.fr],
      columnGap: 12,
      rowGap: 12,
      children: [
        Center(child: SvgPicture.asset("assets/svg/logo.svg", color: Colors.white)).inGridArea('header'),
        for (int i = 0; i < PhotosManagerBase.instance.photos.length; i++) ...[
          Center(child: RotatedBox(
            quarterTurns: 1,
            child: Image.memory(PhotosManagerBase.instance.photos[i])),
          ).inGridArea('content${i+1}'),
        ]
      ],
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