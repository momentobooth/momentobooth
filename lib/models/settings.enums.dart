part of 'settings.dart';

enum LiveViewMethod {

  fakeImage(0, "Fake image"),
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
