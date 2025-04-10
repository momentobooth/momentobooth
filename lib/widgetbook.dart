import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:momento_booth/app_localizations.dart';
import 'package:momento_booth/views/photo_booth_screen/theme/photo_booth_theme.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

// ignore: always_use_package_imports
import 'widgetbook.directories.g.dart';

void main() {
  runApp(const WidgetbookApp());
}

@widgetbook.App()
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
      ],
      appBuilder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FluentLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'), // English
            Locale('nl'), // Dutch
          ],
          home: FluentTheme(
            data: FluentThemeData(
              extensions: [PhotoBoothTheme.defaultBasic()],
            ),
            child: Material(child: child),
          ),
        );
      }
    );
  }

}
