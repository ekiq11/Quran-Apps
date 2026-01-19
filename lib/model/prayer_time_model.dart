// model/prayer_time_model.dart
import 'package:flutter/material.dart';

class PrayerTimeModel {
  final Map<String, TimeOfDay> times;
  final String locationName;
  final double latitude;
  final double longitude;
  final DateTime lastUpdated;

  PrayerTimeModel({
    required this.times,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.lastUpdated,
  });

  // Get next prayer info
  NextPrayerInfo? getNextPrayer(DateTime now) {
    final currentMinutes = now.hour * 60 + now.minute;
    
    NextPrayerInfo? nextPrayer;
    int smallestDiff = 24 * 60; // Max difference in minutes

    times.forEach((name, time) {
      // Skip Terbit (bukan waktu sholat)
      if (name == 'Terbit') return;
      
      final prayerMinutes = time.hour * 60 + time.minute;
      int diff = prayerMinutes - currentMinutes;

      // If prayer time has passed today, calculate for tomorrow
      if (diff < 0) {
        diff += 24 * 60;
      }

      if (diff < smallestDiff) {
        smallestDiff = diff;
        nextPrayer = NextPrayerInfo(
          name: name,
          time: time,
          minutesUntil: diff,
        );
      }
    });

    return nextPrayer;
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'times': times.map((key, value) => MapEntry(
            key,
            {'hour': value.hour, 'minute': value.minute},
          )),
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  // Create from JSON
  factory PrayerTimeModel.fromJson(Map<String, dynamic> json) {
    final timesMap = <String, TimeOfDay>{};
    (json['times'] as Map<String, dynamic>).forEach((key, value) {
      timesMap[key] = TimeOfDay(
        hour: value['hour'],
        minute: value['minute'],
      );
    });

    return PrayerTimeModel(
      times: timesMap,
      locationName: json['locationName'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }

  // Fallback data (Jakarta)
  factory PrayerTimeModel.fallback() {
    return PrayerTimeModel(
      times: {
        'Subuh': TimeOfDay(hour: 4, minute: 30),
        'Terbit': TimeOfDay(hour: 5, minute: 50),
        'Dzuhur': TimeOfDay(hour: 12, minute: 0),
        'Ashar': TimeOfDay(hour: 15, minute: 15),
        'Maghrib': TimeOfDay(hour: 18, minute: 0),
        'Isya': TimeOfDay(hour: 19, minute: 15),
      },
      locationName: 'Jakarta (Default)',
      latitude: -6.2088,
      longitude: 106.8456,
      lastUpdated: DateTime.now(),
    );
  }
}

class NextPrayerInfo {
  final String name;
  final TimeOfDay time;
  final int minutesUntil;

  NextPrayerInfo({
    required this.name,
    required this.time,
    required this.minutesUntil,
  });

  // Get time as string (HH:mm)
  String get timeString {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // Alias for timeString (for backward compatibility)
  String get formattedTime => timeString;

  // Get remaining time as readable string
  String get remainingTime {
    if (minutesUntil < 1) {
      return 'Sekarang';
    } else if (minutesUntil < 60) {
      return '$minutesUntil menit lagi';
    } else {
      final hours = minutesUntil ~/ 60;
      final minutes = minutesUntil % 60;
      
      if (minutes == 0) {
        return '$hours jam lagi';
      } else {
        return '$hours jam $minutes menit lagi';
      }
    }
  }

  // Get short remaining time (for compact display)
  String get remainingTimeShort {
    if (minutesUntil < 1) {
      return 'Sekarang';
    } else if (minutesUntil < 60) {
      return '${minutesUntil}m';
    } else {
      final hours = minutesUntil ~/ 60;
      final minutes = minutesUntil % 60;
      
      if (minutes == 0) {
        return '${hours}j';
      } else {
        return '${hours}j ${minutes}m';
      }
    }
  }

  // Check if prayer time is soon (within 30 minutes)
  bool get isSoon {
    return minutesUntil <= 30;
  }

  // Check if prayer time is very soon (within 10 minutes)
  bool get isVerySoon {
    return minutesUntil <= 10;
  }

  // Get urgency level (for UI coloring)
  PrayerUrgency get urgency {
    if (minutesUntil <= 5) {
      return PrayerUrgency.critical; // Red/urgent
    } else if (minutesUntil <= 15) {
      return PrayerUrgency.high; // Orange/warning
    } else if (minutesUntil <= 30) {
      return PrayerUrgency.medium; // Yellow/notice
    } else {
      return PrayerUrgency.low; // Normal
    }
  }

  // Get duration as Duration object
  Duration get duration {
    return Duration(minutes: minutesUntil);
  }

  // Get hours until prayer
  int get hoursUntil {
    return minutesUntil ~/ 60;
  }

  // Get remaining minutes (after hours)
  int get remainingMinutes {
    return minutesUntil % 60;
  }
}

enum PrayerUrgency {
  low,      // > 30 minutes
  medium,   // 15-30 minutes
  high,     // 5-15 minutes
  critical, // < 5 minutes
}