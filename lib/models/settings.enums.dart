part of 'settings.dart';

enum LiveViewMethod {

  debugNoise(0, "Debug - Static noise"),
  webcam(1, "Webcam");

  // can add more properties or getters/methods if needed
  final int value;
  final String name;

  // can use named parameters if you want
  const LiveViewMethod(this.value, this.name);

  ComboBoxItem<LiveViewMethod> toComboBoxItem() => ComboBoxItem(value: this, child: Text(name));

  static List<ComboBoxItem<LiveViewMethod>> asComboBoxItems() => LiveViewMethod.values.map((value) => value.toComboBoxItem()).toList();

}

enum CaptureMethod {

  liveViewSource(0, "Live view source"),
  sonyImagingEdgeDesktop(1, "Sony Imaging Edge Desktop automation");

  // can add more properties or getters/methods if needed
  final int value;
  final String name;

  // can use named parameters if you want
  const CaptureMethod(this.value, this.name);

  ComboBoxItem<CaptureMethod> toComboBoxItem() => ComboBoxItem(value: this, child: Text(name));

  static List<ComboBoxItem<CaptureMethod>> asComboBoxItems() => CaptureMethod.values.map((value) => value.toComboBoxItem()).toList();

}

enum ExportFormat {

  jpgFormat(0, "JPG"),
  pngFormat(1, "PNG");

  // can add more properties or getters/methods if needed
  final int value;
  final String name;

  // can use named parameters if you want
  const ExportFormat(this.value, this.name);

  ComboBoxItem<ExportFormat> toComboBoxItem() => ComboBoxItem(value: this, child: Text(name));

  static List<ComboBoxItem<ExportFormat>> asComboBoxItems() => ExportFormat.values.map((value) => value.toComboBoxItem()).toList();

}

enum Flip {

  none(false, false, "None"),
  horizontally(true, false, "Horizontally"),
  vertically(false, true, "Vertically"),
  both(true, true, "Both");

  // can add more properties or getters/methods if needed
  final bool flipX;
  final bool flipY;
  final String name;

  // can use named parameters if you want
  const Flip(this.flipX, this.flipY, this.name);

  ComboBoxItem<Flip> toComboBoxItem() => ComboBoxItem(value: this, child: Text(name));

  static List<ComboBoxItem<Flip>> asComboBoxItems() => Flip.values.map((value) => value.toComboBoxItem()).toList();

}
