import 'package:home_widget/home_widget.dart';
import 'package:flutter/material.dart';

class WidgetService {
  static const String appGroupId        = 'group.com.bekalsunnah.doa_harian';
  static const String androidWidgetName = 'PrayerTimeWidgetProvider';

  static Future<void> initialize() async {
    try {
      await HomeWidget.setAppGroupId(appGroupId);
    } catch (e) {
      debugPrint('WidgetService: init error — $e');
    }
  }

  /// Update widget dengan semua 5 waktu sholat + info sholat berikutnya.
  /// [allPrayerTimes] — map: { 'Subuh': '04:45', 'Dzuhur': '12:00', ... }
  static Future<void> updatePrayerTimeWidget({
    required String locationName,
    required String prayerName,       // Sholat berikutnya
    required String prayerTime,       // Waktu sholat berikutnya (HH:mm)
    required String hijriDate,
    required Duration timeUntilNext,
    Map<String, String>? allPrayerTimes, // { 'Subuh': '04:45', ... }
  }) async {
    try {
      // Format countdown
      String countdown;
      final h = timeUntilNext.inHours;
      final m = timeUntilNext.inMinutes.remainder(60);
      if (h > 0) {
        countdown = '$h jam $m menit lagi';
      } else if (m > 0) {
        countdown = '$m menit lagi';
      } else {
        countdown = 'Sekarang';
      }

      // ── Core data ────────────────────────────────────
      await HomeWidget.saveWidgetData<String>('widget_location',    locationName);
      await HomeWidget.saveWidgetData<String>('widget_prayer_name', prayerName);
      await HomeWidget.saveWidgetData<String>('widget_prayer_time', prayerTime);
      await HomeWidget.saveWidgetData<String>('widget_countdown',   countdown);
      await HomeWidget.saveWidgetData<String>('widget_hijri',       hijriDate);

      // ── All 5 prayer times ────────────────────────────
      if (allPrayerTimes != null) {
        await HomeWidget.saveWidgetData<String>('widget_subuh',   allPrayerTimes['Subuh']   ?? '--:--');
        await HomeWidget.saveWidgetData<String>('widget_dzuhur',  allPrayerTimes['Dzuhur']  ?? '--:--');
        await HomeWidget.saveWidgetData<String>('widget_ashar',   allPrayerTimes['Ashar']   ?? '--:--');
        await HomeWidget.saveWidgetData<String>('widget_maghrib', allPrayerTimes['Maghrib'] ?? '--:--');
        await HomeWidget.saveWidgetData<String>('widget_isya',    allPrayerTimes['Isya']    ?? '--:--');
      }

      await HomeWidget.updateWidget(
        qualifiedAndroidName: 'com.bekalsunnah.doa_harian.PrayerTimeWidgetProvider',
        iOSName: 'PrayerTimeWidget',
      );

      debugPrint('✅ Widget updated: $prayerName at $prayerTime (${allPrayerTimes?.length ?? 0} prayer times)');
    } catch (e) {
      debugPrint('❌ WidgetService.updatePrayerTimeWidget: $e');
    }
  }

  /// Format TimeOfDay to HH:mm string
  static String formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}
