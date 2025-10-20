import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:momento_booth/app_localizations.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/views/photo_booth_screen/theme/basic/basic_theme.dart';
import 'package:momento_booth/views/photo_booth_screen/theme/hollywood/hollywood_theme.dart';
import 'package:momento_booth/views/photo_booth_screen/theme/photo_booth_theme.dart';
import 'package:momento_booth/views/photo_booth_screen/theme/wedding/wedding_theme.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

// ignore: always_use_package_imports
import 'widgetbook.directories.g.dart';

void main() {
  runApp(const WidgetbookApp());
}

@App()
class WidgetbookApp extends StatelessWidget {

  const WidgetbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      // Use the generated directories variable
      directories: directories,
      addons: [
        GridAddon(10),
        AlignmentAddon(
          initialAlignment: Alignment.center,
        ),
        InspectorAddon(enabled: true),
        ThemeAddon<PhotoBoothTheme>(
          themes: [
            WidgetbookTheme(
              name: 'Basic',
              data: basicTheme(primaryColor: material.Colors.teal),
            ),
            WidgetbookTheme(
              name: 'Hollywood',
              data: hollywoodTheme(primaryColor: material.Colors.teal),
            ),
            WidgetbookTheme(
              name: 'Wedding',
              data: weddingTheme(primaryColor: material.Colors.teal),
            ),
          ],
          themeBuilder: (context, theme, child) {
            return FluentTheme(
              data: FluentThemeData(extensions: [theme]),
              child: child,
            );
          },
        ),
      ],
      appBuilder: (context, child) {
        return material.MaterialApp(
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FluentLocalizations.delegate,
          ],
          supportedLocales: Language.valuesAsLocale(),
          home: child,
        );
      }
    );
  }

}
