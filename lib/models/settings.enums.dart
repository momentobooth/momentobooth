part of 'settings.dart';

enum ImagingMethod {

  debugNoise(),
  webcam(),
  gphoto2(),
  debugStaticImage(),
  debugServeFromDirectory(),
  custom();

  const ImagingMethod();

  ComboBoxItem<ImagingMethod> toComboBoxItem() => ComboBoxItem(value: this, child: Text(name));

  static List<ComboBoxItem<ImagingMethod>> asComboBoxItems() => ImagingMethod.values.map((value) => value.toComboBoxItem()).toList();

}

enum LiveViewMethod {

  debugNoise(0, "Debug - Static noise"),
  webcam(1, "Webcam"),
  gphoto2(2, "gPhoto2"),
  debugStaticImage(3, "Debug - Static image"),
  serveFromDirectory(4, "Serve from directory");

  final int value;
  final String name;

  const LiveViewMethod(this.value, this.name);

  ComboBoxItem<LiveViewMethod> toComboBoxItem() => ComboBoxItem(value: this, child: Text(name));

  static List<ComboBoxItem<LiveViewMethod>> asComboBoxItems() => LiveViewMethod.values.map((value) => value.toComboBoxItem()).toList();

}

enum CaptureMethod {

  liveViewSource(0, "Live view source"),
  sonyImagingEdgeDesktop(1, "Sony IED automation"),
  gPhoto2(2, "gPhoto2");

  final int value;
  final String name;

  const CaptureMethod(this.value, this.name);

  ComboBoxItem<CaptureMethod> toComboBoxItem() => ComboBoxItem(value: this, child: Text(name));

  static List<ComboBoxItem<CaptureMethod>> asComboBoxItems() => CaptureMethod.values.map((value) => value.toComboBoxItem()).toList();

}

enum GPhoto2SpecialHandling {

  none("None"),
  nikonDSLR("Nikon DSLR"),
  nikonGeneric("Nikon"),
  sony("Sony");

  final String name;

  const GPhoto2SpecialHandling(this.name);

  ComboBoxItem<GPhoto2SpecialHandling> toComboBoxItem() => ComboBoxItem(value: this, child: Text(name));

  static List<ComboBoxItem<GPhoto2SpecialHandling>> asComboBoxItems() => GPhoto2SpecialHandling.values.map((value) => value.toComboBoxItem()).toList();

  GPhoto2CameraSpecialHandling toHelperLibraryEnumValue() {
    return switch (this) {
      GPhoto2SpecialHandling.none => GPhoto2CameraSpecialHandling.none,
      GPhoto2SpecialHandling.nikonDSLR => GPhoto2CameraSpecialHandling.nikonDslr,
      GPhoto2SpecialHandling.nikonGeneric => GPhoto2CameraSpecialHandling.nikonGeneric,
      GPhoto2SpecialHandling.sony => GPhoto2CameraSpecialHandling.sony,
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

  static List<ComboBoxItem<ScreenTransitionAnimation>> asComboBoxItems() => values.map((value) => value.toComboBoxItem()).toList();

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

  static List<ComboBoxItem<Flip>> asComboBoxItems() => values.map((value) => value.toComboBoxItem()).toList();

  FlipAxis? get asFlipAxis => switch (this) {
    Flip.none => null,
    Flip.horizontally => FlipAxis.horizontally,
    Flip.vertically => FlipAxis.vertically,
  };

}

enum Rotate {

  none("No rotation", 0, 0),
  clockwise90degrees("90 degrees", 1, math.pi / 2),
  clockwise180degrees("180 degrees", 2, math.pi),
  clockwise270degrees("270 degrees", 3, math.pi * 1.5);

  // can add more properties or getters/methods if needed
  final String name;

  final int quarterTurns;

  final double radians;

  // can use named parameters if you want
  const Rotate(this.name, this.quarterTurns, this.radians);

  ComboBoxItem<Rotate> toComboBoxItem() => ComboBoxItem(value: this, child: Text(name));

  static List<ComboBoxItem<Rotate>> asComboBoxItems() => values.map((value) => value.toComboBoxItem()).toList();

  Rotation? get asRotation => switch (this) {
        Rotate.none => null,
        Rotate.clockwise90degrees => Rotation.rotate90,
        Rotate.clockwise180degrees => Rotation.rotate180,
        Rotate.clockwise270degrees => Rotation.rotate270,
      };

}

enum Language {

  noLanguage("None", "--", "None", "", "", true),
  english("English", "en", "English", "gb", "🇬🇧", true),
  dutch("Dutch", "nl", "Nederlands", "nl", "🇳🇱", true),
  german("German", "de", "Deutsch", "de", "🇩🇪", false),
  french("French", "fr", "Français", 'fr', "🇫🇷", false);

  final String name;
  final String code;
  final String nameNative;
  final String countryCode;
  final String flag;
  final bool qualityChecked;

  const Language(this.name, this.code, this.nameNative, this.countryCode, this.flag, this.qualityChecked);

  ComboBoxItem<Language> toComboBoxItem() => ComboBoxItem(value: this, child: Text(name));

  static List<Locale> valuesAsLocale() => Language.values.map((l) => Locale(l.code)).toList();

  static List<ComboBoxItem<Language>> asComboBoxItems() => values.where((v) => v != noLanguage).map((value) => value.toComboBoxItem()).toList();
  static List<ComboBoxItem<Language>> asOptionalComboBoxItems() => values.map((value) => value.toComboBoxItem()).toList();

  static List<Language> get definedValues => values.where((v) => v != noLanguage).toList();

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

  static List<ComboBoxItem<BackgroundBlur>> asComboBoxItems() => values.map((value) => value.toComboBoxItem()).toList();

}

enum PrintingImplementation {

  none("Disable printing"),
  flutterPrinting("Flutter printing plugin"),
  cups("CUPS");

  // can add more properties or getters/methods if needed
  final String name;

  // can use named parameters if you want
  const PrintingImplementation(this.name);

  ComboBoxItem<PrintingImplementation> toComboBoxItem() => ComboBoxItem(value: this, child: Text(name));

  static List<ComboBoxItem<PrintingImplementation>> asComboBoxItems() => values.map((value) => value.toComboBoxItem()).toList();

}

enum PrintSize {

  normal("Normal print size"),
  split("Split normal size, e.g. for 3-collage"),
  small("Small print size"),
  tiny("Tiny print size");

  // can add more properties or getters/methods if needed
  final String name;

  // can use named parameters if you want
  const PrintSize(this.name);

}

enum ExternalSystemCheckType {

  ping,
  http,

}

enum ExternalSystemCheckSeverity {

  info,
  warning,
  error,

}

enum OnboardingStep {

  setupImagingDevice,
  importSettings,
  openProject,

}
