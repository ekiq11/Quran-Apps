import 'package:flutter/material.dart';

enum IslamicEventType {
  fastingObligatory, // Puasa Wajib (Ramadhan)
  fastingHighlySunnah, // Puasa Sunnah Mu'akkad (sangat dianjurkan)
  fastingSunnah, // Puasa Sunnah
  forbiddenFasting, // Haram Puasa
  specialDay, // Hari Khusus (tanpa perayaan bidah)
}

class IslamicEvent {
  final String name;
  final String description;
  final String dalil; // Dalil dari Hadits Shahih
  final IslamicEventType type;
  final Color color;

  IslamicEvent({
    required this.name,
    required this.description,
    required this.dalil,
    required this.type,
    required this.color,
  });
}

class IslamicCalendarEvents {
  // Warna untuk setiap jenis event
  static const Color ramadhanColor = Color(0xFF10B981); // Hijau - Puasa Wajib
  static const Color mondayThursdayColor = Color(0xFF3B82F6); // Biru - Senin Kamis
  static const Color ayyamulBidhColor = Color(0xFF8B5CF6); // Ungu - Ayyamul Bidh
  static const Color muharramColor = Color(0xFF6366F1); // Indigo - Muharram/Asyura
  static const Color arfahColor = Color(0xFFEC4899); // Pink - Arafah & Dzulhijjah
  static const Color syawalColor = Color(0xFFF59E0B); // Orange - Syawal
  static const Color shabanColor = Color(0xFF14B8A6); // Teal - Syakban
  static const Color forbiddenColor = Color(0xFFEF4444); // Merah - Haram Puasa

  /// Mendapatkan events berdasarkan tanggal Hijriah
  /// Hanya berdasarkan HADITS SHAHIH dari Bukhari, Muslim, dll
  static List<IslamicEvent> getEventsForHijriDate(
      int year, int month, int day, int weekday) {
    List<IslamicEvent> events = [];

    // ═══════════════════════════════════════════════════════════
    // PUASA SENIN (weekday 1 = Monday)
    // Dalil: HR. Tirmidzi no. 747 (Shahih), HR. Muslim, HR. Abu Daud
    // ═══════════════════════════════════════════════════════════
    if (weekday == 1) {
      events.add(IslamicEvent(
        name: 'Puasa Senin',
        description: 'Puasa sunnah hari Senin',
        dalil:
            'HR. Tirmidzi: "Amal-amal dihadapkan pada hari Senin dan Kamis, maka aku suka jika amalanku dihadapkan sedangkan aku sedang berpuasa"',
        type: IslamicEventType.fastingHighlySunnah,
        color: mondayThursdayColor,
      ));
    }

    // ═══════════════════════════════════════════════════════════
    // PUASA KAMIS (weekday 4 = Thursday)
    // Dalil: HR. Tirmidzi, HR. Muslim, HR. Bukhari
    // ═══════════════════════════════════════════════════════════
    if (weekday == 4) {
      events.add(IslamicEvent(
        name: 'Puasa Kamis',
        description: 'Puasa sunnah hari Kamis',
        dalil:
            'HR. Muslim: "Rasulullah biasa berpuasa pada hari Senin dan Kamis"',
        type: IslamicEventType.fastingHighlySunnah,
        color: mondayThursdayColor,
      ));
    }

    // ═══════════════════════════════════════════════════════════
    // PUASA AYYAMUL BIDH (13, 14, 15 setiap bulan Hijriah)
    // Dalil: HR. Nasa'i, HR. Tirmidzi, HR. Abu Daud (Shahih)
    // ═══════════════════════════════════════════════════════════
    if (day == 13 || day == 14 || day == 15) {
      // Kecuali di bulan Dzulhijjah tanggal 13 (Hari Tasyrik - haram puasa)
      if (!(month == 12 && day == 13)) {
        events.add(IslamicEvent(
          name: 'Ayyamul Bidh',
          description: 'Puasa tanggal 13-15 (hari putih)',
          dalil:
              'HR. Nasa\'i & Tirmidzi: "Rasulullah memerintahkan kami berpuasa pada ayyamul bidh: tanggal 13, 14, 15"',
          type: IslamicEventType.fastingSunnah,
          color: ayyamulBidhColor,
        ));
      }
    }

    // ═══════════════════════════════════════════════════════════
    // BULAN 1: MUHARRAM
    // ═══════════════════════════════════════════════════════════
    if (month == 1) {
      // Puasa Tasu'a (9 Muharram)
      // Dalil: HR. Muslim no. 1134
      if (day == 9) {
        events.add(IslamicEvent(
          name: 'Puasa Tasu\'a',
          description: '9 Muharram - Puasa sebelum Asyura',
          dalil:
              'HR. Muslim: "Jika aku hidup sampai tahun depan, aku akan berpuasa pada tanggal 9"',
          type: IslamicEventType.fastingSunnah,
          color: muharramColor,
        ));
      }

      // Puasa Asyura (10 Muharram) - SANGAT DIANJURKAN
      // Dalil: HR. Muslim no. 1162, HR. Bukhari
      if (day == 10) {
        events.add(IslamicEvent(
          name: 'Puasa Asyura',
          description: 'Menghapus dosa 1 tahun yang lalu',
          dalil:
              'HR. Muslim: "Puasa \'Asyura menghapus dosa satu tahun yang lalu"',
          type: IslamicEventType.fastingHighlySunnah,
          color: muharramColor,
        ));
      }

      // Puasa di bulan Muharram (selain Tasu'a & Asyura)
      // Dalil: HR. Muslim no. 1163
      if (day >= 1 && day <= 29 && day != 9 && day != 10) {
        events.add(IslamicEvent(
          name: 'Puasa Muharram',
          description: 'Puasa sunnah bulan Muharram',
          dalil:
              'HR. Muslim: "Puasa paling utama setelah Ramadhan adalah puasa bulan Allah (Muharram)"',
          type: IslamicEventType.fastingSunnah,
          color: muharramColor,
        ));
      }
    }

    // ═══════════════════════════════════════════════════════════
    // BULAN 8: Syakban
    // Rasulullah banyak berpuasa di bulan Syakban
    // Dalil: HR. Bukhari & Muslim dari Aisyah RA
    // ═══════════════════════════════════════════════════════════
    if (month == 8 && day >= 1 && day <= 28) {
      // Tidak berpuasa setelah pertengahan Syakban
      // Dalil: HR. Abu Daud, Tirmidzi, Nasa'i, Ibnu Majah
      events.add(IslamicEvent(
        name: 'Puasa Syakban',
        description: 'Rasulullah banyak berpuasa di Syakban',
        dalil:
            'HR. Bukhari & Muslim: "Tidak pernah aku melihat Rasulullah berpuasa lebih banyak kecuali di bulan Syakban"',
        type: IslamicEventType.fastingSunnah,
        color: shabanColor,
      ));
    }

    // ═══════════════════════════════════════════════════════════
    // BULAN 9: RAMADHAN - PUASA WAJIB
    // Dalil: QS. Al-Baqarah: 183, Hadits Mutawatir
    // ═══════════════════════════════════════════════════════════
    if (month == 9 && day >= 1 && day <= 29) {
      events.add(IslamicEvent(
        name: 'Puasa Ramadhan',
        description: 'Hari ke-$day Ramadhan - Puasa Wajib',
        dalil:
            'QS. Al-Baqarah 183: "Wahai orang-orang yang beriman, diwajibkan atas kamu berpuasa..."',
        type: IslamicEventType.fastingObligatory,
        color: ramadhanColor,
      ));
    }

    // ═══════════════════════════════════════════════════════════
    // BULAN 10: SYAWAL
    // ═══════════════════════════════════════════════════════════
    if (month == 10) {
      // 1 Syawal - IDUL FITRI (HARAM PUASA)
      // Dalil: HR. Bukhari no. 1992, Muslim no. 827
      if (day == 1) {
        events.add(IslamicEvent(
          name: 'Idul Fitri',
          description: 'Hari Raya Idul Fitri - HARAM PUASA',
          dalil:
              'HR. Bukhari & Muslim: "Nabi melarang berpuasa pada hari Fitri dan hari Nahr (Idul Adha)"',
          type: IslamicEventType.forbiddenFasting,
          color: forbiddenColor,
        ));
      }

      // Puasa 6 hari di Syawal (hari 2-30)
      // Dalil: HR. Muslim no. 1164, HR. Ahmad
      if (day >= 2 && day <= 30) {
        events.add(IslamicEvent(
          name: 'Puasa Syawal',
          description: 'Puasa 6 hari Syawal (seperti puasa setahun)',
          dalil:
              'HR. Muslim: "Siapa berpuasa Ramadhan lalu diikuti 6 hari Syawal, seperti puasa setahun"',
          type: IslamicEventType.fastingHighlySunnah,
          color: syawalColor,
        ));
      }
    }

    // ═══════════════════════════════════════════════════════════
    // BULAN 12: DZULHIJJAH
    // ═══════════════════════════════════════════════════════════
    if (month == 12) {
      // Puasa 9 hari pertama Dzulhijjah (1-9)
      // Dalil: HR. Bukhari: "Tidak ada hari yang amal shalih lebih dicintai Allah selain 10 hari (awal Dzulhijjah)"
      if (day >= 1 && day <= 8) {
        events.add(IslamicEvent(
          name: 'Puasa Dzulhijjah',
          description: 'Puasa di 10 hari pertama Dzulhijjah',
          dalil:
              'HR. Bukhari: "Tidak ada hari yang amal shalih lebih dicintai Allah selain 10 hari ini (awal Dzulhijjah)"',
          type: IslamicEventType.fastingSunnah,
          color: arfahColor,
        ));
      }

      // Puasa Arafah (9 Dzulhijjah) - SANGAT DIANJURKAN
      // Dalil: HR. Muslim no. 1162
      // CATATAN: Bagi yang TIDAK sedang haji
      if (day == 9) {
        events.add(IslamicEvent(
          name: 'Puasa Arafah',
          description: 'Menghapus dosa 2 tahun (lalu & akan datang)',
          dalil:
              'HR. Muslim: "Puasa Arafah menghapus dosa setahun lalu dan setahun akan datang"',
          type: IslamicEventType.fastingHighlySunnah,
          color: arfahColor,
        ));
      }

      // 10 Dzulhijjah - IDUL ADHA (HARAM PUASA)
      // Dalil: HR. Bukhari & Muslim
      if (day == 10) {
        events.add(IslamicEvent(
          name: 'Idul Adha',
          description: 'Hari Raya Idul Adha - HARAM PUASA',
          dalil:
              'HR. Bukhari & Muslim: "Nabi melarang berpuasa pada hari Fitri dan hari Nahr"',
          type: IslamicEventType.forbiddenFasting,
          color: forbiddenColor,
        ));
      }

      // Hari Tasyrik (11, 12, 13 Dzulhijjah) - HARAM PUASA
      // Dalil: HR. Muslim no. 1141, HR. Ahmad
      if (day == 11 || day == 12 || day == 13) {
        events.add(IslamicEvent(
          name: 'Hari Tasyrik',
          description: 'Hari ke-$day Tasyrik - HARAM PUASA',
          dalil:
              'HR. Muslim: "Hari-hari Tasyrik adalah hari makan, minum, dan berdzikir kepada Allah"',
          type: IslamicEventType.forbiddenFasting,
          color: forbiddenColor,
        ));
      }
    }

    return events;
  }

  /// Mendapatkan warna untuk cell kalender berdasarkan prioritas event
  static Color? getEventColor(int year, int month, int day, int weekday) {
    List<IslamicEvent> events =
        getEventsForHijriDate(year, month, day, weekday);

    if (events.isEmpty) return null;

    // Prioritas warna: Haram Puasa > Wajib > Sunnah Muakkad > Sunnah
    if (events.any((e) => e.type == IslamicEventType.forbiddenFasting)) {
      return forbiddenColor;
    }
    if (events.any((e) => e.type == IslamicEventType.fastingObligatory)) {
      return ramadhanColor;
    }
    if (events.any((e) => e.type == IslamicEventType.fastingHighlySunnah)) {
      return events
          .firstWhere((e) => e.type == IslamicEventType.fastingHighlySunnah)
          .color;
    }
    if (events.any((e) => e.type == IslamicEventType.fastingSunnah)) {
      return events
          .firstWhere((e) => e.type == IslamicEventType.fastingSunnah)
          .color;
    }

    return events.first.color;
  }

  /// Mendapatkan emoji/icon untuk jenis event
  static String getEventIcon(IslamicEventType type) {
    switch (type) {
      case IslamicEventType.fastingObligatory:
        return '✓'; // Wajib
      case IslamicEventType.fastingHighlySunnah:
        return '★'; // Sunnah Muakkad
      case IslamicEventType.fastingSunnah:
        return '○'; // Sunnah
      case IslamicEventType.forbiddenFasting:
        return '✕'; // Haram
      case IslamicEventType.specialDay:
        return '◆'; // Hari Khusus
    }
  }
}