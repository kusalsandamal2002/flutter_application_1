class IdUtils {
  static String sessionId(String ovenName) {
    return '${ovenName}_${DateTime.now().millisecondsSinceEpoch}';
  }

  static String stepId(String ovenName, int minuteOfDay) {
    return '${ovenName}_$minuteOfDay';
  }
}