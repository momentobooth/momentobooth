import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momento_booth/views/components/buttons/photo_booth_filled_button.dart';
import 'package:momento_booth/views/photo_booth_screen/theme/photo_booth_theme.dart';

Widget _app(Widget child) {
  return FluentApp(
    theme: FluentThemeData(extensions: [PhotoBoothTheme.defaultBasic(primaryColor: Colors.blue)]),
    home: Center(child: child),
  );
}

void main() {

  testWidgets('presses itself after the timeout', (tester) async {
    int presses = 0;
    await tester.pumpWidget(_app(PhotoBoothFilledButton(
      title: 'Continue',
      onPressed: () => presses++,
      autoPressAfter: const Duration(seconds: 10),
    )));

    await tester.pump(const Duration(seconds: 9));
    expect(presses, 0);

    // The countdown completes on the first frame after the timeout.
    await tester.pump(const Duration(seconds: 2));
    expect(presses, 1);

    // It does not start over by itself.
    await tester.pump(const Duration(seconds: 20));
    expect(presses, 1);
  });

  testWidgets('a tap presses it right away, and only once', (tester) async {
    int presses = 0;
    await tester.pumpWidget(_app(PhotoBoothFilledButton(
      title: 'Continue',
      onPressed: () => presses++,
      autoPressAfter: const Duration(seconds: 10),
    )));

    await tester.pump(const Duration(seconds: 3));
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(presses, 1);

    await tester.pump(const Duration(seconds: 20));
    expect(presses, 1);
  });

  testWidgets('does not press itself without a timeout', (tester) async {
    int presses = 0;
    await tester.pumpWidget(_app(PhotoBoothFilledButton(
      title: 'Continue',
      onPressed: () => presses++,
    )));

    await tester.pump(const Duration(minutes: 1));
    expect(presses, 0);
  });

}
