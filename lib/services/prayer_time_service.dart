// lib/services/prayer_time_service.dart - ENHANCED v4.0
// ✅ Added: Imsak, Syuruk, and Duha times
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:myquran/model/prayer_time_model.dart';
import 'package:myquran/services/location_service.dart';
import 'package:myquran/notification/notification_manager.dart';

class PrayerTimeService {
  static final PrayerTimeService _instance = PrayerTimeService._internal();
  factory PrayerTimeService() => _instance;
  PrayerTimeService._internal();

  final LocationService _locationService = LocationService();
  final NotificationManager _notificationManager = NotificationManager();

  static const String _keyPrayerTimes = 'prayer_times_cache';
  static const Duration _cacheDuration = Duration(hours: 12);

  Future<PrayerTimeModel> calculatePrayerTimes({
    bool forceRefresh = false,
    bool autoSchedule = true,
  }) async {
    try {
      // Check cache first
      if (!forceRefresh) {
        final cached = await _getCachedPrayerTimes();
        if (cached != null) {
          print('📦 Using cached prayer times');
          return cached;
        }
      }

      // Get location
      final location = await _locationService.getCurrentLocation(
        forceRefresh: forceRefresh,
      );

      // Calculate prayer times
      final coordinates = Coordinates(location.latitude, location.longitude);
      final params = _getCalculationParameters(location.latitude, location.longitude);
      final prayerTimes = PrayerTimes.today(coordinates, params);
      
      // Calculate Imsak (10 minutes before Fajr)
      final imsakTime = _subtractMinutes(
        TimeOfDay(hour: prayerTimes.fajr.hour, minute: prayerTimes.fajr.minute),
        10,
      );
      
      // Get Subuh and Syuruk times
      final subuhTime = TimeOfDay(
        hour: prayerTimes.fajr.hour,
        minute: prayerTimes.fajr.minute,
      );
      
      final syurukTime = TimeOfDay(
        hour: prayerTimes.sunrise.hour,
        minute: prayerTimes.sunrise.minute,
      );
      
      // Calculate Duha time (Syuruk + 1/3 of (Syuruk - Subuh))
      final duhaTime = _calculateDuhaTime(subuhTime, syurukTime);
      
      final model = PrayerTimeModel(
        times: {
          'Imsak': imsakTime,
          'Subuh': subuhTime,
          'Syuruk': syurukTime,
          'Duha': duhaTime,
          'Dzuhur': TimeOfDay(
            hour: prayerTimes.dhuhr.hour,
            minute: prayerTimes.dhuhr.minute,
          ),
          'Ashar': TimeOfDay(
            hour: prayerTimes.asr.hour,
            minute: prayerTimes.asr.minute,
          ),
          'Maghrib': TimeOfDay(
            hour: prayerTimes.maghrib.hour,
            minute: prayerTimes.maghrib.minute,
          ),
          'Isya': TimeOfDay(
            hour: prayerTimes.isha.hour,
            minute: prayerTimes.isha.minute,
          ),
        },
        locationName: location.locationName,
        latitude: location.latitude,
        longitude: location.longitude,
        lastUpdated: DateTime.now(),
      );

      // ✅ CRITICAL: Cache the prayer times
      await _cachePrayerTimes(model);

      // ✅ CRITICAL: Save to SharedPreferences (for background access)
      await _savePrayerTimesToPrefs(model.times);

      // ✅ CRITICAL: Auto-schedule notifications if enabled
      if (autoSchedule) {
        try {
          await _autoScheduleNotifications(model.times);
        } catch (e) {
          print('⚠️ Auto-schedule failed: $e (continuing anyway)');
        }
      }

      return model;
    } catch (e) {
      print('❌ Error calculating prayer times: $e');
      
      final cached = await _getCachedPrayerTimes(ignoreExpiry: true);
      if (cached != null) {
        print('📦 Using expired cache due to error');
        return cached;
      }
      
      return PrayerTimeModel.fallback();
    }
  }

  // ✅ Calculate Duha time using astronomical formula
  // Formula: Syuruk + 1/3 × (Syuruk - Subuh)
  TimeOfDay _calculateDuhaTime(TimeOfDay subuh, TimeOfDay syuruk) {
    // Convert to minutes
    final subuhMinutes = subuh.hour * 60 + subuh.minute;
    final syurukMinutes = syuruk.hour * 60 + syuruk.minute;
    
    // Calculate difference
    final difference = syurukMinutes - subuhMinutes;
    
    // Add 1/3 of difference to Syuruk time
    final oneThirdDiff = (difference / 3).round();
    final duhaMinutes = syurukMinutes + oneThirdDiff;
    
    return TimeOfDay(
      hour: (duhaMinutes ~/ 60) % 24,
      minute: duhaMinutes % 60,
    );
  }

  CalculationParameters _getCalculationParameters(double latitude, double longitude) {
    // Indonesia
    if (latitude >= -11 && latitude <= 6 && longitude >= 95 && longitude <= 141) {
      final params = CalculationMethod.singapore.getParameters();
      params.madhab = Madhab.shafi;
      params.fajrAngle = 20.0;
      params.ishaAngle = 18.0;
      params.highLatitudeRule = HighLatitudeRule.twilight_angle;
      return params;
    }
    
    // Malaysia & Singapore
    if (latitude >= 0.5 && latitude <= 7.5 && longitude >= 99 && longitude <= 120) {
      final params = CalculationMethod.singapore.getParameters();
      params.madhab = Madhab.shafi;
      params.highLatitudeRule = HighLatitudeRule.twilight_angle;
      return params;
    }
    
    // Middle East
    if (latitude >= 12 && latitude <= 42 && longitude >= 34 && longitude <= 63) {
      final params = CalculationMethod.umm_al_qura.getParameters();
      params.madhab = Madhab.shafi;
      return params;
    }
    
    // Egypt & North Africa
    if (latitude >= 20 && latitude <= 32 && longitude >= -17 && longitude <= 35) {
      final params = CalculationMethod.egyptian.getParameters();
      params.madhab = Madhab.shafi;
      return params;
    }
    
    // Default
    final params = CalculationMethod.muslim_world_league.getParameters();
    params.madhab = Madhab.shafi;
    params.highLatitudeRule = HighLatitudeRule.twilight_angle;
    return params;
  }

  // ✅ CRITICAL: Save prayer times to SharedPreferences
  Future<void> _savePrayerTimesToPrefs(Map<String, TimeOfDay> times) async {
    try {
      print('💾 Saving prayer times to SharedPreferences...');
      
      final prefs = await SharedPreferences.getInstance();
      
      // Save each prayer time
      for (var entry in times.entries) {
        final prayerName = entry.key.toLowerCase();
        final time = entry.value;
        
        await prefs.setInt('prayer_${prayerName}_hour', time.hour);
        await prefs.setInt('prayer_${prayerName}_minute', time.minute);
        
        print('   ✅ $prayerName: ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
      }
      
      // Save timestamp
      await prefs.setInt('prayer_times_last_updated', DateTime.now().millisecondsSinceEpoch);
      
      print('✅ Prayer times saved to SharedPreferences');
      
    } catch (e) {
      print('❌ Error saving prayer times to prefs: $e');
    }
  }

  // ✅ CRITICAL: Auto-schedule notifications
  Future<void> _autoScheduleNotifications(Map<String, TimeOfDay> prayerTimes) async {
    try {
      print('');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📅 AUTO-SCHEDULING NOTIFICATIONS');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      final prefs = await SharedPreferences.getInstance();
      
      // Get tilawah times
      final tilawahTimes = {
        'Pagi': TimeOfDay(
          hour: prefs.getInt('tilawah_pagi_hour') ?? 6,
          minute: prefs.getInt('tilawah_pagi_minute') ?? 0,
        ),
        'Siang': TimeOfDay(
          hour: prefs.getInt('tilawah_siang_hour') ?? 13,
          minute: prefs.getInt('tilawah_siang_minute') ?? 0,
        ),
        'Malam': TimeOfDay(
          hour: prefs.getInt('tilawah_malam_hour') ?? 20,
          minute: prefs.getInt('tilawah_malam_minute') ?? 0,
        ),
      };
      
      // Get doa times (based on prayer times)
      final doaTimes = {
        'Pagi': _addMinutes(prayerTimes['Subuh'] ?? const TimeOfDay(hour: 5, minute: 0), 15),
        'Petang': _addMinutes(prayerTimes['Maghrib'] ?? const TimeOfDay(hour: 18, minute: 0), 10),
      };
      
      // Schedule using NotificationManager
      await _notificationManager.scheduleAllNotifications(
        prayerTimes: prayerTimes,
        tilawahTimes: tilawahTimes,
        doaTimes: doaTimes,
      );
      
      // Save last schedule time
      await prefs.setInt('last_notification_schedule', DateTime.now().millisecondsSinceEpoch);
      
      print('✅ Notifications auto-scheduled successfully!');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('');
      
    } catch (e, stack) {
      print('❌ Error auto-scheduling notifications: $e');
      print('Stack: $stack');
      rethrow;
    }
  }

  Future<PrayerTimeModel?> _getCachedPrayerTimes({bool ignoreExpiry = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_keyPrayerTimes);
      
      if (jsonStr == null) return null;
      
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final model = PrayerTimeModel.fromJson(json);
      
      if (!ignoreExpiry) {
        final now = DateTime.now();
        
        if (model.lastUpdated.day != now.day || 
            model.lastUpdated.month != now.month ||
            model.lastUpdated.year != now.year) {
          print('📦 Prayer times cache expired (different day)');
          return null;
        }
        
        if (now.difference(model.lastUpdated) > _cacheDuration) {
          print('📦 Prayer times cache expired (time limit)');
          return null;
        }
      }
      
      return model;
    } catch (e) {
      print('❌ Error reading cached prayer times: $e');
      return null;
    }
  }

  Future<void> _cachePrayerTimes(PrayerTimeModel model) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(model.toJson());
      await prefs.setString(_keyPrayerTimes, jsonStr);
      print('✅ Prayer times cached successfully');
    } catch (e) {
      print('❌ Error caching prayer times: $e');
    }
  }

  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyPrayerTimes);
      print('✅ Prayer times cache cleared');
    } catch (e) {
      print('❌ Error clearing prayer times cache: $e');
    }
  }

  // ✅ MANUAL SCHEDULE - Called from notification settings page
  Future<void> scheduleNotificationsManually(PrayerTimeModel model) async {
    try {
      print('📅 Manually scheduling notifications from prayer times...');
      
      // Get user preferences for tilawah times
      final prefs = await SharedPreferences.getInstance();
      final tilawahTimes = {
        'Pagi': _parseTime(prefs.getString('tilawah_time_pagi') ?? '6:0'),
        'Siang': _parseTime(prefs.getString('tilawah_time_siang') ?? '13:0'),
        'Malam': _parseTime(prefs.getString('tilawah_time_malam') ?? '20:0'),
      };
      
      // Get doa times
      final doaTimes = {
        'Pagi': _addMinutes(model.times['Subuh'] ?? const TimeOfDay(hour: 5, minute: 0), 15),
        'Petang': _addMinutes(model.times['Maghrib'] ?? const TimeOfDay(hour: 18, minute: 0), 10),
      };
      
      // Schedule using NotificationManager
      await _notificationManager.scheduleAllNotifications(
        prayerTimes: model.times,
        tilawahTimes: tilawahTimes,
        doaTimes: doaTimes,
      );
      
      // Save to SharedPreferences
      await _savePrayerTimesToPrefs(model.times);
      
      print('✅ Notifications scheduled manually');
    } catch (e) {
      print('❌ Error scheduling notifications manually: $e');
      rethrow;
    }
  }

  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  TimeOfDay _addMinutes(TimeOfDay time, int minutes) {
    final totalMinutes = time.hour * 60 + time.minute + minutes;
    return TimeOfDay(
      hour: (totalMinutes ~/ 60) % 24,
      minute: totalMinutes % 60,
    );
  }

  TimeOfDay _subtractMinutes(TimeOfDay time, int minutes) {
    final totalMinutes = time.hour * 60 + time.minute - minutes;
    // Handle negative values (previous day)
    final adjustedMinutes = totalMinutes < 0 ? totalMinutes + (24 * 60) : totalMinutes;
    return TimeOfDay(
      hour: (adjustedMinutes ~/ 60) % 24,
      minute: adjustedMinutes % 60,
    );
  }

  Future<void> rescheduleNotifications() async {
    try {
      print('🔄 Rescheduling notifications...');
      final model = await calculatePrayerTimes(forceRefresh: true, autoSchedule: true);
      print('✅ Notifications rescheduled with latest prayer times');
    } catch (e) {
      print('❌ Error rescheduling notifications: $e');
    }
  }

  Future<PrayerTimeModel> getPrayerTimesForDate(DateTime date) async {
    try {
      final location = await _locationService.getCurrentLocation();
      final coordinates = Coordinates(location.latitude, location.longitude);
      final params = _getCalculationParameters(location.latitude, location.longitude);
      
      final dateComponents = DateComponents(date.year, date.month, date.day);
      final prayerTimes = PrayerTimes(coordinates, dateComponents, params);
      
      // Calculate Imsak
      final imsakTime = _subtractMinutes(
        TimeOfDay(hour: prayerTimes.fajr.hour, minute: prayerTimes.fajr.minute),
        10,
      );
      
      // Get Subuh and Syuruk
      final subuhTime = TimeOfDay(
        hour: prayerTimes.fajr.hour,
        minute: prayerTimes.fajr.minute,
      );
      
      final syurukTime = TimeOfDay(
        hour: prayerTimes.sunrise.hour,
        minute: prayerTimes.sunrise.minute,
      );
      
      // Calculate Duha
      final duhaTime = _calculateDuhaTime(subuhTime, syurukTime);
      
      return PrayerTimeModel(
        times: {
          'Imsak': imsakTime,
          'Subuh': subuhTime,
          'Syuruk': syurukTime,
          'Duha': duhaTime,
          'Dzuhur': TimeOfDay(
            hour: prayerTimes.dhuhr.hour,
            minute: prayerTimes.dhuhr.minute,
          ),
          'Ashar': TimeOfDay(
            hour: prayerTimes.asr.hour,
            minute: prayerTimes.asr.minute,
          ),
          'Maghrib': TimeOfDay(
            hour: prayerTimes.maghrib.hour,
            minute: prayerTimes.maghrib.minute,
          ),
          'Isya': TimeOfDay(
            hour: prayerTimes.isha.hour,
            minute: prayerTimes.isha.minute,
          ),
        },
        locationName: location.locationName,
        latitude: location.latitude,
        longitude: location.longitude,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      print('❌ Error getting prayer times for date: $e');
      return PrayerTimeModel.fallback();
    }
  }
  
  // ✅ Load prayer times from SharedPreferences
  Future<Map<String, TimeOfDay>> loadSavedPrayerTimes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final times = <String, TimeOfDay>{};
      
      final prayers = ['Imsak', 'Subuh', 'Syuruk', 'Duha', 'Dzuhur', 'Ashar', 'Maghrib', 'Isya'];
      
      for (final prayer in prayers) {
        final hourKey = 'prayer_${prayer.toLowerCase()}_hour';
        final minuteKey = 'prayer_${prayer.toLowerCase()}_minute';
        
        final hour = prefs.getInt(hourKey);
        final minute = prefs.getInt(minuteKey);
        
        if (hour != null && minute != null) {
          times[prayer] = TimeOfDay(hour: hour, minute: minute);
        }
      }
      
      if (times.isNotEmpty) {
        print('✅ Loaded ${times.length} prayer times from storage');
      } else {
        print('⚠️ No prayer times found in storage');
      }
      
      return times;
      
    } catch (e) {
      print('❌ Error loading saved prayer times: $e');
      return {};
    }
  }
}