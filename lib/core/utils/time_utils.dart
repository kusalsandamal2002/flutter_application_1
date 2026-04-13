import 'package:flutter/material.dart';

class TimeUtils {
  static int minuteOfDayFromTimeOfDay(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  static String format12Hour(
    int hour,
    int minute, {
    bool withSeconds = false,
    int second = 0,
  }) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final normalizedHour = hour % 12 == 0 ? 12 : hour % 12;
    final mm = minute.toString().padLeft(2, '0');

    if (withSeconds) {
      final ss = second.toString().padLeft(2, '0');
      return '$normalizedHour:$mm:$ss $period';
    }

    return '$normalizedHour:$mm $period';
  }

  static String formatTimeOfDay(TimeOfDay time) {
    return format12Hour(time.hour, time.minute);
  }

  static TimeOfDay addDurationToTime(
    TimeOfDay start,
    int addHours,
    int addMinutes,
  ) {
    final totalMinutes = start.hour * 60 + start.minute + (addHours * 60) + addMinutes;
    final normalized = totalMinutes % (24 * 60);
    return TimeOfDay(
      hour: normalized ~/ 60,
      minute: normalized % 60,
    );
  }
}