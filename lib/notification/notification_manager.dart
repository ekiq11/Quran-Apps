
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:myquran/notification/notification_service.dart';
import 'package:myquran/quran/service/quran_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final QuranService _quranService = QuranService();
  final Random _random = Random();
  
  bool _isInitialized = false;
  tz.Location? _userLocation;
  Timer? _midnightRescheduleTimer;
  
  // ✅ INTELLIGENCE DATA
  static const String _keyPrayerStats = 'prayer_statistics';
  static const String _keyLastPrayerTime = 'last_prayer_time';
  static const String _keyConsecutiveDays = 'consecutive_prayer_days';
  
  static Function(BuildContext context, String type, Map<String, dynamic> data)? onNotificationTappedWithContext;
  static Function(String type, Map<String, dynamic> data)? onNotificationTapped;
  
  static const String _channelPrayer = 'prayer_critical_v9';
  static const String _channelDzikir = 'dzikir_critical_v9';
  static const String _channelTilawah = 'tilawah_critical_v9';
  static const String _channelDoa = 'doa_critical_v9';
  
  static const String _keyNotificationHistory = 'notification_history_v3';
  static const String _keyReadNotifications = 'read_notifications_v2';
  static const String _keyBadgeCount = 'notification_badge_count';
  
  static const Map<String, int> _notifIds = {
    'Subuh': 1001, 'Dzuhur': 1002, 'Ashar': 1003, 'Maghrib': 1004, 'Isya': 1005,
    'DzikirPagi': 2001, 'DzikirPetang': 2002,
    'TilawahPagi': 3001, 'TilawahSiang': 3002, 'TilawahMalam': 3003,
    'DoaPagi': 4001, 'DoaPetang': 4002,
  };

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🧠 INTELLIGENT PRAYER WINDOW DETECTION
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  /// Detect which prayer window we're currently in
  String getCurrentPrayerWindow(Map<String, TimeOfDay> prayerTimes) {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    
    final subuh = prayerTimes['Subuh'];
    final dzuhur = prayerTimes['Dzuhur'];
    final ashar = prayerTimes['Ashar'];
    final maghrib = prayerTimes['Maghrib'];
    final isya = prayerTimes['Isya'];
    
    if (subuh != null && dzuhur != null) {
      final subuhMin = subuh.hour * 60 + subuh.minute;
      final dzuhurMin = dzuhur.hour * 60 + dzuhur.minute;
      
      if (currentMinutes >= subuhMin && currentMinutes < dzuhurMin) {
        final remaining = dzuhurMin - currentMinutes;
        return remaining < 30 ? 'Subuh (akan berakhir $remaining menit lagi)' : 'Subuh';
      }
    }
    
    if (dzuhur != null && ashar != null) {
      final dzuhurMin = dzuhur.hour * 60 + dzuhur.minute;
      final asharMin = ashar.hour * 60 + ashar.minute;
      
      if (currentMinutes >= dzuhurMin && currentMinutes < asharMin) {
        final remaining = asharMin - currentMinutes;
        return remaining < 30 ? 'Dzuhur (akan berakhir $remaining menit lagi)' : 'Dzuhur';
      }
    }
    
    if (ashar != null && maghrib != null) {
      final asharMin = ashar.hour * 60 + ashar.minute;
      final maghribMin = maghrib.hour * 60 + maghrib.minute;
      
      if (currentMinutes >= asharMin && currentMinutes < maghribMin) {
        final remaining = maghribMin - currentMinutes;
        return remaining < 30 ? 'Ashar (akan berakhir $remaining menit lagi)' : 'Ashar';
      }
    }
    
    if (maghrib != null && isya != null) {
      final maghribMin = maghrib.hour * 60 + maghrib.minute;
      final isyaMin = isya.hour * 60 + isya.minute;
      
      if (currentMinutes >= maghribMin && currentMinutes < isyaMin) {
        return 'Maghrib';
      }
    }
    
    if (isya != null) {
      final isyaMin = isya.hour * 60 + isya.minute;
      if (currentMinutes >= isyaMin || (subuh != null && currentMinutes < subuh.hour * 60 + subuh.minute)) {
        return 'Isya';
      }
    }
    
    return 'Tidak ada waktu sholat aktif';
  }
  
  /// Get next prayer time
  Map<String, dynamic>? getNextPrayer(Map<String, TimeOfDay> prayerTimes) {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    
    final prayers = ['Subuh', 'Dzuhur', 'Ashar', 'Maghrib', 'Isya'];
    
    for (var prayer in prayers) {
      final time = prayerTimes[prayer];
      if (time != null) {
        final prayerMinutes = time.hour * 60 + time.minute;
        if (prayerMinutes > currentMinutes) {
          final remaining = prayerMinutes - currentMinutes;
          return {
            'name': prayer,
            'time': time,
            'minutesRemaining': remaining,
            'isUrgent': remaining < 30,
            'isVerySoon': remaining < 10,
          };
        }
      }
    }
    
    // If no prayer found, next is tomorrow's Subuh
    final subuh = prayerTimes['Subuh'];
    if (subuh != null) {
      final subuhMin = subuh.hour * 60 + subuh.minute;
      final remaining = (24 * 60) - currentMinutes + subuhMin;
      return {
        'name': 'Subuh',
        'time': subuh,
        'minutesRemaining': remaining,
        'isTomorrow': true,
      };
    }
    
    return null;
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 💬 CONTEXT-AWARE MOTIVATIONAL QUOTES
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  // 🕌 PRAYER MOTIVATIONAL QUOTES (50 quotes)
  static final List<String> _prayerMotivationalQuotes = [
    'Sholat adalah tiang agama, jangan sampai roboh',
    'Sesungguhnya sholat mencegah dari perbuatan keji dan mungkar',
    'Sholat adalah cahaya yang menerangi kehidupan',
    'Dengan sholat, hati menjadi tenang dan damai',
    'Sholat adalah dialog langsung dengan Sang Pencipta',
    'Jangan tunda sholat, karena ajal tidak mengenal waktu',
    'Sholat adalah bentuk syukur terbesar kepada Allah',
    'Orang yang menjaga sholatnya, maka Allah menjaga kehidupannya',
    'Sholat adalah bekal terbaik untuk menghadapi hari',
    'Dengan sholat, semua urusan menjadi dimudahkan',
    'Sholat adalah kunci pembuka pintu surga',
    'Sholatmu adalah cerminan imanmu',
    'Jangan sia-siakan waktu sholat, karena tidak akan terulang',
    'Sholat adalah investasi terbaik untuk akhirat',
    'Dengan sholat berjamaah, pahala berlipat 27 kali',
    'Sholat adalah obat dari segala kegelisahan',
    'Jika kamu stress, sholatlah. Allah pasti memberi jalan',
    'Sholat tepat waktu adalah tanda ketakwaan',
    'Kesuksesan dunia dan akhirat dimulai dari sholat',
    'Sholat adalah benteng dari godaan syetan',
    'Orang yang meninggalkan sholat, Allah meninggalkan rezeki',
    'Sholat adalah amal pertama yang dihisab di akhirat',
    'Jangan biarkan kesibukan menghalangi sholat',
    'Sholat membawa keberkahan dalam setiap langkah',
    'Dengan sholat, hati menjadi dekat dengan Allah',
    'Sholat adalah penghapus dosa-dosa kecil',
    'Sholatmu hari ini menentukan surgamu besok',
    'Jangan tunggu tua untuk rajin sholat',
    'Sholat adalah kunci kebahagiaan hakiki',
    'Dengan sholat, Allah membukakan pintu rezeki',
    'Sholat adalah amalan yang paling dicintai Allah',
    'Jangan remehkan sholat, karena itulah penyelamatmu',
    'Sholat adalah bentuk cinta kepada Allah',
    'Dengan sholat, hidup menjadi lebih bermakna',
    'Sholat adalah pelita di kegelapan dunia',
    'Jaga sholatmu, maka Allah menjaga keluargamu',
    'Sholat adalah waktu istimewa bersama Allah',
    'Dengan sholat khusyuk, doa lebih mudah dikabulkan',
    'Sholat adalah senjata mukmin yang paling ampuh',
    'Jangan tunda sholat dengan alasan apapun',
    'Sholat adalah pembeda mukmin dengan kafir',
    'Dengan sholat, semua masalah terasa ringan',
    'Sholat adalah bentuk ketaatan tertinggi',
    'Jangan biarkan harta menghalangi sholat',
    'Sholat adalah kunci ketentraman jiwa',
    'Dengan sholat berjamaah, ukhuwah semakin kuat',
    'Sholat adalah perisai dari bencana',
    'Jangan sia-siakan nikmat waktu untuk sholat',
    'Sholat adalah jalan menuju ridha Allah',
    'Dengan sholat, malaikat mencatat kebaikan',
  ];

  // 🌅 SUBUH SPECIFIC QUOTES (30 quotes)
  static final List<String> _subuhQuotes = [
    'Sholat Subuh adalah cahaya yang menerangi seharian',
    'Bangun untuk Subuh adalah kemenangan atas nafsu',
    'Rezeki pagi menanti orang yang sholat Subuh',
    'Subuh adalah waktu paling berkah untuk berdoa',
    'Jangan tidurkan sholatmu, bangunkan dirimu',
    'Sholat Subuh adalah tanda cinta kepada Allah',
    'Orang yang sholat Subuh dalam perlindungan Allah',
    'Subuh adalah awal kesuksesan hari ini',
    'Dengan Subuh berjamaah, seharian dalam lindungan',
    'Jangan kalah dengan nafsu, bangkit untuk Subuh',
    'Sholat Subuh adalah investasi terbaik di pagi hari',
    'Kemuliaan Subuh tidak akan terulang hari ini',
    'Bangun Subuh adalah jihad melawan rasa malas',
    'Subuh adalah waktu mustajab untuk meminta',
    'Orang yang menjaga Subuh, dijaga oleh Allah',
    'Jangan sia-siakan berkah waktu Subuh',
    'Sholat Subuh membuka pintu rezeki',
    'Subuh adalah janji setia kepada Allah',
    'Dengan Subuh, hari dimulai dengan berkah',
    'Jangan biarkan kasur mengalahkan Subuh',
    'Sholat Subuh adalah kunci kebahagiaan pagi',
    'Subuh adalah waktu malaikat turun membawa rahmat',
    'Bangun Subuh adalah tanda kekuatan iman',
    'Jangan tunda Subuh, karena waktu tidak menunggu',
    'Sholat Subuh adalah bentuk syukur atas hidup',
    'Subuh adalah momentum terbaik bertemu Allah',
    'Dengan Subuh, pagi menjadi penuh semangat',
    'Jangan kalah dengan syetan, bangkit untuk Subuh',
    'Sholat Subuh adalah cahaya di awal hari',
    'Subuh adalah waktu terbaik untuk memulai',
  ];

  // ☀️ DZUHUR SPECIFIC QUOTES (25 quotes)
  static final List<String> _dzuhurQuotes = [
    'Istirahat sejenak, isi dengan sholat Dzuhur',
    'Dzuhur adalah waktu untuk menyegarkan iman',
    'Jangan biarkan kesibukan melupakan Dzuhur',
    'Sholat Dzuhur membawa berkah di siang hari',
    'Luangkan waktu untuk Dzuhur, Allah akan melapangkan rezeki',
    'Dzuhur adalah momentum recharge spiritual',
    'Jangan tunda Dzuhur dengan alasan kerja',
    'Sholat Dzuhur adalah bentuk syukur di tengah hari',
    'Dzuhur membawa ketenangan di tengah kesibukan',
    'Dengan Dzuhur berjamaah, pahala berlimpah',
    'Jangan korbankan Dzuhur untuk urusan dunia',
    'Sholat Dzuhur adalah istirahat terbaik',
    'Dzuhur adalah waktu untuk kembali kepada Allah',
    'Jangan sia-siakan waktu Dzuhur yang berharga',
    'Sholat Dzuhur membawa keberkahan siang',
    'Dzuhur adalah jeda yang penuh makna',
    'Dengan Dzuhur, siang menjadi lebih produktif',
    'Jangan lewatkan Dzuhur karena meeting',
    'Sholat Dzuhur adalah prioritas utama',
    'Dzuhur membawa ketenangan di tengah rutinitas',
    'Jangan biarkan deadline mengalahkan Dzuhur',
    'Sholat Dzuhur adalah bentuk disiplin waktu',
    'Dzuhur adalah waktu untuk reset mental',
    'Dengan Dzuhur tepat waktu, urusan dimudahkan',
    'Jangan tunda Dzuhur, karena waktu terus berjalan',
  ];

  // 🌤️ ASHAR SPECIFIC QUOTES (25 quotes)
  static final List<String> _asharQuotes = [
    'Ashar adalah waktu yang sangat mulia',
    'Jangan lewatkan Ashar, karena waktu cepat habis',
    'Sholat Ashar adalah bekal menjelang sore',
    'Ashar adalah waktu malaikat berganti shift',
    'Dengan Ashar tepat waktu, hidup lebih teratur',
    'Jangan sia-siakan kemuliaan waktu Ashar',
    'Sholat Ashar adalah tanda ketakwaan',
    'Ashar membawa kedamaian menjelang sore',
    'Jangan tunda Ashar dengan alasan apapun',
    'Sholat Ashar adalah cahaya di sore hari',
    'Ashar adalah waktu mustajab untuk berdoa',
    'Dengan Ashar berjamaah, ukhuwah semakin erat',
    'Jangan korbankan Ashar untuk pekerjaan',
    'Sholat Ashar adalah bentuk syukur sore',
    'Ashar membawa berkah menjelang malam',
    'Jangan lewatkan waktu emas Ashar',
    'Sholat Ashar adalah prioritas di sore hari',
    'Ashar adalah moment untuk kembali kepada Allah',
    'Dengan Ashar, sore menjadi penuh berkah',
    'Jangan biarkan waktu Ashar terlewat',
    'Sholat Ashar adalah investasi sore hari',
    'Ashar adalah waktu yang sangat istimewa',
    'Jangan tunda Ashar karena sibuk',
    'Sholat Ashar membawa ketenangan jiwa',
    'Ashar adalah kunci keberkahan sore',
  ];

  // 🌆 MAGHRIB SPECIFIC QUOTES (25 quotes)
  static final List<String> _maghribQuotes = [
    'Maghrib adalah waktu untuk berbuka puasa',
    'Jangan tunda Maghrib, karena waktu sangat singkat',
    'Sholat Maghrib menutup aktivitas siang',
    'Maghrib adalah waktu paling indah untuk sholat',
    'Dengan Maghrib berjamaah, keluarga semakin harmonis',
    'Jangan sia-siakan waktu Maghrib yang singkat',
    'Sholat Maghrib adalah awal malam yang berkah',
    'Maghrib membawa kedamaian di penghujung hari',
    'Jangan lewatkan Maghrib karena apapun',
    'Sholat Maghrib adalah syukur atas hari ini',
    'Maghrib adalah waktu berkumpul dengan keluarga',
    'Dengan Maghrib, malam dimulai dengan berkah',
    'Jangan tunda Maghrib meski lapar',
    'Sholat Maghrib adalah prioritas utama sore',
    'Maghrib adalah moment istimewa bersama Allah',
    'Jangan korbankan Maghrib untuk TV',
    'Sholat Maghrib membawa ketenangan malam',
    'Maghrib adalah waktu yang sangat berharga',
    'Dengan Maghrib tepat waktu, malam lebih tenang',
    'Jangan sia-siakan keindahan waktu Maghrib',
    'Sholat Maghrib adalah penutup hari yang baik',
    'Maghrib adalah waktu untuk refleksi diri',
    'Jangan lewatkan Maghrib karena santai',
    'Sholat Maghrib adalah bentuk disiplin waktu',
    'Maghrib adalah kunci malam yang berkah',
  ];

  // 🌙 ISYA SPECIFIC QUOTES (25 quotes)
  static final List<String> _isyaQuotes = [
    'Isya adalah penutup hari dengan ibadah',
    'Jangan tidur sebelum Isya selesai',
    'Sholat Isya adalah bekal tidur yang nyenyak',
    'Isya membawa ketenangan malam',
    'Dengan Isya berjamaah, tidur lebih berkah',
    'Jangan sia-siakan waktu Isya',
    'Sholat Isya adalah bentuk syukur malam',
    'Isya adalah waktu untuk menutup hari',
    'Jangan tunda Isya karena mengantuk',
    'Sholat Isya membawa mimpi yang indah',
    'Isya adalah waktu malaikat mencatat amal',
    'Dengan Isya tepat waktu, malam lebih tenang',
    'Jangan korbankan Isya untuk hiburan',
    'Sholat Isya adalah prioritas malam',
    'Isya adalah moment terakhir hari ini',
    'Jangan lewatkan Isya karena film',
    'Sholat Isya adalah penutup amal hari ini',
    'Isya membawa kedamaian sebelum tidur',
    'Dengan Isya, tidur dalam lindungan Allah',
    'Jangan sia-siakan kemuliaan waktu Isya',
    'Sholat Isya adalah investasi malam',
    'Isya adalah waktu untuk istirahat spiritual',
    'Jangan tunda Isya karena game',
    'Sholat Isya membawa berkah tidur',
    'Isya adalah kunci malam yang tenang',
  ];
  
  static final List<String> _tilawahQuotesMorning = [
    'Mulai hari dengan cahaya Al-Qur\'an',
    'Pagi yang diberkahi dimulai dengan tilawah',
    'Segarkan jiwa dengan ayat-ayat suci',
    'Al-Qur\'an adalah energi pagi yang hakiki',
  ];
  
  static final List<String> _tilawahQuotesAfternoon = [
    'Sempatkan tilawah di tengah kesibukan',
    'Istirahat sejenak, isi dengan Al-Qur\'an',
    'Recharge spiritual di siang hari',
  ];
  
  static final List<String> _tilawahQuotesEvening = [
    'Tutup hari dengan bacaan Al-Qur\'an',
    'Malam yang tenang dengan tilawah',
    'Sebelum tidur, bacalah Al-Qur\'an',
    'Akhiri hari dengan cahaya ilahi',
  ];

  static final List<String> _dzikirQuotesMorning = [
    'Dzikir pagi melindungimu seharian',
    'Mulai dengan mengingat Allah',
    'Pagi yang diberkahi dengan dzikir',
  ];
  
  static final List<String> _dzikirQuotesEvening = [
    'Dzikir petang benteng dari malam',
    'Akhiri hari dengan mengingat Allah',
    'Perlindungan malam dimulai dengan dzikir',
  ];

  static final List<String> _doaQuotesMorning = [
    'Minta kepada Allah sebelum memulai hari',
    'Doa pagi mengantarkan kesuksesan',
    'Pagi penuh berkah dengan berdoa',
  ];
  
  static final List<String> _doaQuotesEvening = [
    'Syukuri hari ini dengan doa',
    'Minta ampun sebelum malam tiba',
    'Doa petang membawa ketenangan',
  ];

  /// Get random prayer motivational quote based on prayer name
  String getRandomPrayerQuote(String prayerName) {
    List<String> quotes = [];
    
    switch (prayerName.toLowerCase()) {
      case 'subuh':
        quotes = _subuhQuotes;
        break;
      case 'dzuhur':
        quotes = _dzuhurQuotes;
        break;
      case 'ashar':
        quotes = _asharQuotes;
        break;
      case 'maghrib':
        quotes = _maghribQuotes;
        break;
      case 'isya':
        quotes = _isyaQuotes;
        break;
      default:
        quotes = _prayerMotivationalQuotes;
    }
    
    return quotes[_random.nextInt(quotes.length)];
  }

  String getContextAwareQuote(String type, String timeOfDay) {
    List<String> quotes = [];
    
    if (type == 'tilawah') {
      if (timeOfDay == 'Pagi') quotes = _tilawahQuotesMorning;
      else if (timeOfDay == 'Siang') quotes = _tilawahQuotesAfternoon;
      else quotes = _tilawahQuotesEvening;
    } else if (type == 'dzikir') {
      quotes = timeOfDay == 'Pagi' ? _dzikirQuotesMorning : _dzikirQuotesEvening;
    } else if (type == 'doa') {
      quotes = timeOfDay == 'Pagi' ? _doaQuotesMorning : _doaQuotesEvening;
    }
    
    return quotes.isNotEmpty ? quotes[_random.nextInt(quotes.length)] : '';
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📊 USAGE ANALYTICS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  Future<void> trackPrayerNotification(String prayerName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsJson = prefs.getString(_keyPrayerStats);
      
      Map<String, dynamic> stats = {};
      if (statsJson != null) {
        stats = jsonDecode(statsJson) as Map<String, dynamic>;
      }
      
      // Increment counter
      final key = 'notif_${prayerName.toLowerCase()}_count';
      stats[key] = (stats[key] as int? ?? 0) + 1;
      
      // Track last time
      stats['last_${prayerName.toLowerCase()}'] = DateTime.now().toIso8601String();
      
      await prefs.setString(_keyPrayerStats, jsonEncode(stats));
    } catch (e) {
      print('⚠️ Error tracking prayer: $e');
    }
  }
  
  Future<Map<String, int>> getPrayerStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsJson = prefs.getString(_keyPrayerStats);
      
      if (statsJson != null) {
        final stats = jsonDecode(statsJson) as Map<String, dynamic>;
        return stats.map((key, value) => MapEntry(key, value as int? ?? 0));
      }
    } catch (e) {
      print('⚠️ Error getting stats: $e');
    }
    
    return {};
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🚀 ENHANCED INITIALIZATION
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    print('');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🧠 ULTRA SMART Notification Manager v16.0');
    print('   Features: Context-Aware, Window Detection, Auto-Reschedule');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    try {
      await _initializeTimezone();
      await _initializePlugin();
      if (Platform.isAndroid) await _createCriticalChannels();
      
      final hasPerms = await ensurePermissions();
      
      if (!hasPerms) {
        print('❌ Permissions denied');
        return false;
      }
      
      // ✅ Setup midnight auto-reschedule
      _setupMidnightReschedule();
      
    _isInitialized = true;
print('✅ Notification System Ready with Auto-Badge Update');
print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
print('');
return true;
    } catch (e, stack) {
      print('❌ Init failed: $e\n$stack');
      return false;
    }
  }

  Future<bool> hasRequiredPermissions() async {
    try {
      final notifStatus = await Permission.notification.status;
      if (!notifStatus.isGranted) return false;
      
      if (Platform.isAndroid) {
        final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidPlugin != null) {
          final canSchedule = await androidPlugin.canScheduleExactNotifications() ?? false;
          if (!canSchedule) return false;
        }
        
        final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
        if (!batteryStatus.isGranted) return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> ensurePermissions() async {
    final hasPermissions = await hasRequiredPermissions();
    
    if (hasPermissions) {
      print('✅ All permissions already granted');
      return true;
    }
    
    print('⚠️ Missing permissions, requesting...');
    final result = await requestPermissions();
    
    return result['notification'] == true;
  }

  Future<void> _initializeTimezone() async {
    tz.initializeTimeZones();
    final prefs = await SharedPreferences.getInstance();
    final savedTz = prefs.getString('user_timezone') ?? 'Asia/Makassar';
    _userLocation = tz.getLocation(savedTz);
    tz.setLocalLocation(_userLocation!);
    print('📍 Timezone: $savedTz');
  }

  Future<void> _initializePlugin() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    await _notifications.initialize(
  InitializationSettings(android: androidSettings, iOS: iosSettings),
  onDidReceiveNotificationResponse: _onDidReceiveNotification,
  onDidReceiveBackgroundNotificationResponse: _onDidReceiveNotification,
);

print('✅ Notification plugin initialized with auto-save handler');
  }

 @pragma('vm:entry-point')
static Future<void> _onDidReceiveNotification(NotificationResponse response) async {
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('🔔 NOTIFICATION RECEIVED - Auto-saving & updating badge');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  
  try {
    if (response.payload == null) {
      print('⚠️ No payload found');
      return;
    }
    
    final data = jsonDecode(response.payload!) as Map<String, dynamic>;
    
    print('📋 Notification data:');
    print('   ID: ${data['id']}');
    print('   Type: ${data['type']}');
    print('   Title: ${data['title']}');
    
    // ✅ STEP 1: Save to history (convert scheduled → shown)
    await _saveNotificationToHistory(data);
    
    // ✅ STEP 2: FORCE update badge count IMMEDIATELY
    await _forceUpdateBadgeCount();
    
    // ✅ STEP 3: Track analytics
    final prayerName = data['name'] as String?;
    if (prayerName != null && data['type'] == 'prayer') {
      await NotificationManager()._trackPrayerInteraction(prayerName);
    }
    
    print('✅ Notification processed successfully');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    
  } catch (e, stack) {
    print('❌ Error processing notification: $e');
    print('Stack: $stack');
  }
}

// ✅ NEW METHOD: Force update badge immediately
static Future<void> _forceUpdateBadgeCount() async {
  try {
    print('   🔢 Forcing badge count update...');
    
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_keyNotificationHistory);
    final readIdsJson = prefs.getString(_keyReadNotifications);
    
    if (historyJson == null) {
      await prefs.setInt(_keyBadgeCount, 0);
      NotificationService.badgeCount.value = 0;
      print('   ✅ Badge: 0 (no history)');
      return;
    }
    
    final List<dynamic> history = jsonDecode(historyJson);
    Set<String> readIds = {};
    
    if (readIdsJson != null) {
      final List<dynamic> readList = jsonDecode(readIdsJson);
      readIds = readList.map((e) => e.toString()).toSet();
    }
    
    // ✅ COUNT ONLY: non-scheduled AND unread
    int unreadCount = 0;
    for (var item in history) {
      final isScheduled = item['isScheduled'] as bool? ?? false;
      final id = item['id'].toString();
      
      if (!isScheduled && !readIds.contains(id)) {
        unreadCount++;
      }
    }
    
    // ✅ UPDATE both SharedPreferences AND ValueNotifier
    await prefs.setInt(_keyBadgeCount, unreadCount);
    NotificationService.badgeCount.value = unreadCount;
    
    print('   ✅ Badge updated: $unreadCount unread notifications');
    print('   📊 Total shown: ${history.where((n) => n['isScheduled'] == false).length}');
    print('   📊 Total read: ${readIds.length}');
    
  } catch (e, stack) {
    print('   ❌ Error updating badge: $e');
    print('   Stack: $stack');
  }
}

Future<void> _trackPrayerInteraction(String prayerName) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final statsJson = prefs.getString('prayer_statistics');
    
    Map<String, dynamic> stats = {};
    if (statsJson != null) {
      stats = jsonDecode(statsJson) as Map<String, dynamic>;
    }
    
    // Increment counter
    final key = 'notif_${prayerName.toLowerCase()}_count';
    stats[key] = (stats[key] as int? ?? 0) + 1;
    
    // Track last time
    stats['last_${prayerName.toLowerCase()}'] = DateTime.now().toIso8601String();
    
    await prefs.setString('prayer_statistics', jsonEncode(stats));
    print('   📊 Prayer interaction tracked: $prayerName');
    
  } catch (e) {
    print('   ⚠️ Error tracking prayer: $e');
  }
}

  static Future<void> _saveNotificationToHistory(Map<String, dynamic> data) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_keyNotificationHistory);
    
    List<Map<String, dynamic>> history = [];
    if (historyJson != null) {
      final decoded = jsonDecode(historyJson) as List<dynamic>;
      history = decoded.cast<Map<String, dynamic>>();
    }
    
    final notifId = data['id'] as String;
    
    // ✅ CARI apakah sudah ada (dari scheduled)
    final existingIndex = history.indexWhere((item) => item['id'] == notifId);
    
    if (existingIndex != -1) {
      // ✅ CASE 1: UPDATE dari scheduled → shown
      print('   📝 Updating existing scheduled notification to SHOWN');
      
      history[existingIndex] = {
        ...history[existingIndex],
        'isScheduled': false, // ✅ CRITICAL: Mark as shown
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'isRead': false, // ✅ Mark as unread
      };
      
      print('   ✅ Updated: scheduled → shown (${data['title']})');
      
    } else {
      // ✅ CASE 2: NEW notification (shouldn't happen, but handle it)
      print('   📝 Creating new notification entry (SHOWN)');
      
      final notificationData = {
        'id': notifId,
        'title': data['title'] ?? 'Notifikasi',
        'body': data['body'] ?? '',
        'type': data['notifType'] ?? 9,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'isRead': false,
        'isScheduled': false, // ✅ This is a SHOWN notification
      };
      
      history.add(notificationData);
      print('   ✅ New notification saved: ${data['title']}');
    }
    
    // ✅ Keep last 200 notifications
    if (history.length > 200) {
      history = history.sublist(history.length - 200);
      print('   🗑️ Trimmed history to 200 items');
    }
    
    // ✅ Save back to SharedPreferences
    await prefs.setString(_keyNotificationHistory, jsonEncode(history));
    
    print('   📊 Total in history: ${history.length}');
    print('   📊 Scheduled: ${history.where((n) => n['isScheduled'] == true).length}');
    print('   📊 Shown: ${history.where((n) => n['isScheduled'] == false).length}');
    
  } catch (e, stack) {
    print('   ❌ Error saving to history: $e');
    print('   Stack: $stack');
  }
}
  static Future<void> _updateBadgeCountSmart(List<Map<String, dynamic>> history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readIdsJson = prefs.getString(_keyReadNotifications);
      
      Set<String> readIds = {};
      if (readIdsJson != null) {
        final List<dynamic> readList = jsonDecode(readIdsJson);
        readIds = readList.map((e) => e.toString()).toSet();
      }
      
      int unreadCount = 0;
      for (var item in history) {
        final isScheduled = item['isScheduled'] as bool? ?? false;
        if (!isScheduled && !readIds.contains(item['id'].toString())) {
          unreadCount++;
        }
      }
      
      await prefs.setInt(_keyBadgeCount, unreadCount);
      NotificationService.badgeCount.value = unreadCount;
      
      print('🔢 Badge updated: $unreadCount');
    } catch (e) {
      print('⚠️ Badge update error: $e');
    }
  }

  Future<void> _createCriticalChannels() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;
    
    await androidPlugin.createNotificationChannel(
      AndroidNotificationChannel(
        _channelPrayer, 'Adzan & Waktu Sholat',
        description: 'Notifikasi waktu sholat dengan prioritas tinggi',
        importance: Importance.max, playSound: true, enableVibration: true,
        vibrationPattern: Int64List.fromList(const [0, 500, 200, 500]),
        showBadge: true,
      ),
    );
    
    await androidPlugin.createNotificationChannel(
      AndroidNotificationChannel(
        _channelDzikir, 'Pengingat Dzikir',
        description: 'Dzikir pagi dan petang',
        importance: Importance.max, playSound: true, enableVibration: true,
        vibrationPattern: Int64List.fromList(const [0, 300, 200, 300]),
        ledColor: const Color(0xFF06B6D4),
      ),
    );
    
    await androidPlugin.createNotificationChannel(
      AndroidNotificationChannel(
        _channelTilawah, 'Pengingat Tilawah',
        description: 'Waktu membaca Al-Quran',
        importance: Importance.max, playSound: true, enableVibration: true,
        vibrationPattern: Int64List.fromList(const [0, 400, 100, 400]),
        ledColor: const Color(0xFF10B981),
      ),
    );
    
    await androidPlugin.createNotificationChannel(
      AndroidNotificationChannel(
        _channelDoa, 'Pengingat Doa',
        description: 'Pengingat untuk berdoa',
        importance: Importance.max, playSound: true, enableVibration: true,
        vibrationPattern: Int64List.fromList(const [0, 350, 150, 350]),
        ledColor: const Color(0xFFA855F7),
      ),
    );
    
    print('✅ Critical channels created');
  }

  Future<Map<String, bool>> requestPermissions() async {
    print('🔐 Requesting permissions...');
    
    final result = <String, bool>{
      'notification': false,
      'exactAlarm': false,
      'batteryOptimization': false,
    };
    
    var status = await Permission.notification.request();
    result['notification'] = status.isGranted;
    
    if (!status.isGranted) {
      print('❌ Notification denied');
      return result;
    }
    print('✅ Notification');
    
    if (Platform.isAndroid) {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        try {
          final canSchedule = await androidPlugin.canScheduleExactNotifications() ?? false;
          
          if (!canSchedule) {
            await androidPlugin.requestExactAlarmsPermission();
            final canNow = await androidPlugin.canScheduleExactNotifications() ?? false;
            result['exactAlarm'] = canNow;
          } else {
            result['exactAlarm'] = true;
          }
        } catch (e) {
          print('⚠️ Exact alarm error: $e');
        }
      }
      
      try {
        status = await Permission.ignoreBatteryOptimizations.status;
        
        if (!status.isGranted) {
          final granted = await Permission.ignoreBatteryOptimizations.request();
          result['batteryOptimization'] = granted.isGranted;
        } else {
          result['batteryOptimization'] = true;
        }
      } catch (e) {
        print('⚠️ Battery optimization unavailable');
      }
    }
    
    return result;
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🌙 AUTO-RESCHEDULE AT MIDNIGHT
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  void _setupMidnightReschedule() {
    _midnightRescheduleTimer?.cancel();
    
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 0, 1); // 00:01
    final duration = tomorrow.difference(now);
    
    print('⏰ Auto-reschedule set for: ${tomorrow.hour}:${tomorrow.minute}');
    print('   (in ${duration.inHours}h ${duration.inMinutes % 60}m)');
    
    _midnightRescheduleTimer = Timer(duration, () async {
      print('\n🌙 MIDNIGHT AUTO-RESCHEDULE TRIGGERED');
      try {
        // This will be called by main.dart's scheduleAllNotificationsIfNeeded
        // Just log for now
        print('   Notifications will be rescheduled on next app open');
      } catch (e) {
        print('❌ Auto-reschedule error: $e');
      }
      
      // Setup next day's reschedule
      _setupMidnightReschedule();
    });
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(NotificationResponse response) {
    print('🔔 Notification response (background)');
    NotificationManager()._handleNotificationTap(response);
  }

  Future<void> _handleNotificationTap(NotificationResponse response) async {
    if (response.payload == null) return;
    
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      final type = data['type'] as String? ?? 'unknown';
      
      print('📱 Handling notification: $type');
      
      onNotificationTapped?.call(type, data);
      
      if (onNotificationTappedWithContext != null) {
        try {
          final BuildContext? context = navigatorKey.currentContext;
          if (context != null) {
            onNotificationTappedWithContext?.call(context, type, data);
          }
        } catch (e) {
          print('⚠️ Context callback error: $e');
        }
      }
    } catch (e, stack) {
      print('❌ Error handling notification: $e');
      print('Stack: $stack');
    }
  }

  Future<void> _updateBadgeCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_keyNotificationHistory);
      
      if (historyJson == null) {
        await prefs.setInt(_keyBadgeCount, 0);
        NotificationService.badgeCount.value = 0;
        return;
      }
      
      final List<dynamic> history = jsonDecode(historyJson);
      final readIdsJson = prefs.getString(_keyReadNotifications);
      
      Set<String> readIds = {};
      if (readIdsJson != null) {
        final List<dynamic> readList = jsonDecode(readIdsJson);
        readIds = readList.map((e) => e.toString()).toSet();
      }
      
      int unread = 0;
      for (var item in history) {
        final isScheduled = item['isScheduled'] as bool? ?? false;
        if (!isScheduled && !readIds.contains(item['id'].toString())) {
          unread++;
        }
      }
      
      await prefs.setInt(_keyBadgeCount, unread);
      NotificationService.badgeCount.value = unread;
      print('🔢 Badge: $unread');
    } catch (e) {
      print('⚠️ Badge update error: $e');
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📅 ULTRA SMART SCHEDULE - WITH INTELLIGENCE
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> scheduleAllNotifications({
    required Map<String, TimeOfDay> prayerTimes,
    Map<String, bool>? enabledPrayers,
    required Map<String, TimeOfDay> tilawahTimes,
    Map<String, TimeOfDay>? doaTimes,
  }) async {
    print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🧠 ULTRA SMART SCHEDULING v16.0');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    try {
      await cancelAllNotifications();
      
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final currentMinutes = now.hour * 60 + now.minute;
      
      // ✅ INTELLIGENT CONTEXT
      final currentWindow = getCurrentPrayerWindow(prayerTimes);
      final nextPrayer = getNextPrayer(prayerTimes);
      
      print('\n📍 CURRENT CONTEXT:');
      print('   Time: ${now.hour}:${now.minute.toString().padLeft(2, '0')}');
      print('   Window: $currentWindow');
      if (nextPrayer != null) {
        print('   Next Prayer: ${nextPrayer['name']} in ${nextPrayer['minutesRemaining']} min');
        if (nextPrayer['isUrgent'] == true) {
          print('   ⚠️  URGENT: Less than 30 minutes!');
        }
      }
      
      final enabled = enabledPrayers ?? {
        'Subuh': prefs.getBool('notif_enable_subuh') ?? true,
        'Dzuhur': prefs.getBool('notif_enable_dzuhur') ?? true,
        'Ashar': prefs.getBool('notif_enable_ashar') ?? true,
        'Maghrib': prefs.getBool('notif_enable_maghrib') ?? true,
        'Isya': prefs.getBool('notif_enable_isya') ?? true,
      };
      
      int scheduled = 0;
      int skipped = 0;
      List<String> urgentNotifications = [];
      
      // 1️⃣ PRAYER NOTIFICATIONS - SMART FILTERING
      print('\n1️⃣ PRAYER NOTIFICATIONS:');
      for (var entry in prayerTimes.entries) {
        if (entry.key == 'Terbit' || entry.key == 'Imsak' || 
            entry.key == 'Syuruk' || entry.key == 'Duha') {
          continue;
        }
        
        if (enabled[entry.key] == true) {
          final prayerMinutes = entry.value.hour * 60 + entry.value.minute;
          
          if (prayerMinutes > currentMinutes) {
            try {
              await _schedulePrayerSmart(entry.key, entry.value, prayerTimes);
              scheduled++;
              
              final remaining = prayerMinutes - currentMinutes;
              if (remaining < 30) {
                urgentNotifications.add('${entry.key} in $remaining min');
              }
              
              print('   ✅ ${entry.key}: ${_fmt(entry.value)} (+${remaining}m)');
            } catch (e) {
              print('   ❌ ${entry.key}: $e');
            }
          } else {
            skipped++;
            print('   ⏭️  ${entry.key}: ${_fmt(entry.value)} (passed)');
          }
        }
      }
      
      // 2️⃣ DZIKIR NOTIFICATIONS
      print('\n2️⃣ DZIKIR NOTIFICATIONS:');
      if (prefs.getBool('notif_enable_dzikir_pagi') ?? true) {
        final subuhTime = prayerTimes['Subuh'];
        if (subuhTime != null) {
          final time = _addMin(subuhTime, 30);
          final dzikirMinutes = time.hour * 60 + time.minute;
          
          if (dzikirMinutes > currentMinutes) {
            try {
              await _scheduleDzikirSmart('Pagi', time);
              scheduled++;
              print('   ✅ Pagi: ${_fmt(time)}');
            } catch (e) {
              print('   ❌ Pagi: $e');
            }
          } else {
            skipped++;
            print('   ⏭️  Pagi: ${_fmt(time)} (passed)');
          }
        }
      }
      
      if (prefs.getBool('notif_enable_dzikir_petang') ?? true) {
        final asharTime = prayerTimes['Ashar'];
        if (asharTime != null) {
          final time = _addMin(asharTime, 30);
          final dzikirMinutes = time.hour * 60 + time.minute;
          
          if (dzikirMinutes > currentMinutes) {
            try {
              await _scheduleDzikirSmart('Petang', time);
              scheduled++;
              print('   ✅ Petang: ${_fmt(time)}');
            } catch (e) {
              print('   ❌ Petang: $e');
            }
          } else {
            skipped++;
            print('   ⏭️  Petang: ${_fmt(time)} (passed)');
          }
        }
      }
      
      // 3️⃣ TILAWAH NOTIFICATIONS
      print('\n3️⃣ TILAWAH NOTIFICATIONS:');
      final tilawahSchedule = [
        ('Pagi', 'notif_enable_tilawah_pagi', true),
        ('Siang', 'notif_enable_tilawah_siang', false),
        ('Malam', 'notif_enable_tilawah_malam', true),
      ];
      
      for (var (type, prefKey, defaultEnabled) in tilawahSchedule) {
        if (prefs.getBool(prefKey) ?? defaultEnabled) {
          final time = tilawahTimes[type];
          if (time != null) {
            final tilawahMinutes = time.hour * 60 + time.minute;
            
            if (tilawahMinutes > currentMinutes) {
              try {
                await _scheduleTilawahSmart(type, time);
                scheduled++;
                print('   ✅ $type: ${_fmt(time)}');
              } catch (e) {
                print('   ❌ $type: $e');
              }
            } else {
              skipped++;
              print('   ⏭️  $type: ${_fmt(time)} (passed)');
            }
          }
        }
      }
      
      // 4️⃣ DOA NOTIFICATIONS
      print('\n4️⃣ DOA NOTIFICATIONS:');
      if (prefs.getBool('notif_enable_doa_pagi') ?? true) {
        final subuhTime = prayerTimes['Subuh'];
        if (subuhTime != null) {
          final time = doaTimes?['Pagi'] ?? _addMin(subuhTime, 15);
          final doaMinutes = time.hour * 60 + time.minute;
          
          if (doaMinutes > currentMinutes) {
            try {
              await _scheduleDoaSmart('Pagi', time);
              scheduled++;
              print('   ✅ Pagi: ${_fmt(time)}');
            } catch (e) {
              print('   ❌ Pagi: $e');
            }
          } else {
            skipped++;
            print('   ⏭️  Pagi: ${_fmt(time)} (passed)');
          }
        }
      }
      
      if (prefs.getBool('notif_enable_doa_petang') ?? true) {
        final maghribTime = prayerTimes['Maghrib'];
        if (maghribTime != null) {
          final time = doaTimes?['Petang'] ?? _addMin(maghribTime, 10);
          final doaMinutes = time.hour * 60 + time.minute;
          
          if (doaMinutes > currentMinutes) {
            try {
              await _scheduleDoaSmart('Petang', time);
              scheduled++;
              print('   ✅ Petang: ${_fmt(time)}');
            } catch (e) {
              print('   ❌ Petang: $e');
            }
          } else {
            skipped++;
            print('   ⏭️  Petang: ${_fmt(time)} (passed)');
          }
        }
      }
      
      final pending = await _notifications.pendingNotificationRequests();
      print('\n📊 INTELLIGENT SUMMARY:');
      print('   ✅ Scheduled: $scheduled');
      print('   ⏭️  Skipped: $skipped');
      print('   📋 Pending: ${pending.length}');
      
      if (urgentNotifications.isNotEmpty) {
        print('\n   ⚠️  URGENT UPCOMING:');
        for (var notif in urgentNotifications) {
          print('      • $notif');
        }
      }
      
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      
    } catch (e, stack) {
      print('❌ Fatal error: $e');
      print('Stack: $stack');
      rethrow;
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🕌 ULTRA SMART PRAYER SCHEDULING
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> _schedulePrayerSmart(
    String name, 
    TimeOfDay time, 
    Map<String, TimeOfDay> allPrayerTimes,
  ) async {
    final now = tz.TZDateTime.now(_userLocation!);
    var scheduled = tz.TZDateTime(_userLocation!, now.year, now.month, now.day, time.hour, time.minute);
    
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    
    final prefs = await SharedPreferences.getInstance();
    final isSilent = prefs.getBool('notification_silent_mode') ?? false;
    
    // ✅ GET RANDOM MOTIVATIONAL QUOTE based on prayer name
    final motivationalQuote = getRandomPrayerQuote(name);
    
    // ✅ SMART MESSAGE based on urgency
    final currentMinutes = now.hour * 60 + now.minute;
    final prayerMinutes = time.hour * 60 + time.minute;
    final remaining = prayerMinutes - currentMinutes;
    
    String urgencyMessage = '';
    if (remaining < 10 && remaining > 0) {
      urgencyMessage = '\n\n⚠️ SEGERA! Waktu $name tinggal $remaining menit lagi!';
    } else if (remaining < 30 && remaining > 0) {
      urgencyMessage = '\n\n⏰ Bersiaplah! Sebentar lagi waktu $name';
    }
    
    final title = '🕌 Waktu Sholat $name';
    final body = '$motivationalQuote$urgencyMessage';
    final id = '${name}_${scheduled.millisecondsSinceEpoch}';
    
    final payload = jsonEncode({
      'id': id,
      'type': 'prayer',
      'name': name,
      'time': scheduled.toIso8601String(),
      'title': title,
      'body': body,
      'motivationalQuote': motivationalQuote,
      'notifType': _getNotificationTypeIndex(name),
    });
    
    await _notifications.zonedSchedule(
      _notifIds[name]!,
      title,
      body,
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelPrayer, 
          'Adzan & Waktu Sholat',
          importance: Importance.max, 
          priority: Priority.max,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          playSound: !isSilent,
          sound: isSilent ? null : const RawResourceAndroidNotificationSound('adzan'),
          enableVibration: !isSilent,
          vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
          icon: '@mipmap/ic_launcher', 
          color: const Color(0xFF059669),
          styleInformation: BigTextStyleInformation(
            body,
            contentTitle: title,
            summaryText: 'Bekal Muslim',
          ),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: !isSilent,
          sound: 'adzan.wav',
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleDzikirSmart(String type, TimeOfDay time) async {
    final now = tz.TZDateTime.now(_userLocation!);
    var scheduled = tz.TZDateTime(_userLocation!, now.year, now.month, now.day, time.hour, time.minute);
    if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));
    
    final prefs = await SharedPreferences.getInstance();
    final isSilent = prefs.getBool('notification_silent_mode') ?? false;
    
    final emoji = type == 'Pagi' ? '🌅' : '🌆';
    final quote = getContextAwareQuote('dzikir', type);
    
    final title = '$emoji Waktu Dzikir $type';
    final id = 'Dzikir${type}_${scheduled.millisecondsSinceEpoch}';
    
    await _notifications.zonedSchedule(
      type == 'Pagi' ? _notifIds['DzikirPagi']! : _notifIds['DzikirPetang']!,
      title,
      quote,
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelDzikir,
          'Pengingat Dzikir',
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          playSound: !isSilent,
          enableVibration: !isSilent,
          vibrationPattern: Int64List.fromList([0, 300, 200, 300]),
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF06B6D4),
          styleInformation: BigTextStyleInformation(
            quote,
            contentTitle: title,
          ),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: !isSilent,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: jsonEncode({'id': id, 'type': 'dzikir', 'name': type, 'title': title, 'body': quote, 'notifType': 7}),
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleTilawahSmart(String type, TimeOfDay time) async {
    final now = tz.TZDateTime.now(_userLocation!);
    var scheduled = tz.TZDateTime(_userLocation!, now.year, now.month, now.day, time.hour, time.minute);
    if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));
    
    final prefs = await SharedPreferences.getInstance();
    final isSilent = prefs.getBool('notification_silent_mode') ?? false;
    
    final lastRead = await _quranService.getLastRead();
    final lastReadText = lastRead != null 
        ? 'Lanjutkan: ${lastRead.surahName} Ayat ${lastRead.ayahNumber}'
        : 'Mulai Tilawah Al-Qur\'an';
    
    final quote = getContextAwareQuote('tilawah', type);
    
    String emoji = type == 'Pagi' ? '📖' : type == 'Siang' ? '☀️' : '🌙';
    final title = '$emoji Tilawah $type';
    final body = '$lastReadText\n\n$quote';
    final id = 'Tilawah${type}_${scheduled.millisecondsSinceEpoch}';
    
    final notifId = type == 'Pagi' ? _notifIds['TilawahPagi']! 
        : type == 'Siang' ? _notifIds['TilawahSiang']! 
        : _notifIds['TilawahMalam']!;
    
    await _notifications.zonedSchedule(
      notifId,
      title,
      body,
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelTilawah,
          'Pengingat Tilawah',
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          playSound: !isSilent,
          enableVibration: !isSilent,
          vibrationPattern: Int64List.fromList([0, 400, 100, 400]),
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF10B981),
          styleInformation: BigTextStyleInformation(body, contentTitle: title),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: !isSilent,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: jsonEncode({'id': id, 'type': 'tilawah', 'name': type, 'title': title, 'body': body, 'lastRead': lastRead?.toJson(), 'notifType': 8}),
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleDoaSmart(String type, TimeOfDay time) async {
    final now = tz.TZDateTime.now(_userLocation!);
    var scheduled = tz.TZDateTime(_userLocation!, now.year, now.month, now.day, time.hour, time.minute);
    if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));
    
    final prefs = await SharedPreferences.getInstance();
    final isSilent = prefs.getBool('notification_silent_mode') ?? false;
    
    final quote = getContextAwareQuote('doa', type);
    final emoji = type == 'Pagi' ? '🤲' : '🌟';
    final title = '$emoji Waktu Doa $type';
    final id = 'Doa${type}_${scheduled.millisecondsSinceEpoch}';
    
    await _notifications.zonedSchedule(
      type == 'Pagi' ? _notifIds['DoaPagi']! : _notifIds['DoaPetang']!,
      title,
      quote,
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelDoa,
          'Pengingat Doa',
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          playSound: !isSilent,
          enableVibration: !isSilent,
          vibrationPattern: Int64List.fromList([0, 350, 150, 350]),
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFFA855F7),
          styleInformation: BigTextStyleInformation(
            quote,
            contentTitle: title,
          ),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: !isSilent,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: jsonEncode({'id': id, 'type': 'doa', 'name': type, 'title': title, 'body': quote, 'notifType': 10}),
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🛠️ HELPER METHODS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  int _getNotificationTypeIndex(String prayerName) {
    switch (prayerName.toLowerCase()) {
      case 'subuh': return 0;
      case 'dzuhur': return 1;
      case 'ashar': return 2;
      case 'maghrib': return 3;
      case 'isya': return 4;
      default: return 5;
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print('🗑️ All notifications cancelled');
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  String _fmt(TimeOfDay time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  
  String _getMessage(String name) {
    switch (name) {
      case 'Subuh': return 'Cahaya hari dimulai dengan sholat Subuh';
      case 'Dzuhur': return 'Istirahat sejenak, tunaikan sholat Dzuhur';
      case 'Ashar': return 'Waktu mulia untuk sholat Ashar';
      case 'Maghrib': return 'Akhiri siang dengan sholat Maghrib';
      case 'Isya': return 'Tutup hari dengan sholat Isya';
      default: return 'Saatnya menunaikan sholat';
    }
  }

  TimeOfDay _addMin(TimeOfDay time, int minutes) {
    final total = time.hour * 60 + time.minute + minutes;
    return TimeOfDay(hour: (total ~/ 60) % 24, minute: total % 60);
  }

  void dispose() {
    _midnightRescheduleTimer?.cancel();
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();