import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/rust_bridge/library_api.generated.dart';
import 'package:momento_booth/rust_bridge/library_bridge.dart';
import 'package:momento_booth/theme/momento_booth_theme_data.dart';
import 'package:flutter/material.dart' hide Action, RawImage;
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobx/mobx.dart';
import 'package:path/path.dart';
import 'package:screenshot/screenshot.dart';

enum TemplateKind {

  front(0, "front"),
  back(1, "back");

  // can add more properties or getters/methods if needed
  final int value;
  final String name;

  // can use named parameters if you want
  const TemplateKind(this.value, this.name);

}

class PhotoCollage extends StatefulWidget {

  final double aspectRatio;
  final bool showLogo;

  const PhotoCollage({
    super.key,
    required this.aspectRatio,
    this.showLogo = false,
  });

  @override
  State<PhotoCollage> createState() => PhotoCollageState();

}

class PhotoCollageState extends State<PhotoCollage> {

  PhotoCollageState() {
    setInitialized = Action(_setInitialized);
    findTemplates();
  }

  void _setInitialized(bool value) => _initialized.value = value;

  final Observable<bool> _initialized = Observable(false);
  bool get initialized => _initialized.value;
  late Action setInitialized;

  ScreenshotController screenshotController = ScreenshotController(); 

  MomentoBoothThemeData get theme => MomentoBoothThemeData.defaults();
  static const double gap = 20.0;

  ObservableList<int> get chosen => PhotosManagerBase.instance.chosen;
  ObservableList<Uint8List> get photos => PhotosManagerBase.instance.photos;
  Iterable<Uint8List> get chosenPhotos => PhotosManagerBase.instance.chosenPhotos;
  int get nChosen => PhotosManagerBase.instance.chosen.length;
  int get rotation => [0, 1, 4].contains(nChosen) ? 1 : 0;

  String get templatesFolder => SettingsManagerBase.instance.settings.templatesFolder;

  var templates = {
    TemplateKind.front: <int, File?>{},
    TemplateKind.back: <int, File?>{},
  };
  
  void findTemplates() async {
    for (int i = 0; i <= 4; i++) {
      final frontTemplate = await _templateResolver(TemplateKind.front, i);
      final backTemplate = await _templateResolver(TemplateKind.back, i);
      templates[TemplateKind.front]?[i] = frontTemplate;
      templates[TemplateKind.back]?[i] = backTemplate;
    }
    setInitialized([true]);
  }

  File? get frontTemplate => templates[TemplateKind.front]?[nChosen];
  File? get backTemplate => templates[TemplateKind.back]?[nChosen];

  /// Checks if a given template file exists and returns it if it does.
  Future<File?> _templateTest(String fileName) async {
    var template = File(join(templatesFolder, fileName));
    if (await template.exists()) { return template; }
    return null;
  }

  /// Resolve the template for a given kind (backtground, foreground) and number of photos.
  Future<File?> _templateResolver(TemplateKind kind, int numPhotos) async {
    final filesToCheck = [
      _templateTest("${kind.name}-template-$numPhotos.png"),
      _templateTest("${kind.name}-template-$numPhotos.jpg"),
      _templateTest("${kind.name}-template.png"),
      _templateTest("${kind.name}-template.jpg"),
    ];
    final checkedFiles = await Future.wait(filesToCheck);
    return checkedFiles.firstWhere((element) => element != null, orElse: () => null);
  }

  @override
  Widget build(BuildContext context) {
    return Screenshot(
      controller: screenshotController,
      child: AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: Observer(builder: (context) => _layout)
      ),
    );
  }

  Widget get _layout {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (int i = 0; i <= 4; i++) ...[
          if (initialized && templates[TemplateKind.back]?[i] != null)
            Opacity(
              opacity: i == nChosen ? 1 : 0,
              child: Image.file(templates[TemplateKind.back]![i]!, fit: BoxFit.cover),
            ),
        ],
        Padding(
          padding: const EdgeInsets.all(gap),
          child: _innerLayout,
        ),
        for (int i = 0; i <= 4; i++) ...[
          if (initialized && templates[TemplateKind.front]?[i] != null)
            Opacity(
              opacity: i == nChosen ? 1 : 0,
              child: Image.file(templates[TemplateKind.front]![i]!, fit: BoxFit.cover),
            ),
        ],
      ]
    );
  }

  Widget get _innerLayout {
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
        if (widget.showLogo)
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
        if (widget.showLogo)
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
        if (widget.showLogo) ...[
          Center(child: SvgPicture.asset("assets/svg/logo.svg", color: Colors.black)).inGridArea('l3header1'),
          Center(child: SvgPicture.asset("assets/svg/logo.svg", color: Colors.black)).inGridArea('l3header2'),
        ],
        for (int i = 0; i < nChosen; i++) ...[
          Image.memory(photos[chosen[i]]).inGridArea('l3content${i+1}'),
          Image.memory(photos[chosen[i]]).inGridArea('l3content${i+4}'),
        ]
      ],
    );
  }

  Widget get _fourLayout {
    return Stack(
      children: [
        LayoutGrid(
          areas: '''
              l4content3 l4content1
              l4content4 l4content2
            ''',
          rowSizes: [auto, auto],
          columnSizes: [auto, auto],
          columnGap: gap,
          rowGap: gap,
          children: [
            for (int i = 0; i < nChosen; i++) ...[
              RotatedBox(
                quarterTurns: 1,
                child: SizedBox.expand(
                  child: Image.memory(photos[chosen[i]], fit: BoxFit.cover,)
                )
              ).inGridArea('l4content${i+1}'),
            ]
          ],
        ),
        if (widget.showLogo)
          Padding(
            padding: const EdgeInsets.all(250),
            child: RotatedBox(
              quarterTurns: 1,
              child: Center(child: SvgPicture.asset("assets/svg/logo.svg", color: Colors.black))
            ),
          ),
      ],
    );
  }

  Future<Uint8List?> getCollageImage({required double pixelRatio, ExportFormat format = ExportFormat.jpgFormat, int jpgQuality = 80}) async {
    final delay = Duration(milliseconds: 20);
    if (format == ExportFormat.pngFormat) {
      return screenshotController.capture(pixelRatio: pixelRatio, delay: delay);
    }
    final image = await screenshotController.captureAsUiImage(pixelRatio: pixelRatio, delay: delay);
    // Lib by default uses ui.ImageByteFormat.png for capture, encoding is what takes long.
    final byteData = await image!.toByteData(format: ui.ImageByteFormat.rawRgba);
    // Create an image lib image instance from ui image instance.
    //final dartImage = img.Image.fromBytes(width: image.width, height: image.height, bytes: byteData!.buffer, numChannels: 4, order: img.ChannelOrder.rgba);
    //final jpg = img.encodeJpg(dartImage, quality: jpgQuality);
    final rawImage = RawImage(format: RawImageFormat.Rgba, data: byteData!.buffer.asUint8List(), width: image.width, height: image.height);
    final List<ImageOperation> operationsBeforeEncoding = rotation == 1 ? [ImageOperation.rotate(Rotation.Rotate270)] : [];
    final jpg = await rustLibraryApi.jpegEncode(rawImage: rawImage, quality: jpgQuality, operationsBeforeEncoding: operationsBeforeEncoding);
    return jpg;
  }

}
