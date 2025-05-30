import 'package:fluent_ui/fluent_ui.dart';
import 'package:lottie/lottie.dart';
import 'package:momento_booth/extensions/build_context_extension.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

class LoadingDialog extends StatelessWidget {

  final String title;
  final Widget spinner;

  LoadingDialog.generic({super.key, required this.title}) : spinner = Container(
    width: 64,
    height: 64,
    margin: EdgeInsets.all(24),
    child: ProgressRing(
      strokeWidth: 6,
      activeColor: Colors.black,
    ),
  );

  LoadingDialog.cameraDownload({super.key, required this.title})
    : spinner = Lottie.asset(
        'assets/animations/Animation - 1708738963082.json',
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
        frameRate: FrameRate.max,
        width: 120,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      height: 200,
      width: 400,
      decoration: ShapeDecoration(
        color: FluentTheme.of(context).accentColor.light,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(96),
        ),
      ),
      child: Row(
        children: [
          spinner,
          Flexible(
            child: Text(
              title,
              style: context.theme.dialogTheme.titleStyle.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

}

@widgetbook.UseCase(
  name: 'Loading dialog - Generic',
  type: LoadingDialog,
)
Widget loadingDialogGeneric(BuildContext context) {
  return LoadingDialog.generic(
    title: context.knobs.string(label: 'Title', initialValue: 'Please wait...'),
  );
}

@widgetbook.UseCase(
  name: 'Loading dialog - Camera download',
  type: LoadingDialog,
)
Widget loadingDialogCameraDownload(BuildContext context) {
  return LoadingDialog.cameraDownload(
    title: context.knobs.string(label: 'Title', initialValue: 'Loading photo...'),
  );
}
