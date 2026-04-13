import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(
      android: android,
    );

    await _plugin.initialize(settings);
  }

  NotificationDetails get _details {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'oven_alerts_channel',
        'Oven Alerts',
        channelDescription: 'Notifications for oven tracking alerts',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );
  }

  Future<void> showMainAlert({
    required int id,
    required String ovenName,
    required String finishTime,
  }) async {
    await _plugin.show(
      id,
      'Oven Complete',
      '$ovenName finished at $finishTime',
      _details,
    );
  }

  Future<void> showSensorAlert({
    required int id,
    required String ovenName,
    required String sensorTime,
  }) async {
    await _plugin.show(
      id,
      'Sensor Check Needed',
      '$ovenName needs check at $sensorTime',
      _details,
    );
  }

  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}