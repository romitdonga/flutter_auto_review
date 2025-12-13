enum TriggerType { appOpen, customEvent, screenTransition, appExit, manual }

extension TriggerTypeExtension on TriggerType {
  String get analyticsName {
    switch (this) {
      case TriggerType.appOpen:
        return 'app_open';
      case TriggerType.customEvent:
        return 'custom_event';
      case TriggerType.screenTransition:
        return 'screen_transition';
      case TriggerType.appExit:
        return 'app_exit';
      case TriggerType.manual:
        return 'manual';
    }
  }
}
