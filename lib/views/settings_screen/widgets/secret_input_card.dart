import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/repositories/secret/secret_repository.dart';
import 'package:momento_booth/views/custom_widgets/cards/fluent_setting_card.dart';
import 'package:momento_booth/views/settings_screen/widgets/update_secret_dialog.dart';

class SecretInputCard extends StatelessWidget {

  final IconData icon;
  final String title;
  final String subtitle;
  final String secretStorageKey;
  final VoidCallback? onSecretStored;

  const SecretInputCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.secretStorageKey,
    this.onSecretStored,
  });

  @override
  Widget build(BuildContext context) {
    return FluentSettingCard(
      icon: icon,
      title: title,
      subtitle: subtitle,
      child: Button(
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
          await getIt<SecretRepository>().storeSecret(secretStorageKey, value);
          onSecretStored?.call();
        },
      ),
    );
  }

}
