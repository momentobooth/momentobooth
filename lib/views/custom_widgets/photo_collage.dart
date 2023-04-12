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
import 'package:mobx/src/api/observable_collections.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';

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

  ScreenshotController screenshotController = ScreenshotController(); 

  MomentoBoothThemeData get theme => MomentoBoothThemeData.defaults();
  static const double gap = 20.0;

  ObservableList<int> get chosen => PhotosManagerBase.instance.chosen;
  ObservableList<Uint8List> get photos => PhotosManagerBase.instance.photos;
  Iterable<Uint8List> get chosenPhotos => PhotosManagerBase.instance.chosenPhotos;
  int get nChosen => PhotosManagerBase.instance.chosen.length;

  @override
  Widget build(BuildContext context) {
    return Screenshot(
      controller: screenshotController,
      child: AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: Padding(
          padding: const EdgeInsets.all(gap),
          child: Observer(builder: (context) => _layout),
        )
      ),
    );
  }

  Widget get _layout {
    if (PhotosManagerBase.instance.chosen.isEmpty) {
      return _zeroLayout;
    } else if (nChosen == 1) {
      return _oneLayout;
    } else if (nChosen == 2) {
      return _twoLayout;
    } else if (nChosen == 3) {
      return _threeLayout;
    } else if (nChosen == 4) {
      return _fourLayout;
    }
    return Container();
  }

  Widget get _zeroLayout {
    return RotatedBox(
      quarterTurns: 1,
      child: Center(
      child: AutoSizeText("Select some photos :)",
        style: theme.titleStyle, textAlign: TextAlign.center,),
      ),
    );
  }

  Widget get _oneLayout {
    return LayoutGrid(
      areas: '''
          l1header
          l1content
        ''',
      rowSizes: [1.fr, 8.fr],
      columnSizes: [1.fr],
      columnGap: gap,
      rowGap: gap,
      children: [
        Center(child: SvgPicture.asset("assets/svg/logo.svg", color: Colors.black)).inGridArea('l1header'),
        SizedBox.expand(child: RotatedBox(
          quarterTurns: 1,
          child: Image.memory(photos[chosen[0]], fit: BoxFit.cover,),),
        ).inGridArea('l1content'),
      ],
    );
  }

  Widget get _twoLayout {
    return LayoutGrid(
      areas: '''
          l2header
          l2content1
          l2content2
        ''',
      rowSizes: [1.fr, auto, auto],
      columnSizes: [1.fr],
      columnGap: gap,
      rowGap: gap,
      children: [
        Center(child: SvgPicture.asset("assets/svg/logo.svg", color: Colors.black)).inGridArea('l2header'),
        for (int i = 0; i < nChosen; i++) ...[
          Image.memory(photos[chosen[i]]).inGridArea('l2content${i+1}'),
        ]
      ],
    );
  }

  Widget get _threeLayout {
    return LayoutGrid(
      areas: '''
          l3header1 l3header2
          l3content1 l3content4
          l3content2 l3content5
          l3content3 l3content6
        ''',
      rowSizes: [1.fr, auto, auto, auto],
      columnSizes: [1.fr, 1.fr],
      columnGap: 2*gap,
      rowGap: gap,
      children: [
        Container(
          alignment: Alignment.center,
          color: Colors.blue,
          child: Text("Powered by Casper die echt teringsnel Flutter geleerd heeft", textAlign: TextAlign.center,)
        ).inGridArea('l3header1'),
        Center(child: SvgPicture.asset("assets/svg/logo.svg", color: Colors.black)).inGridArea('l3header2'),
        for (int i = 0; i < nChosen; i++) ...[
          Image.memory(photos[chosen[i]]).inGridArea('l3content${i+1}'),
          Image.memory(photos[chosen[i]]).inGridArea('l3content${i+4}'),
        ]
      ],
    );
  }

  Widget get _fourLayout {
    return LayoutGrid(
      areas: '''
          l4content1 l4content2
          l4header   l4header
          l4content3 l4content4
        ''',
      rowSizes: [5.fr, 1.fr, 5.fr],
      columnSizes: [1.fr, 1.fr],
      columnGap: gap,
      rowGap: gap,
      children: [
        Center(child: SvgPicture.asset("assets/svg/logo.svg", color: Colors.black)).inGridArea('l4header'),
        for (int i = 0; i < nChosen; i++) ...[
          Center(child: RotatedBox(
            quarterTurns: 1,
            child: Image.memory(photos[chosen[i]])),
          ).inGridArea('l4content${i+1}'),
        ]
      ],
    );
  }

  Future<Uint8List?> getCollageImage() {
    return screenshotController.capture(pixelRatio: 6.0);
  }

}
