import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart' hide Action, RawImage;
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/app_localizations.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/managers/project_manager.dart';
import 'package:momento_booth/models/photo_capture.dart';
import 'package:momento_booth/utils/logger.dart';
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

class QuoteCollage extends StatefulWidget {

  final double padding;
  final int? debug;
  final VoidCallback? decodeCallback;
  final bool isVisible;

  const QuoteCollage({
    super.key,
    this.padding = 0,
    this.debug,
    this.decodeCallback,
    this.isVisible = true,
  });

  @override
  State<QuoteCollage> createState() => QuoteCollageState();

}

class QuoteCollageState extends State<QuoteCollage> with Logger {

  @override
  void initState() {
    super.initState();
    setInitialized = Action(_setInitialized);
    findTemplates();
  }

  void _setInitialized(int value) => _initialized.value = value;

  final Observable<int> _initialized = Observable(0);
  int get initialized => _initialized.value;
  late Action setInitialized;

  ScreenshotController screenshotController = ScreenshotController();

  static const double gap = 20.0;

  ObservableList<PhotoCapture> get photos => getIt<PhotosManager>().photos;
  String? get summaryString => getIt<PhotosManager>().summaryText;
  bool firstImageDecoded = false;

  Directory get templatesFolder => getIt<ProjectManager>().getTemplateDir();

  File? template;

  Future<void> findTemplates() async {
      template = await _templateResolver();
      setInitialized([1]);
  }

  /// Checks if a given template file exists and returns it if it does.
  Future<File?> _templateTest(String fileName) async {
    var template = File(join(templatesFolder.path, fileName));
    if (template.existsSync()) return template;
    return null;
  }

  /// Resolve the template for a given kind (backtground, foreground) and number of photos.
  Future<File?> _templateResolver() async {
    const name = "separator";
    final filesToCheck = [
      _templateTest("$name.png"),
      _templateTest("$name.jpg"),
    ];
    final checkedFiles = await Future.wait(filesToCheck);
    return checkedFiles.firstWhere((element) => element != null, orElse: () => null);
  }

  @override
  Widget build(BuildContext context) {
    Widget collageBox = Screenshot(
      controller: screenshotController,
      child: ColoredBox(
        color: Colors.white,
        child: SizedBox(
          width: 576,
          child: Observer(builder: (context) => _getLayout(AppLocalizations.of(context)!, context)),
        ),
      ),
    );

    if (widget.isVisible) return collageBox;

    // We have already tested built in Flutter widgets like Visibility, Opacity, Offstage, but none of them work...
    return Transform.translate(
      offset: Offset(MediaQuery.sizeOf(context).width, 0),
      child: collageBox,
    );
  }

  Widget _getLayout(AppLocalizations localizations, BuildContext context) {
    return Column(
      spacing: 16,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // _PhotoContainer(
        //   rotated: true,
        //   child: _getImage(2, decodeCallback: widget.decodeCallback),
        // ),
        Image.memory(photos[2].data, fit: BoxFit.contain,),
        Text(summaryString ?? "loading...",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: Colors.black,
            fontSize: 60,
          ),
        ),
        if (initialized > 0 && template != null)
          Image.file(template!, fit: BoxFit.contain,)
      ],
    );
  }

  Future<Uint8List?> getCollageImage() async {
    // Await frame render, should workaround the black image issue
    await waitForPostFrameCallback();

    return screenshotController.capture(pixelRatio: 1.0);
  }

  Future<void> waitForPostFrameCallback() {
    Completer completer = Completer();
    WidgetsBinding.instance.addPostFrameCallback((_) => completer.complete());
    return completer.future;
  }

}
