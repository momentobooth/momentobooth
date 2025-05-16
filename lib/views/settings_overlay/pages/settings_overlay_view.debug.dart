part of '../settings_overlay_view.dart';

Widget _getDebugTab(SettingsOverlayViewModel viewModel, SettingsOverlayController controller) {
  return SettingsPage(
    title: "Debug",
    blocks: [
      SettingsSection(
        title: "Photos and capture",
        settings: [
          Observer(
            builder: (context) => SettingsTextDisplayTile(
              icon: LucideIcons.hash,
              title: "Photos in memory",
              subtitle: "The number of photos stored in memory in the PhotosManager",
              text: getIt<PhotosManager>().photos.length.toString(),
            ),
          ),
          Observer(
            builder: (context) => Row(
              spacing: 8.0,
              children: [
                for (int i = 0; i < getIt<PhotosManager>().photos.length; i++)
                  SizedBox.square(
                    dimension: 100,
                    child: ImageWithLoaderFallback.memory(getIt<PhotosManager>().photos[i].data, onImageDecoded: () => {})
                  )
              ],
            )
          ),
          SettingsActionTile(
            icon: LucideIcons.camera,
            title: "Capture photo",
            subtitle: "Trigger a photo capture",
            buttonText: "Trigger capture",
            onPressed: controller.onTriggerCapturePressed,
          ),
          SettingsActionTile(
            icon: LucideIcons.trash,
            title: "Clear photos",
            subtitle: "Clear the photos stored in memory",
            buttonText: "Clear photos",
            onPressed: controller.onPhotosClearPressed,
          ),
          SettingsActionTile(
            icon: LucideIcons.video,
            title: "Start video recording",
            subtitle: "Start a video recording using gPhoto2",
            buttonText: "Start recording",
            onPressed: controller.onStartVideoRecordingPressed,
          ),
          SettingsActionTile(
            icon: LucideIcons.videoOff,
            title: "Stop video recording",
            subtitle: "Stop a video recording using gPhoto2",
            buttonText: "Stop recording",
            onPressed: controller.onStopVideoRecordingPressed,
          ),
          SettingsActionTile(
            icon: LucideIcons.folder,
            title: "Get camera files",
            subtitle: "Retrieve a list of files on the camera",
            buttonText: "Get filelist",
            onPressed: controller.onGetCameraFilesPressed,
          ),
        ],
      ),
      SettingsSection(
        title: "Actions",
        settings: [
          SettingsActionTile(
            icon: LucideIcons.play,
            title: "Play audio sample",
            subtitle: "Play a sample mp3 file, to verify whether audio file playback is working. Please note that the User interface > Sound Effects > Enable Sound Effects setting needs to be enabled.",
            buttonText: "Audio test",
            onPressed: controller.onPlayAudioSamplePressed,
          ),
          SettingsActionTile(
            icon: LucideIcons.mailWarning,
            title: "Report fake error",
            subtitle: "Test whether error reporting (to Sentry) works",
            buttonText: "Report Fake Error",
            onPressed: () => throw Exception("This is a fake error to test error reporting"),
          ),
        ],
      ),
      SettingsSection(
        title: "Debug settings",
        settings: [
          SettingsToggleTile(
            icon: LucideIcons.monitorCog,
            title: "Show FPS count",
            subtitle: "Show the FPS count in the upper right corner.",
            value: () => viewModel.debugShowFpsCounter,
            onChanged: controller.onDebugShowFpsCounterChanged,
          ),
        ],
      ),
    ],
  );
}
