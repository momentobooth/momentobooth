part of 'settings.dart';

enum LiveViewMethod {

  debugNoise(0, "Debug - Static noise"),
  webcam(1, "Webcam"),
  gphoto2(2, "gPhoto2"),
  debugStaticImage(3, "Debug - Static image");

  final int value;
  final String name;

  const LiveViewMethod(this.value, this.name);

  ComboBoxItem<LiveViewMethod> toComboBoxItem() => ComboBoxItem(value: this, child: Text(name));

  static List<ComboBoxItem<LiveViewMethod>> asComboBoxItems() => LiveViewMethod.values.map((value) => value.toComboBoxItem()).toList();

}

enum CaptureMethod {

  liveViewSource(0, "Live view source"),
  sonyImagingEdgeDesktop(1, "Sony Imaging Edge Desktop automation"),
  gPhoto2(2, "gPhoto2");

  final int value;
  final String name;

  const CaptureMethod(this.value, this.name);

  ComboBoxItem<CaptureMethod> toComboBoxItem() => ComboBoxItem(value: this, child: Text(name));

  static List<ComboBoxItem<CaptureMethod>> asComboBoxItems() => CaptureMethod.values.map((value) => value.toComboBoxItem()).toList();

}

enum GPhoto2SpecialHandling {

  none("None"),
  nikonDSLR("Nikon DSLR");

  final String name;

  const GPhoto2SpecialHandling(this.name);

  ComboBoxItem<GPhoto2SpecialHandling> toComboBoxItem() => ComboBoxItem(value: this, child: Text(name));

  static List<ComboBoxItem<GPhoto2SpecialHandling>> asComboBoxItems() => GPhoto2SpecialHandling.values.map((value) => value.toComboBoxItem()).toList();

  GPhoto2CameraSpecialHandling toHelperLibraryEnumValue() {
    return switch (this) {
      GPhoto2SpecialHandling.none => GPhoto2CameraSpecialHandling.None,
      GPhoto2SpecialHandling.nikonDSLR => GPhoto2CameraSpecialHandling.NikonDSLR,
    };
  }

}

enum ExportFormat {

  jpgFormat(0, "JPG"),
  pngFormat(1, "PNG");

  final int value;
  final String name;

  const ExportFormat(this.value, this.name);

  ComboBoxItem<ExportFormat> toComboBoxItem() => ComboBoxItem(value: this, child: Text(name));

  static List<ComboBoxItem<ExportFormat>> asComboBoxItems() => ExportFormat.values.map((value) => value.toComboBoxItem()).toList();

}

enum FilterQuality {

  none(ui.FilterQuality.none, "None"),
  low(ui.FilterQuality.low, "Low"),
  medium(ui.FilterQuality.medium, "Medium"),
  high(ui.FilterQuality.high, "High");

  final ui.FilterQuality value;
  final String name;

  const FilterQuality(this.value, this.name);

  ComboBoxItem<FilterQuality> toComboBoxItem() => ComboBoxItem(value: this, child: Text(name));

  static List<ComboBoxItem<FilterQuality>> asComboBoxItems() => FilterQuality.values.map((value) => value.toComboBoxItem()).toList();

  ui.FilterQuality toUiFilterQuality() => switch (this) {
    FilterQuality.none => ui.FilterQuality.none,
    FilterQuality.low => ui.FilterQuality.low,
    FilterQuality.medium => ui.FilterQuality.medium,
    FilterQuality.high => ui.FilterQuality.high,
  };

}

enum ScreenTransitionAnimation {

  none("None"),
  fadeAndScale("Fade and scale"),
  fadeAndSlide("Fade and slide");

  final String name;

  // can use named parameters if you want
  const ScreenTransitionAnimation(this.name);

  ComboBoxItem<ScreenTransitionAnimation> toComboBoxItem() => ComboBoxItem(value: this, child: Text(name));

  static List<ComboBoxItem<ScreenTransitionAnimation>> asComboBoxItems() => ScreenTransitionAnimation.values.map((value) => value.toComboBoxItem()).toList();

}

enum Flip {

  none("None"),
  horizontally("Horizontally"),
  vertically("Vertically");

  // can add more properties or getters/methods if needed
  final String name;

  // can use named parameters if you want
  const Flip(this.name);

  ComboBoxItem<Flip> toComboBoxItem() => ComboBoxItem(value: this, child: Text(name));

  static List<ComboBoxItem<Flip>> asComboBoxItems() => Flip.values.map((value) => value.toComboBoxItem()).toList();

  FlipAxis? get asFlipAxis => switch (this) {
    Flip.none => null,
    Flip.horizontally => FlipAxis.Horizontally,
    Flip.vertically => FlipAxis.Vertically,
  };

}

enum Rotate {

  none("No rotation"),
  clockwise90degrees("90 degrees"),
  clockwise180degrees("180 degrees"),
  clockwise270degrees("270 degrees");

  // can add more properties or getters/methods if needed
  final String name;

  // can use named parameters if you want
  const Rotate(this.name);

  ComboBoxItem<Rotate> toComboBoxItem() => ComboBoxItem(value: this, child: Text(name));

  static List<ComboBoxItem<Rotate>> asComboBoxItems() => Rotate.values.map((value) => value.toComboBoxItem()).toList();

  Rotation? get asRotation => switch (this) {
        Rotate.none => null,
        Rotate.clockwise90degrees => Rotation.Rotate90,
        Rotate.clockwise180degrees => Rotation.Rotate180,
        Rotate.clockwise270degrees => Rotation.Rotate270,
      };

}

enum Language {

  english("English", "en"),
  dutch("Dutch", "nl");

  final String name;
  final String code;

  // can use named parameters if you want
  const Language(this.name, this.code);

  ComboBoxItem<Language> toComboBoxItem() => ComboBoxItem(value: this, child: Text(name));

  static List<ComboBoxItem<Language>> asComboBoxItems() => Language.values.map((value) => value.toComboBoxItem()).toList();

  Locale toLocale() => Locale(code);

}

enum AnimationAnchor {

  //touchToStart("Touch to start"), // TODO: implement
  //logo("Logo"), // TODO: implement
  screen("Screen");

  final String name;

  const AnimationAnchor(this.name);

}

enum BackgroundBlur {

  none("Disabled"),
  textureBlur("Use texture blur");

  // can add more properties or getters/methods if needed
  final String name;

  // can use named parameters if you want
  const BackgroundBlur(this.name);

  ComboBoxItem<BackgroundBlur> toComboBoxItem() => ComboBoxItem(value: this, child: Text(name));

  static List<ComboBoxItem<BackgroundBlur>> asComboBoxItems() => BackgroundBlur.values.map((value) => value.toComboBoxItem()).toList();

}
