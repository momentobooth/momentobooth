import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';

class OnboardingPage extends StatefulWidget {

  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();

}

class _OnboardingPageState extends State<OnboardingPage> with TickerProviderStateMixin {

  @override
  Widget build(BuildContext context) {
    final FluentThemeData themeData = FluentTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            themeData.accentColor.lightest,
            const Color(0xFFE8EAF6),
          ],
          center: const Alignment(-0.1, 0.9),
        ),
      ),
      child: LayoutGrid(
        columnGap: 12,
        rowGap: 12,
        areas: '''
            lt t rt
            l  B r
            lb b rb
          ''',
        // A number of extension methods are provided for concise track sizing
        columnSizes: [
          1.4.fr,
          5.0.fr,
          1.4.fr,
        ],
        rowSizes: [
          0.8.fr,
          5.0.fr,
          0.8.fr,
        ],
        children: [
          gridArea('B').containing(Builder(builder: _getCenterWidget)),
        ],
      ),
    );
  }

  Widget _getCenterWidget(BuildContext context) {
    return Acrylic(
      elevation: 16.0,
      luminosityAlpha: 0.8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
      child: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(34, 0, 34, 34),
              child: Center(child: ProgressRing()),
            ),
          ),
        ],
      ),
    );
  }

}
