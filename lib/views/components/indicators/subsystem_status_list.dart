import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/models/subsystem.dart';
import 'package:momento_booth/views/components/indicators/subsystem_status_display.dart';

class SubsystemStatusList extends StatelessWidget {

  const SubsystemStatusList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: getIt<ObservableList<Subsystem>>().map((s) {
        return Observer(builder: (_) {
           return SubsystemStatusDisplay(title: s.subsystemName, status: s.subsystemStatus);
         });
      }).toList(),
    );
  }

}
