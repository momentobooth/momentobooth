
import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/views/settings_overlay/components/settings_page.dart';

class SettingsListPage extends StatelessWidget {

  final String title;
  final List<Widget> blocks;

  const SettingsListPage({super.key, required this.title, required this.blocks});

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      title: title,
      bodyBuilder: (context, scrollController, scrollPhysics) {
        return ListView(controller: scrollController, physics: scrollPhysics, children: blocks);
      },
    );
  }

}
