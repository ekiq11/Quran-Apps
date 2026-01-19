// provider/dashboard_provider.dart - MIGRATED TO NotificationManager
// ✅ CLEAN VERSION - NO ADZAN REFERENCES

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:myquran/model/prayer_time_model.dart';
import 'package:myquran/notification/notification_manager.dart'; // ✅ CHANGED
import 'dart:async';

import '../services/prayer_time_service.dart';
import '../services/location_service.dart';
import '../quran/service/quran_service.dart';
import '../quran/model/surah_model.dart';

class DashboardProvider extends ChangeNotifier {
  final PrayerTimeService _prayerTimeService = PrayerTimeService();
  final LocationService _locationService = LocationService();
  final QuranService _quranService = QuranService();
  final NotificationManager _notificationManager = NotificationManager(); // ✅ CHANGED

  // State
  PrayerTimeModel? _prayerTimeModel;
  BookmarkModel? _lastRead;
  LocationData? _locationData;
  String _currentTime = '';
  String _currentDate = '';
  bool _isLoadingPrayerTimes = true;
  bool _isLoadingLastRead = true;
  bool _isLoadingLocation = true;
  bool _notificationsInitialized = false;
  String _errorMessage = '';
  
  DateTime? _lastReadUpdateTime;
  DateTime? _prayerTimesUpdateTime;

  // Timers
  Timer? _clockTimer;
  Timer? _lastReadRefreshTimer;
  Timer? _prayerTimeUpdateTimer;
  Timer? _midnightCheckTimer;

  // Getters
  PrayerTimeModel? get prayerTimeModel => _prayerTimeModel;
  BookmarkModel? get lastRead => _lastRead;
  LocationData? get locationData => _locationData;
  String get currentTime => _currentTime;
  String get currentDate => _currentDate;
  bool get isLoadingPrayerTimes => _isLoadingPrayerTimes;
  bool get isLoadingLastRead => _isLoadingLastRead;
  bool get isLoadingLocation => _isLoadingLocation;
  bool get notificationsInitialized => _notificationsInitialized;
  String get errorMessage => _errorMessage;
  bool get hasError => _errorMessage.isNotEmpty;

  NextPrayerInfo? get nextPrayerInfo {
    if (_prayerTimeModel == null) return null;
    return _prayerTimeModel!.getNextPrayer(DateTime.now());
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // INITIALIZATION
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  Future<void> initialize() async {
    print('🚀 Initializing Dashboard...');
    
    await _initializeDateFormatting();
    _startClock();
    _startAutoRefreshTimers();
    _startMidnightCheck();
    
    await Future.wait([
      loadLocation(),
      initializeNotifications(),
    ]);
    
    await loadPrayerTimes();
    await loadLastRead();
    
    print('✅ Dashboard initialized');
  }

  Future<void> _initializeDateFormatting() async {
    try {
      await initializeDateFormatting('id_ID', null);
    } catch (e) {
      print('⚠️ Date formatting error: $e');
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // NOTIFICATION INITIALIZATION - UPDATED
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  Future<void> initializeNotifications() async {
    if (_notificationsInitialized) {
      print('ℹ️ Notifications already initialized');
      return;
    }
    
    try {
      print('🔔 Initializing notifications...');
      
      // ✅ UPDATED: Use NotificationManager's requestPermissions instead
      final permissions = await _notificationManager.requestPermissions();
      final hasPermission = permissions['notification'] == true;
      
      if (!hasPermission) {
        print('⚠️ No notification permission');
        _notificationsInitialized = false;
        return;
      }
      
      _notificationsInitialized = true;
      print('✅ Notifications initialized');
      print('   Exact Alarm: ${permissions['exactAlarm'] == true ? '✅' : '❌'}');
      
      notifyListeners();
    } catch (e) {
      print('❌ Notification init error: $e');
      _notificationsInitialized = false;
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // TIMERS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  void _startClock() {
    _updateTime();
    _clockTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      _updateTime();
    });
  }

  void _startMidnightCheck() {
    _midnightCheckTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      final now = DateTime.now();
      
      // At midnight, refresh prayer times
      if (now.hour == 0 && now.minute <= 5) {
        if (_prayerTimesUpdateTime == null || 
            !_isSameDay(_prayerTimesUpdateTime!, now)) {
          print('🕐 Midnight - refreshing prayer times...');
          loadPrayerTimes(forceRefresh: true);
        }
      }
    });
  }

  void _startAutoRefreshTimers() {
    // Refresh last read every 15 seconds
    _lastReadRefreshTimer = Timer.periodic(
      Duration(seconds: 15),
      (_) {
        if (_shouldRefreshLastRead()) {
          loadLastRead(silent: true);
        }
      },
    );

    // Update prayer info every 30 seconds (UI only)
    _prayerTimeUpdateTimer = Timer.periodic(
      Duration(seconds: 30),
      (_) {
        if (_prayerTimeModel != null) {
          final now = DateTime.now();
          if (_prayerTimesUpdateTime != null && 
              !_isSameDay(_prayerTimesUpdateTime!, now)) {
            print('📅 New day detected - refreshing prayer times...');
            loadPrayerTimes(forceRefresh: true);
          } else {
            notifyListeners(); // Just update UI
          }
        }
      },
    );
  }

  bool _shouldRefreshLastRead() {
    if (_lastReadUpdateTime == null) return true;
    final difference = DateTime.now().difference(_lastReadUpdateTime!);
    return difference.inSeconds > 10;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
          date1.month == date2.month &&
          date1.day == date2.day;
  }

  void _updateTime() {
    final now = DateTime.now();
    _currentTime = DateFormat('HH:mm:ss').format(now);
    try {
      _currentDate = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(now);
    } catch (e) {
      _currentDate = DateFormat('EEEE, dd MMMM yyyy').format(now);
    }
    notifyListeners();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // DATA LOADING
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  Future<void> loadLocation({bool forceRefresh = false}) async {
    try {
      _isLoadingLocation = true;
      notifyListeners();

      _locationData = await _locationService.getCurrentLocation(
        forceRefresh: forceRefresh,
      );

      _isLoadingLocation = false;
      notifyListeners();
    } catch (e) {
      print('❌ Location error: $e');
      _isLoadingLocation = false;
      
      _locationData = LocationData(
        latitude: -6.2088,
        longitude: 106.8456,
        locationName: 'Jakarta (Default)',
        timestamp: DateTime.now(),
      );
      notifyListeners();
    }
  }

  Future<void> loadPrayerTimes({bool forceRefresh = false}) async {
    try {
      _isLoadingPrayerTimes = true;
      _errorMessage = '';
      notifyListeners();

      _prayerTimeModel = await _prayerTimeService.calculatePrayerTimes(
        forceRefresh: forceRefresh,
      );

      _prayerTimesUpdateTime = DateTime.now();
      _isLoadingPrayerTimes = false;
      notifyListeners();
      
      print('✅ Prayer times loaded');
      
    } catch (e) {
      print('❌ Prayer times error: $e');
      _errorMessage = 'Gagal memuat waktu sholat';
      _isLoadingPrayerTimes = false;
      
      _prayerTimeModel = PrayerTimeModel.fallback();
      notifyListeners();
    }
  }

  Future<void> loadLastRead({bool silent = false}) async {
    try {
      if (!silent) {
        _isLoadingLastRead = true;
        notifyListeners();
      }

      final lastReadData = await _quranService.getLastRead();
      
      if (_hasLastReadChanged(lastReadData)) {
        _lastRead = lastReadData;
        _lastReadUpdateTime = DateTime.now();
        
        if (!silent) {
          print('✅ Last read: ${_lastRead?.surahName ?? "None"}');
        }
      }

      _isLoadingLastRead = false;
      notifyListeners();
    } catch (e) {
      print('❌ Last read error: $e');
      _isLoadingLastRead = false;
      _lastRead = null;
      notifyListeners();
    }
  }

  bool _hasLastReadChanged(BookmarkModel? newData) {
    if (_lastRead == null && newData == null) return false;
    if (_lastRead == null || newData == null) return true;
    
    return _lastRead!.surahNumber != newData.surahNumber ||
          _lastRead!.ayahNumber != newData.ayahNumber ||
          _lastRead!.lastRead != newData.lastRead;
  }

  Future<void> forceRefreshLastRead() async {
    print('🔄 Force refresh last read...');
    _lastReadUpdateTime = null;
    await loadLastRead(silent: false);
  }

  Future<void> smartRefresh() async {
    final futures = <Future>[];
    
    futures.add(loadLastRead(silent: false));
    
    if (_prayerTimesUpdateTime == null || 
        !_isSameDay(_prayerTimesUpdateTime!, DateTime.now())) {
      futures.add(loadPrayerTimes(forceRefresh: true));
    }
    
    await Future.wait(futures);
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // PULL-TO-REFRESH
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  Future<void> refreshAll() async {
    print('🔄 Pull-to-refresh...');
    
    try {
      await Future.wait([
        loadLocation(forceRefresh: true),
        loadPrayerTimes(forceRefresh: true),
        loadLastRead(silent: false),
      ]);
      
      print('✅ Refresh complete');
      
    } catch (e) {
      print('❌ Refresh error: $e');
    }
  }

  Future<void> clearCaches() async {
    print('🗑️ Clearing caches...');
    
    await _prayerTimeService.clearCache();
    await _locationService.clearCache();
    _lastReadUpdateTime = null;
    _prayerTimesUpdateTime = null;
    
    await loadLocation(forceRefresh: true);
    await loadPrayerTimes(forceRefresh: true);
    await loadLastRead(silent: false);
    
    print('✅ Caches cleared');
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // HELPERS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  Future<bool> requestLocationPermission() async {
    return await _locationService.requestLocationPermission();
  }

  Future<bool> hasLocationPermission() async {
    return await _locationService.hasLocationPermission();
  }

  String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} tahun lalu';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} bulan lalu';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit lalu';
    } else {
      return 'Baru saja';
    }
  }

  String getLastReadFreshness() {
    if (_lastReadUpdateTime == null) return 'Belum dimuat';
    final diff = DateTime.now().difference(_lastReadUpdateTime!);
    if (diff.inSeconds < 30) return 'Terbaru';
    if (diff.inMinutes < 5) return 'Baru saja';
    return getTimeAgo(_lastReadUpdateTime!);
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _lastReadRefreshTimer?.cancel();
    _prayerTimeUpdateTimer?.cancel();
    _midnightCheckTimer?.cancel();
    super.dispose();
  }
}