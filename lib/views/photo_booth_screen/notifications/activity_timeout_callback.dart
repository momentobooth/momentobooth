import 'dart:async';

import 'package:flutter/widgets.dart';

/// Notifcation for the [ActivityMonitor] to run the provided callback function, when a activity timeout occurs.
class ActivityTimeoutCallback extends Notification {

  final FutureOr<void> Function() onActivityTimeout;

  ActivityTimeoutCallback({required this.onActivityTimeout});

}
