// // notification/notification_updater.dart - FIXED (NO HARDCODED TIMEZONE LABELS)
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:myquran/notification/notification_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:timezone/timezone.dart' as tz;

// class NotificationUpdater {
//   static final NotificationService _notificationService = NotificationService();
//   static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
//   static const String _keyLastUpdate = 'last_notification_update';
//   static const String _keyUpdateStatus = 'notification_update_status';
  
//   // Schedule all notifications based on prayer times and user preferences
//   static Future<void> updateAllNotifications({
//     required Map<String, TimeOfDay> prayerTimes,
//     bool force = false,
//     Map<String, bool>? enabledPrayers,
//     bool enableDzikirPagi = true,
//     bool enableDzikirPetang = true,
//     bool enableTilawahPagi = true,
//     bool enableTilawahMalam = true,
//   }) async {
//     try {
//       print('📅 Updating all notifications...');
      
//       // Check if update is needed
//       if (!force && !await _shouldUpdate()) {
//         print('⏭️ Update not needed yet');
//         return;
//       }
      
//       final prefs = await SharedPreferences.getInstance();
      
//       // Load enabled prayers if not provided
//       final Map<String, bool> prayersToSchedule = enabledPrayers ?? {
//         'Subuh': prefs.getBool('notif_enable_subuh') ?? true,
//         'Dzuhur': prefs.getBool('notif_enable_dzuhur') ?? true,
//         'Ashar': prefs.getBool('notif_enable_ashar') ?? true,
//         'Maghrib': prefs.getBool('notif_enable_maghrib') ?? true,
//         'Isya': prefs.getBool('notif_enable_isya') ?? true,
//       };
      
//       // Load other notification preferences
//       enableDzikirPagi = prefs.getBool('notif_enable_dzikir_pagi') ?? true;
//       enableDzikirPetang = prefs.getBool('notif_enable_dzikir_petang') ?? true;
//       enableTilawahPagi = prefs.getBool('notif_enable_tilawah_pagi') ?? true;
//       enableTilawahMalam = prefs.getBool('notif_enable_tilawah_malam') ?? true;
      
//       // Get silent mode status
//       final isSilentMode = await _notificationService.getSilentMode();
      
//       // Cancel all existing notifications
//       await _notificationService.cancelAllNotifications();
      
//       int totalScheduled = 0;
      
//       // Schedule prayer time notifications
//       for (var entry in prayerTimes.entries) {
//         final prayerName = entry.key;
//         final prayerTime = entry.value;
        
//         // Skip 'Terbit' (sunrise)
//         if (prayerName == 'Terbit') continue;
        
//         // Check if this prayer notification is enabled
//         if (prayersToSchedule[prayerName] == true) {
//           await _schedulePrayerNotification(prayerName, prayerTime, isSilentMode);
//           totalScheduled++;
//           print('✅ Scheduled: $prayerName at ${prayerTime.hour}:${prayerTime.minute}');
//         } else {
//           print('⏭️ Skipped: $prayerName (disabled by user)');
//         }
//       }
      
//       // Schedule dzikir notifications
//       if (enableDzikirPagi) {
//         await _scheduleDzikirNotification('Pagi', TimeOfDay(hour: 7, minute: 0), isSilentMode);
//         totalScheduled++;
//         print('✅ Scheduled: Dzikir Pagi at 07:00');
//       }
      
//       if (enableDzikirPetang) {
//         await _scheduleDzikirNotification('Petang', TimeOfDay(hour: 17, minute: 0), isSilentMode);
//         totalScheduled++;
//         print('✅ Scheduled: Dzikir Petang at 17:00');
//       }
      
//       // Schedule tilawah notifications
//       if (enableTilawahPagi) {
//         await _scheduleTilawahNotification('Pagi', TimeOfDay(hour: 6, minute: 0), isSilentMode);
//         totalScheduled++;
//         print('✅ Scheduled: Tilawah Pagi at 06:00');
//       }
      
//       if (enableTilawahMalam) {
//         await _scheduleTilawahNotification('Malam', TimeOfDay(hour: 20, minute: 0), isSilentMode);
//         totalScheduled++;
//         print('✅ Scheduled: Tilawah Malam at 20:00');
//       }
      
//       // Save update status
//       await prefs.setString(_keyLastUpdate, DateTime.now().toIso8601String());
//       await prefs.setString(_keyUpdateStatus, '$totalScheduled notifikasi terjadwal');
      
//       print('✅ All notifications updated: $totalScheduled total');
      
//     } catch (e) {
//       print('❌ Error updating notifications: $e');
//       throw e;
//     }
//   }
  
//   static Future<bool> _shouldUpdate() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final lastUpdateStr = prefs.getString(_keyLastUpdate);
      
//       if (lastUpdateStr == null) return true;
      
//       final lastUpdate = DateTime.parse(lastUpdateStr);
//       final now = DateTime.now();
      
//       // Update if last update was more than 24 hours ago
//       final difference = now.difference(lastUpdate);
//       return difference.inHours >= 24;
      
//     } catch (e) {
//       print('Error checking update status: $e');
//       return true;
//     }
//   }
  
//   static Future<void> _schedulePrayerNotification(
//     String prayerName, 
//     TimeOfDay time,
//     bool isSilentMode,
//   ) async {
//     final now = tz.TZDateTime.now(tz.local);
//     var scheduledDate = tz.TZDateTime(
//       tz.local,
//       now.year,
//       now.month,
//       now.day,
//       time.hour,
//       time.minute,
//     );
    
//     // If the time has passed today, schedule for tomorrow
//     if (scheduledDate.isBefore(now)) {
//       scheduledDate = scheduledDate.add(Duration(days: 1));
//     }
    
//     final notificationId = _getPrayerNotificationId(prayerName);
    
//     // ✅ FORMAT WAKTU TANPA LABEL TIMEZONE HARDCODED
//     final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    
//     await _notifications.zonedSchedule(
//       notificationId,
//       '🕌 Waktu Sholat $prayerName',
//       'Saatnya sholat $prayerName ($timeStr)', // ✅ TIDAK ADA "WIB"
//       scheduledDate,
//       NotificationDetails(
//         android: AndroidNotificationDetails(
//           'prayer_alerts_v2',
//           'Waktu Sholat',
//           channelDescription: 'Pengingat waktu sholat',
//           importance: Importance.max,
//           priority: Priority.max,
//           icon: '@mipmap/ic_launcher',
//           color: Color(0xFF059669),
//           playSound: !isSilentMode,
//           enableVibration: !isSilentMode,
//         ),
//         iOS: DarwinNotificationDetails(
//           presentAlert: true,
//           presentBadge: true,
//           presentSound: !isSilentMode,
//           interruptionLevel: InterruptionLevel.timeSensitive,
//         ),
//       ),
//       androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//       uiLocalNotificationDateInterpretation:
//           UILocalNotificationDateInterpretation.absoluteTime,
//       matchDateTimeComponents: DateTimeComponents.time,
//       payload: 'prayer|$prayerName|${time.hour}:${time.minute}',
//     );
//   }
  
//   static Future<void> _scheduleDzikirNotification(
//     String type, 
//     TimeOfDay time,
//     bool isSilentMode,
//   ) async {
//     final now = tz.TZDateTime.now(tz.local);
//     var scheduledDate = tz.TZDateTime(
//       tz.local,
//       now.year,
//       now.month,
//       now.day,
//       time.hour,
//       time.minute,
//     );
    
//     if (scheduledDate.isBefore(now)) {
//       scheduledDate = scheduledDate.add(Duration(days: 1));
//     }
    
//     final notificationId = type == 'Pagi' ? 200 : 201;
//     final emoji = type == 'Pagi' ? '🌅' : '🌆';
    
//     await _notifications.zonedSchedule(
//       notificationId,
//       '$emoji Waktu Dzikir $type',
//       'Saatnya membaca dzikir $type hari ini',
//       scheduledDate,
//       NotificationDetails(
//         android: AndroidNotificationDetails(
//           'dzikir_reminders_v2',
//           'Dzikir Pagi & Petang',
//           channelDescription: 'Pengingat dzikir pagi dan petang',
//           importance: Importance.high,
//           priority: Priority.high,
//           icon: '@mipmap/ic_launcher',
//           color: Color(0xFF06B6D4),
//           playSound: !isSilentMode,
//           enableVibration: !isSilentMode,
//         ),
//         iOS: DarwinNotificationDetails(
//           presentAlert: true,
//           presentBadge: true,
//           presentSound: !isSilentMode,
//         ),
//       ),
//       androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//       uiLocalNotificationDateInterpretation:
//           UILocalNotificationDateInterpretation.absoluteTime,
//       matchDateTimeComponents: DateTimeComponents.time,
//       payload: 'dzikir|$type|${time.hour}:${time.minute}',
//     );
//   }
  
//   static Future<void> _scheduleTilawahNotification(
//     String type, 
//     TimeOfDay time,
//     bool isSilentMode,
//   ) async {
//     final now = tz.TZDateTime.now(tz.local);
//     var scheduledDate = tz.TZDateTime(
//       tz.local,
//       now.year,
//       now.month,
//       now.day,
//       time.hour,
//       time.minute,
//     );
    
//     if (scheduledDate.isBefore(now)) {
//       scheduledDate = scheduledDate.add(Duration(days: 1));
//     }
    
//     final notificationId = type == 'Pagi' ? 300 : 301;
//     final emoji = type == 'Pagi' ? '📖' : '🌙';
    
//     await _notifications.zonedSchedule(
//       notificationId,
//       '$emoji Waktu Tilawah $type',
//       'Luangkan waktu untuk membaca Al-Qur\'an',
//       scheduledDate,
//       NotificationDetails(
//         android: AndroidNotificationDetails(
//           'tilawah_reminders_v2',
//           'Tilawah Al-Qur\'an',
//           channelDescription: 'Pengingat membaca Al-Qur\'an',
//           importance: Importance.high,
//           priority: Priority.high,
//           icon: '@mipmap/ic_launcher',
//           color: Color(0xFF10B981),
//           playSound: !isSilentMode,
//           enableVibration: !isSilentMode,
//         ),
//         iOS: DarwinNotificationDetails(
//           presentAlert: true,
//           presentBadge: true,
//           presentSound: !isSilentMode,
//         ),
//       ),
//       androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//       uiLocalNotificationDateInterpretation:
//           UILocalNotificationDateInterpretation.absoluteTime,
//       matchDateTimeComponents: DateTimeComponents.time,
//       payload: 'tilawah|$type|${time.hour}:${time.minute}',
//     );
//   }
  
//   static int _getPrayerNotificationId(String prayerName) {
//     switch (prayerName) {
//       case 'Subuh': return 100;
//       case 'Dzuhur': return 101;
//       case 'Ashar': return 102;
//       case 'Maghrib': return 103;
//       case 'Isya': return 104;
//       default: return 999;
//     }
//   }
  
//   static Future<String> getUpdateStatus() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       return prefs.getString(_keyUpdateStatus) ?? 'Belum ada update';
//     } catch (e) {
//       return 'Error';
//     }
//   }
  
//   static Future<DateTime?> getLastUpdateTime() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final lastUpdateStr = prefs.getString(_keyLastUpdate);
//       if (lastUpdateStr == null) return null;
//       return DateTime.parse(lastUpdateStr);
//     } catch (e) {
//       return null;
//     }
//   }
// }