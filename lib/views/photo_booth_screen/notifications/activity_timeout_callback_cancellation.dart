import 'dart:async';

import 'package:flutter/widgets.dart';

/// Notifcation for the [ActivityMonitor] to cancel the earlier requested run of the provided callback function.
class ActivityTimeoutCallbackCancellation extends Notification {

  final FutureOr<void> Function() onActivityTimeout;

  ActivityTimeoutCallbackCancellation({required this.onActivityTimeout});

}
