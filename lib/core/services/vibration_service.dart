import 'package:vibration/vibration.dart';

class VibrationService {
  Future<void> vibrateBrief() async {
    final canVibrate = await Vibration.hasVibrator();
    if (!canVibrate) return;

    await Vibration.vibrate(duration: 500);
  }
}