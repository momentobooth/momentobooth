import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:momento_booth/managers/settings_manager.dart';
import 'package:mobx/mobx.dart';
import 'package:path/path.dart' show basename, join; // Without show mobx complains
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

part 'photos_manager.g.dart';

class PhotosManager = PhotosManagerBase with _$PhotosManager;

enum CaptureMode {

  single(0, "Single"),
  collage(1, "Collage");

  // can add more properties or getters/methods if needed
  final int value;
  final String name;

  // can use named parameters if you want
  const CaptureMode(this.value, this.name);

}

/// Class containing global state for photos in the app
abstract class PhotosManagerBase with Store {

  static final PhotosManagerBase instance = PhotosManager._internal();

  @observable
  ObservableList<Uint8List> photos = ObservableList<Uint8List>();

  @observable
  Uint8List? outputImage;

  @observable
  ObservableList<int> chosen = ObservableList<int>();

  @observable
  CaptureMode captureMode = CaptureMode.single;

  @computed
  bool get showLiveViewBackground => photos.isEmpty && captureMode == CaptureMode.single;

  Directory get outputDir => Directory(SettingsManagerBase.instance.settings.output.localFolder);
  int photoNumber = 0;
  bool photoNumberChecked = false;
  static String baseName = "MomentoBooth-image";
 
  Iterable<Uint8List> get chosenPhotos => chosen.map((choice) => photos[choice]);

  PhotosManagerBase._internal();

  @action
  void reset({bool advance = true}) {
    photos.clear();
    chosen.clear();
    captureMode = CaptureMode.single;
    if (advance) { photoNumber++; }
  }

  @action
  Future<File?> writeOutput() async {
    if (instance.outputImage == null) return null;
    if (!photoNumberChecked) {
      photoNumber = await findLastImageNumber()+1;
      photoNumberChecked = true;
    }
    final extension = SettingsManagerBase.instance.settings.output.exportFormat.name.toLowerCase();
    final filePath = join(outputDir.path, '$baseName-${photoNumber.toString().padLeft(4, '0')}.$extension');
    File file = await File(filePath).create();
    return await file.writeAsBytes(instance.outputImage!);
  }
  
  @action
  Future<int> findLastImageNumber() async {
    final fileListBefore = await outputDir.list().toList();
    final matchingFiles = fileListBefore.whereType<File>().where((file) => basename(file.path).startsWith(baseName));
    
    if (matchingFiles.isEmpty) { return 0; }

    final lastImg = matchingFiles.last;
    final pattern = RegExp(r'\d+');
    final match = pattern.firstMatch(basename(lastImg.path));
    if (match != null) {
      return int.parse(match.group(0) ?? "0");
    }
    return 0;
  }

  Future<File> getOutputImageAsTempFile() async {
    final Directory tempDir = await getTemporaryDirectory();
    final ext = SettingsManagerBase.instance.settings.output.exportFormat.name.toLowerCase();
    File file = await File('${tempDir.path}/image.$ext').create();
    await file.writeAsBytes(outputImage!);
    return file;
  }

  Future<Uint8List> getOutputPDF() async {
    final image = pw.MemoryImage(outputImage!);
    const mm = PdfPageFormat.mm;
    final settings = SettingsManagerBase.instance.settings.hardware;
    final pageFormat = PdfPageFormat(settings.pageWidth * mm, settings.pageHeight * mm,
                                     marginBottom: settings.printerMarginBottom * mm,
                                     marginLeft: settings.printerMarginLeft * mm,
                                     marginRight: settings.printerMarginRight * mm,
                                     marginTop: settings.printerMarginTop * mm,);
    const fit = pw.BoxFit.contain;

    // Check if photo should be rotated
    // Do not assume any prior knowledge about the image.
    final bool rotate = image.width! > image.height!;
    late final pw.Image imageWidget;
    if (rotate) {
      imageWidget = pw.Image(image, fit: fit, height: pageFormat.availableWidth, width: pageFormat.availableHeight);
    } else {
      imageWidget = pw.Image(image, fit: fit, height: pageFormat.availableHeight, width: pageFormat.availableWidth);
    }

    final doc = pw.Document(title: "MomentoBooth image");
    doc.addPage(pw.Page(
      pageFormat: pageFormat,
      build: (pw.Context context) {
        return pw.Center(
          child: rotate ? pw.Transform.rotateBox(angle: 0.5*pi, child: imageWidget,) : imageWidget,
        );
      })
    );

    return await doc.save();
  }

}
