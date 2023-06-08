import 'package:flutter/widgets.dart';

class CustomRectTween extends RectTween {

  final Curve curve;

  CustomRectTween({
    super.begin,
    super.end,
    this.curve = Curves.easeInOutCubic,
  }) ;

  @override
  Rect? lerp(double t) => super.lerp(Curves.easeInOutCubic.transform(t));

}
