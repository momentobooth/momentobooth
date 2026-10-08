import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/settings_manager.dart';

/// Warns the user before a camera that has not been confirmed before is used through gPhoto2.
class GPhoto2CameraWarningDialog extends StatelessWidget {

  final String cameraModel;

  const GPhoto2CameraWarningDialog({super.key, required this.cameraModel});

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 560),
      title: const Text("Use this camera with gPhoto2?"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Text(cameraModel, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Text(
            "This camera model has not been used with MomentoBooth on this computer before. "
            "Even though controlling a camera through gPhoto2 is generally safe, during development a bug once corrupted the SD card of a camera, after which it refused to work until the card was formatted.\n\n"
            "Therefore, make sure there is nothing important on the memory card when testing for the first time.",
          ),
        ],
      ),
      actions: [
        Button(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("Cancel"),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text("I understand, use this camera"),
        ),
      ],
    );
  }

  /// Returns true if [cameraModel] is already confirmed or the user confirms it in a dialog, in which case it is remembered.
  /// The model name is used because the port part of the camera identifier changes per USB port.
  static Future<bool> confirmIfNeeded(BuildContext context, String cameraModel) async {
    final settingsManager = getIt<SettingsManager>();
    if (settingsManager.settings.hardware.gPhoto2ConfirmedCameras.contains(cameraModel)) return true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => GPhoto2CameraWarningDialog(cameraModel: cameraModel),
    );
    if (confirmed != true) return false;

    final current = settingsManager.settings;
    await settingsManager.updateAndSave(current.copyWith.hardware(
      gPhoto2ConfirmedCameras: [...current.hardware.gPhoto2ConfirmedCameras, cameraModel],
    ));
    return true;
  }

}
