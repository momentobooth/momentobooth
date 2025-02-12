import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/_all.dart';
import 'package:momento_booth/views/onboarding_screen/components/subsystem_status_display.dart';

class SubsystemStatusList extends StatelessWidget {

  const SubsystemStatusList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: [
        Observer(builder: (_) {
          return SubsystemStatusDisplay(title: "Window manager", status: getIt<WindowManager>().subsystemStatus);
        }),
        Observer(builder: (_) {
          return SubsystemStatusDisplay(title: "Settings", status: getIt<SettingsManager>().subsystemStatus);
        }),
        Observer(builder: (_) {
          return SubsystemStatusDisplay(title: "Statistics", status: getIt<StatsManager>().subsystemStatus);
        }),
        Observer(builder: (_) {
          return SubsystemStatusDisplay(title: "Projects", status: getIt<ProjectManager>().subsystemStatus);
        }),
        Observer(builder: (_) {
          return SubsystemStatusDisplay(title: "Live view", status: getIt<LiveViewManager>().subsystemStatus);
        }),
        Observer(builder: (_) {
          return SubsystemStatusDisplay(title: "MQTT", status: getIt<MqttManager>().subsystemStatus);
        }),
        Observer(builder: (_) {
          return SubsystemStatusDisplay(title: "Printing", status: getIt<PrintingManager>().subsystemStatus);
        }),
        Observer(builder: (_) {
          return SubsystemStatusDisplay(title: "Sounds", status: getIt<SfxManager>().subsystemStatus);
        }),
      ],
    );
  }

}
