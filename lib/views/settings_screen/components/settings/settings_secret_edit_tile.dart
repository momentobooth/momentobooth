import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/repositories/secrets/secrets_repository.dart';
import 'package:momento_booth/views/settings_screen/components/settings/settings_tile.dart';
import 'package:momento_booth/views/settings_screen/components/update_secret_dialog.dart';

class SettingsSecretEditTile extends StatelessWidget {

  final IconData icon;
  final String title;
  final String subtitle;
  final String secretStorageKey;
  final VoidCallback? onSecretStored;

  const SettingsSecretEditTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.secretStorageKey,
    this.onSecretStored,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      setting: Button(
        onPressed: () => _openSecretUpdateDialog(context),
        child: const Text('Change'),
      ),
    );
  }

  void _openSecretUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => UpdateSecretDialog(
        secretName: secretStorageKey,
        onDismiss: () => Navigator.of(context).pop(),
        onSavePressed: (value) async {
          Navigator.of(context).pop();
          await getIt<SecretsRepository>().storeSecret(secretStorageKey, value);
          onSecretStored?.call();
        },
      ),
    );
  }

}
