// notification/notification_helpers.dart - TYPE-SAFE HELPERS

import 'package:flutter/material.dart';

/// Extension untuk Map agar null-safe
extension SafeMapAccess<K, V> on Map<K, V> {
  /// Get value dengan default jika null
  V getOrDefault(K key, V defaultValue) {
    return this[key] ?? defaultValue;
  }
  
  /// Get boolean value dengan default false
  bool getBoolOrFalse(K key) {
    final value = this[key];
    if (value is bool) return value;
    return false;
  }
  
  /// Get boolean value dengan default true
  bool getBoolOrTrue(K key) {
    final value = this[key];
    if (value is bool) return value;
    return true;
  }
}

/// Permission result wrapper
class PermissionResults {
  final bool notification;
  final bool exactAlarm;
  final bool fullScreen;
  final bool battery;
  
  const PermissionResults({
    required this.notification,
    this.exactAlarm = false,
    this.fullScreen = false,
    this.battery = false,
  });
  
  factory PermissionResults.fromMap(Map<String, bool> map) {
    return PermissionResults(
      notification: map['notification'] ?? false,
      exactAlarm: map['exactAlarm'] ?? false,
      fullScreen: map['fullScreen'] ?? false,
      battery: map['battery'] ?? false,
    );
  }
  
  bool get hasAllCritical => notification && exactAlarm;
  
  bool get hasAll => notification && exactAlarm && fullScreen && battery;
  
  @override
  String toString() {
    return 'PermissionResults(\n'
        '  notification: $notification,\n'
        '  exactAlarm: $exactAlarm,\n'
        '  fullScreen: $fullScreen,\n'
        '  battery: $battery\n'
        ')';
  }
}

/// Notification schedule result
class ScheduleResult {
  final int totalScheduled;
  final int pendingCount;
  final List<String> scheduledNotifications;
  final List<String> errors;
  
  const ScheduleResult({
    required this.totalScheduled,
    required this.pendingCount,
    this.scheduledNotifications = const [],
    this.errors = const [],
  });
  
  bool get isSuccess => errors.isEmpty && totalScheduled > 0;
  
  @override
  String toString() {
    return 'ScheduleResult(\n'
        '  scheduled: $totalScheduled,\n'
        '  pending: $pendingCount,\n'
        '  errors: ${errors.length}\n'
        ')';
  }
}

/// Notification type enum dengan helper methods
enum NotificationType {
  prayer('prayer', 'Sholat', 5),
  dzikir('dzikir', 'Dzikir', 6),
  tilawah('tilawah', 'Tilawah', 7),
  test('test', 'Test', 9);
  
  final String code;
  final String displayName;
  final int typeIndex;
  
  const NotificationType(this.code, this.displayName, this.typeIndex);
  
  static NotificationType fromCode(String code) {
    return NotificationType.values.firstWhere(
      (type) => type.code == code,
      orElse: () => NotificationType.test,
    );
  }
  
  static NotificationType fromIndex(int index) {
    return NotificationType.values.firstWhere(
      (type) => type.typeIndex == index,
      orElse: () => NotificationType.test,
    );
  }
}

/// Prayer name enum dengan helper methods
enum PrayerName {
  subuh('Subuh', 1001),
  dzuhur('Dzuhur', 1002),
  ashar('Ashar', 1003),
  maghrib('Maghrib', 1004),
  isya('Isya', 1005);
  
  final String name;
  final int notificationId;
  
  const PrayerName(this.name, this.notificationId);
  
  static PrayerName? fromName(String name) {
    try {
      return PrayerName.values.firstWhere(
        (prayer) => prayer.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }
  
  static PrayerName? fromId(int id) {
    try {
      return PrayerName.values.firstWhere(
        (prayer) => prayer.notificationId == id,
      );
    } catch (e) {
      return null;
    }
  }
  
  String get message {
    switch (this) {
      case PrayerName.subuh:
        return 'Sholat Subuh adalah cahaya hari ini';
      case PrayerName.dzuhur:
        return 'Luangkan waktu sejenak untuk sholat';
      case PrayerName.ashar:
        return 'Jangan lewatkan waktu yang mulia ini';
      case PrayerName.maghrib:
        return 'Akhiri hari dengan sholat yang khusyuk';
      case PrayerName.isya:
        return 'Tutup hari dengan ibadah';
    }
  }
}

/// Time formatting helper
class TimeFormatter {
  static String formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }
  
  static String formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month} '
           '${formatTime(dateTime)}';
  }
  
  static String formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
           '${time.minute.toString().padLeft(2, '0')}';
  }
  
  static String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) return 'Baru saja';
    if (difference.inMinutes < 60) return '${difference.inMinutes} menit lalu';
    if (difference.inHours < 24) return '${difference.inHours} jam yang lalu';
    if (difference.inDays == 1) return 'Kemarin';
    if (difference.inDays < 7) return '${difference.inDays} hari yang lalu';
    
    return formatDateTime(dateTime);
  }
}

/// Validation helpers
class NotificationValidator {
  static bool isValidTime(TimeOfDay time) {
    return time.hour >= 0 && time.hour < 24 && 
           time.minute >= 0 && time.minute < 60;
  }
  
  static bool isValidScheduleTime(DateTime scheduledTime) {
    final now = DateTime.now();
    // Must be in the future (at least 1 minute)
    return scheduledTime.isAfter(now.add(const Duration(minutes: 1)));
  }
  
  static bool isValidNotificationId(int id) {
    return id >= 1000 && id <= 9999;
  }
  
  static String? validateNotificationSettings({
    required Map<String, TimeOfDay> prayerTimes,
    required Map<String, TimeOfDay> tilawahTimes,
  }) {
    // Validate prayer times
    for (var entry in prayerTimes.entries) {
      if (!isValidTime(entry.value)) {
        return 'Waktu ${entry.key} tidak valid: ${TimeFormatter.formatTimeOfDay(entry.value)}';
      }
    }
    
    // Validate tilawah times
    for (var entry in tilawahTimes.entries) {
      if (!isValidTime(entry.value)) {
        return 'Waktu tilawah ${entry.key} tidak valid: ${TimeFormatter.formatTimeOfDay(entry.value)}';
      }
    }
    
    return null; // All valid
  }
}

/// Error handling helpers
class NotificationError {
  final String message;
  final String? details;
  final NotificationErrorType type;
  
  const NotificationError({
    required this.message,
    this.details,
    this.type = NotificationErrorType.unknown,
  });
  
  @override
  String toString() => details != null 
      ? '$message\nDetails: $details'
      : message;
}

enum NotificationErrorType {
  permissionDenied,
  scheduleFailed,
  invalidTime,
  channelError,
  unknown,
}