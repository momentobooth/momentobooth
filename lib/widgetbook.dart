import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:momento_booth/app_localizations.dart';
import 'package:momento_booth/theme/momento_booth_theme.dart';
import 'package:momento_booth/theme/momento_booth_theme_data.dart';
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
      integrations: [
        // To make addons & knobs work with Widgetbook Cloud
        WidgetbookCloudIntegration(),
      ],
      appBuilder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            FluentLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'), // English
            Locale('nl'), // Dutch
          ],
          home: FluentTheme(
            data: FluentThemeData.light(),
            child: Material(
              child: MomentoBoothTheme(
                data: MomentoBoothThemeData.defaults(),
                child: child,
              ),
            ),
          ),
        );
      }
    );
  }

}
