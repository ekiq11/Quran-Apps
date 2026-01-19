// lib/services/prayer_time_service.dart - FIXED v2.0
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:myquran/model/prayer_time_model.dart';
import 'package:myquran/services/location_service.dart';
import 'package:myquran/notification/notification_manager.dart';  // ✅ CHANGED!

class PrayerTimeService {
  static final PrayerTimeService _instance = PrayerTimeService._internal();
  factory PrayerTimeService() => _instance;
  PrayerTimeService._internal();

  final LocationService _locationService = LocationService();
  final NotificationManager _notificationManager = NotificationManager();  // ✅ CHANGED!

  static const String _keyPrayerTimes = 'prayer_times_cache';
  static const Duration _cacheDuration = Duration(hours: 12);

  Future<PrayerTimeModel> calculatePrayerTimes({
    bool forceRefresh = false,
  }) async {
    try {
      // Check cache first
      if (!forceRefresh) {
        final cached = await _getCachedPrayerTimes();
        if (cached != null) {
          print('Using cached prayer times');
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
      
      final model = PrayerTimeModel(
        times: {
          'Subuh': TimeOfDay(
            hour: prayerTimes.fajr.hour,
            minute: prayerTimes.fajr.minute,
          ),
          'Terbit': TimeOfDay(
            hour: prayerTimes.sunrise.hour,
            minute: prayerTimes.sunrise.minute,
          ),
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

      // Cache the prayer times
      await _cachePrayerTimes(model);

      // ✅ SCHEDULE NOTIFICATIONS (only if user wants auto-schedule)
      // Don't auto-schedule here, let user control from settings
      // await _scheduleNotifications(model);

      return model;
    } catch (e) {
      print('Error calculating prayer times: $e');
      
      final cached = await _getCachedPrayerTimes(ignoreExpiry: true);
      if (cached != null) {
        print('Using expired cache due to error');
        return cached;
      }
      
      return PrayerTimeModel.fallback();
    }
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
          print('Prayer times cache expired (different day)');
          return null;
        }
        
        if (now.difference(model.lastUpdated) > _cacheDuration) {
          print('Prayer times cache expired (time limit)');
          return null;
        }
      }
      
      return model;
    } catch (e) {
      print('Error reading cached prayer times: $e');
      return null;
    }
  }

  Future<void> _cachePrayerTimes(PrayerTimeModel model) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(model.toJson());
      await prefs.setString(_keyPrayerTimes, jsonStr);
      print('Prayer times cached successfully');
    } catch (e) {
      print('Error caching prayer times: $e');
    }
  }

  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyPrayerTimes);
      print('Prayer times cache cleared');
    } catch (e) {
      print('Error clearing prayer times cache: $e');
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
      
      // Schedule using NotificationManager
      await _notificationManager.scheduleAllNotifications(
        prayerTimes: model.times,
        tilawahTimes: tilawahTimes,
      );
      
      print('✅ Notifications scheduled successfully');
    } catch (e) {
      print('❌ Error scheduling notifications: $e');
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

  Future<void> rescheduleNotifications() async {
    try {
      final model = await calculatePrayerTimes(forceRefresh: true);
      await scheduleNotificationsManually(model);
    } catch (e) {
      print('Error rescheduling notifications: $e');
    }
  }

  Future<PrayerTimeModel> getPrayerTimesForDate(DateTime date) async {
    try {
      final location = await _locationService.getCurrentLocation();
      final coordinates = Coordinates(location.latitude, location.longitude);
      final params = _getCalculationParameters(location.latitude, location.longitude);
      
      final dateComponents = DateComponents(date.year, date.month, date.day);
      final prayerTimes = PrayerTimes(coordinates, dateComponents, params);
      
      return PrayerTimeModel(
        times: {
          'Subuh': TimeOfDay(
            hour: prayerTimes.fajr.hour,
            minute: prayerTimes.fajr.minute,
          ),
          'Terbit': TimeOfDay(
            hour: prayerTimes.sunrise.hour,
            minute: prayerTimes.sunrise.minute,
          ),
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
      print('Error getting prayer times for date: $e');
      return PrayerTimeModel.fallback();
    }
  }
}