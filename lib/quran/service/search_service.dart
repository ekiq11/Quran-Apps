// service/search_service.dart - FIXED FOR CORRECT FILE PATHS
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';

class SearchResult {
  final String surahNumber;
  final String surahName;
  final int ayatNumber;
  final String arabicText;
  final String translation;
  final SearchResultType type;

  SearchResult({
    required this.surahNumber,
    required this.surahName,
    required this.ayatNumber,
    required this.arabicText,
    required this.translation,
    this.type = SearchResultType.text,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchResult &&
          runtimeType == other.runtimeType &&
          surahNumber == other.surahNumber &&
          ayatNumber == other.ayatNumber;

  @override
  int get hashCode => surahNumber.hashCode ^ ayatNumber.hashCode;
}

enum SearchResultType {
  text,
  direct,
}

class SearchService {
  final Map<int, _SurahData> _surahCache = {};
  static const int _maxResults = 100;

  // Mapping nama surah
  final Map<String, int> _surahNameMap = {
    'al-fatihah': 1, 'alfatihah': 1, 'fatihah': 1, 'al fatihah': 1, 'fatiha': 1,
    'al-baqarah': 2, 'albaqarah': 2, 'baqarah': 2, 'al baqarah': 2, 'baqoroh': 2,
    'ali imran': 3, 'al-imran': 3, 'al imran': 3, 'imran': 3,
    'an-nisa': 4, 'annisa': 4, 'nisa': 4, 'an nisa': 4,
    'al-maidah': 5, 'almaidah': 5, 'maidah': 5, 'al maidah': 5,
    'al-anam': 6, 'alanam': 6, 'anam': 6, 'al anam': 6,
    'al-araf': 7, 'alaraf': 7, 'araf': 7, 'al araf': 7,
    'al-anfal': 8, 'alanfal': 8, 'anfal': 8, 'al anfal': 8,
    'at-taubah': 9, 'attaubah': 9, 'taubah': 9, 'at taubah': 9, 'tawbah': 9,
    'yunus': 10, 'yusuf': 12, 'hud': 11,
    'ar-rad': 13, 'arrad': 13, 'rad': 13,
    'ibrahim': 14,
    'al-hijr': 15, 'alhijr': 15, 'hijr': 15,
    'an-nahl': 16, 'annahl': 16, 'nahl': 16,
    'al-isra': 17, 'alisra': 17, 'isra': 17,
    'al-kahf': 18, 'alkahf': 18, 'kahf': 18,
    'maryam': 19, 'mariam': 19,
    'taha': 20, 'ta-ha': 20, 'ta ha': 20,
    'al-anbiya': 21, 'alanbiya': 21, 'anbiya': 21,
    'al-hajj': 22, 'alhajj': 22, 'hajj': 22,
    'al-muminun': 23, 'almuminun': 23, 'muminun': 23,
    'an-nur': 24, 'annur': 24, 'nur': 24,
    'al-furqan': 25, 'alfurqan': 25, 'furqan': 25,
    'asy-syuara': 26, 'asysyuara': 26, 'syuara': 26,
    'an-naml': 27, 'annaml': 27, 'naml': 27,
    'al-qasas': 28, 'alqasas': 28, 'qasas': 28,
    'al-ankabut': 29, 'alankabut': 29, 'ankabut': 29,
    'ar-rum': 30, 'arrum': 30, 'rum': 30,
    'luqman': 31, 'lukman': 31,
    'as-sajdah': 32, 'assajdah': 32, 'sajdah': 32,
    'al-ahzab': 33, 'alahzab': 33, 'ahzab': 33,
    'saba': 34,
    'fatir': 35, 'fathir': 35,
    'yasin': 36, 'ya-sin': 36, 'ya sin': 36,
    'as-saffat': 37, 'assaffat': 37, 'saffat': 37,
    'sad': 38,
    'az-zumar': 39, 'azzumar': 39, 'zumar': 39,
    'ghafir': 40, 'gafir': 40,
    'fussilat': 41,
    'asy-syura': 42, 'asysyura': 42, 'syura': 42,
    'az-zukhruf': 43, 'azzukhruf': 43, 'zukhruf': 43,
    'ad-dukhan': 44, 'addukhan': 44, 'dukhan': 44,
    'al-jasiyah': 45, 'aljasiyah': 45, 'jasiyah': 45,
    'al-ahqaf': 46, 'alahqaf': 46, 'ahqaf': 46,
    'muhammad': 47,
    'al-fath': 48, 'alfath': 48, 'fath': 48,
    'al-hujurat': 49, 'alhujurat': 49, 'hujurat': 49,
    'qaf': 50,
    'az-zariyat': 51, 'azzariyat': 51, 'zariyat': 51,
    'at-tur': 52, 'attur': 52, 'tur': 52,
    'an-najm': 53, 'annajm': 53, 'najm': 53,
    'al-qamar': 54, 'alqamar': 54, 'qamar': 54,
    'ar-rahman': 55, 'arrahman': 55, 'rahman': 55,
    'al-waqiah': 56, 'alwaqiah': 56, 'waqiah': 56,
    'al-hadid': 57, 'alhadid': 57, 'hadid': 57,
    'al-mujadalah': 58, 'almujadalah': 58, 'mujadalah': 58,
    'al-hasyr': 59, 'alhasyr': 59, 'hasyr': 59,
    'al-mumtahanah': 60, 'almumtahanah': 60, 'mumtahanah': 60,
    'as-saff': 61, 'assaff': 61, 'saff': 61,
    'al-jumuah': 62, 'aljumuah': 62, 'jumuah': 62, 'jumat': 62,
    'al-munafiqun': 63, 'almunafiqun': 63, 'munafiqun': 63,
    'at-taghabun': 64, 'attaghabun': 64, 'taghabun': 64,
    'at-talaq': 65, 'attalaq': 65, 'talaq': 65,
    'at-tahrim': 66, 'attahrim': 66, 'tahrim': 66,
    'al-mulk': 67, 'almulk': 67, 'mulk': 67,
    'al-qalam': 68, 'alqalam': 68, 'qalam': 68, 'nun': 68,
    'al-haqqah': 69, 'alhaqqah': 69, 'haqqah': 69,
    'al-maarij': 70, 'almaarij': 70, 'maarij': 70,
    'nuh': 71, 'nooh': 71,
    'al-jinn': 72, 'aljinn': 72, 'jinn': 72, 'jin': 72,
    'al-muzzammil': 73, 'almuzzammil': 73, 'muzzammil': 73,
    'al-muddassir': 74, 'almuddassir': 74, 'muddassir': 74,
    'al-qiyamah': 75, 'alqiyamah': 75, 'qiyamah': 75,
    'al-insan': 76, 'alinsan': 76, 'insan': 76, 'dahr': 76,
    'al-mursalat': 77, 'almursalat': 77, 'mursalat': 77,
    'an-naba': 78, 'annaba': 78, 'naba': 78,
    'an-naziat': 79, 'annaziat': 79, 'naziat': 79,
    'abasa': 80,
    'at-takwir': 81, 'attakwir': 81, 'takwir': 81,
    'al-infitar': 82, 'alinfitar': 82, 'infitar': 82,
    'al-mutaffifin': 83, 'almutaffifin': 83, 'mutaffifin': 83,
    'al-insyiqaq': 84, 'alinsyiqaq': 84, 'insyiqaq': 84,
    'al-buruj': 85, 'alburuj': 85, 'buruj': 85,
    'at-tariq': 86, 'attariq': 86, 'tariq': 86,
    'al-ala': 87, 'alala': 87, 'ala': 87,
    'al-ghasyiyah': 88, 'alghasyiyah': 88, 'ghasyiyah': 88,
    'al-fajr': 89, 'alfajr': 89, 'fajr': 89,
    'al-balad': 90, 'albalad': 90, 'balad': 90,
    'asy-syams': 91, 'asysyams': 91, 'syams': 91,
    'al-lail': 92, 'allail': 92, 'lail': 92,
    'ad-duha': 93, 'adduha': 93, 'duha': 93,
    'asy-syarh': 94, 'asysyarh': 94, 'syarh': 94, 'insyirah': 94,
    'at-tin': 95, 'attin': 95, 'tin': 95,
    'al-alaq': 96, 'alalaq': 96, 'alaq': 96, 'iqra': 96,
    'al-qadr': 97, 'alqadr': 97, 'qadr': 97,
    'al-bayyinah': 98, 'albayyinah': 98, 'bayyinah': 98,
    'az-zalzalah': 99, 'azzalzalah': 99, 'zalzalah': 99,
    'al-adiyat': 100, 'aladiyat': 100, 'adiyat': 100,
    'al-qariah': 101, 'alqariah': 101, 'qariah': 101,
    'at-takasur': 102, 'attakasur': 102, 'takasur': 102,
    'al-asr': 103, 'alasr': 103, 'asr': 103,
    'al-humazah': 104, 'alhumazah': 104, 'humazah': 104,
    'al-fil': 105, 'alfil': 105, 'fil': 105,
    'quraisy': 106, 'quraysh': 106,
    'al-maun': 107, 'almaun': 107, 'maun': 107,
    'al-kausar': 108, 'alkausar': 108, 'kausar': 108, 'kautsar': 108,
    'al-kafirun': 109, 'alkafirun': 109, 'kafirun': 109,
    'an-nasr': 110, 'annasr': 110, 'nasr': 110,
    'al-lahab': 111, 'allahab': 111, 'lahab': 111, 'masad': 111,
    'al-ikhlas': 112, 'alikhlas': 112, 'ikhlas': 112, 'tauhid': 112,
    'al-falaq': 113, 'alfalaq': 113, 'falaq': 113,
    'an-nas': 114, 'annas': 114, 'nas': 114,
  };

  Future<_SurahData> _loadSurahToCache(int surahNumber) async {
    if (_surahCache.containsKey(surahNumber)) {
      return _surahCache[surahNumber]!;
    }

    try {
      // ✅ FIXED: Load ayat dengan format yang benar
      final ayahJson = await rootBundle.loadString(
        'assets/quran-json/ayat/arabic_verse_uthmani$surahNumber.json',
      );
      final ayahData = json.decode(ayahJson);

      // Load translation
      final translationJson = await rootBundle.loadString(
        'assets/quran-json/terjemahan/$surahNumber.json',
      );
      final translationData = json.decode(translationJson);

      // Load list surah untuk metadata
      final listSurahJson = await rootBundle.loadString(
        'assets/quran-json/surah/list-surah.json',
      );
      final List<dynamic> listSurah = json.decode(listSurahJson);
      final surahMeta = listSurah.firstWhere(
        (s) => s['id'] == surahNumber,
        orElse: () => null,
      );

      final data = _SurahData(
        id: ayahData['id'] ?? surahNumber,
        name: surahMeta?['ltn'] ?? translationData['name'] ?? '',
        arabicTexts: List<String>.from(ayahData['aya'] ?? []),
        translations: List<String>.from(translationData['ayaTranslation'] ?? []),
      );

      _surahCache[surahNumber] = data;
      return data;
    } catch (e) {
      print('Error loading surah $surahNumber: $e');
      rethrow;
    }
  }

  Map<String, dynamic>? _parseDirectQuery(String query) {
    final trimmed = query.trim().toLowerCase();
    
    // Format: "9:10"
    final pattern1 = RegExp(r'^(\d+)\s*[:]\s*(\d+)$');
    final match1 = pattern1.firstMatch(trimmed);
    if (match1 != null) {
      return {
        'surah': int.parse(match1.group(1)!),
        'ayat': int.parse(match1.group(2)!),
      };
    }

    // Format: "surat 9 ayat 10"
    final pattern2 = RegExp(r'(?:surat|surah|qs\.?)\s*(\d+)\s*(?:ayat|ayah|:)\s*(\d+)');
    final match2 = pattern2.firstMatch(trimmed);
    if (match2 != null) {
      return {
        'surah': int.parse(match2.group(1)!),
        'ayat': int.parse(match2.group(2)!),
      };
    }

    // Format: nama surah + nomor ayat
    for (var entry in _surahNameMap.entries) {
      final name = entry.key;
      final surahNum = entry.value;
      
      final pattern = RegExp('(?:^|\\s)$name(?:\\s+ayat)?\\s+(\\d+)(?:\\s|\$)');
      final match = pattern.firstMatch(trimmed);
      if (match != null) {
        return {
          'surah': surahNum,
          'ayat': int.parse(match.group(1)!),
        };
      }
    }

    return null;
  }

  Future<List<SearchResult>> searchAll(String query) async {
    final trimmed = query.trim();
    
    if (trimmed.isEmpty) return [];

    // Direct search
    final directQuery = _parseDirectQuery(trimmed);
    if (directQuery != null) {
      final surahNum = directQuery['surah'] as int;
      final ayatNum = directQuery['ayat'] as int;
      
      if (surahNum >= 1 && surahNum <= 114) {
        try {
          final surah = await _loadSurahToCache(surahNum);
          
          if (ayatNum > 0 && ayatNum <= surah.arabicTexts.length) {
            return [
              SearchResult(
                surahNumber: surah.id.toString(),
                surahName: surah.name,
                ayatNumber: ayatNum,
                arabicText: surah.arabicTexts[ayatNum - 1],
                translation: ayatNum <= surah.translations.length 
                    ? surah.translations[ayatNum - 1] 
                    : '',
                type: SearchResultType.direct,
              )
            ];
          }
        } catch (e) {
          print('Error loading direct query: $e');
        }
      }
      return [];
    }

    // Text search
    if (trimmed.length < 3) return [];

    final results = <SearchResult>{};
    final queryLower = trimmed.toLowerCase();
    final normalizedQuery = _normalizeArabic(trimmed);

    for (int surahNumber = 1; surahNumber <= 114; surahNumber++) {
      if (results.length >= _maxResults) break;
      
      try {
        final surah = await _loadSurahToCache(surahNumber);
        
        for (int i = 0; i < surah.arabicTexts.length; i++) {
          if (results.length >= _maxResults) break;
          
          final arabicText = surah.arabicTexts[i];
          final normalizedText = _normalizeArabic(arabicText);
          final translation = i < surah.translations.length 
              ? surah.translations[i] 
              : '';
          
          if (normalizedText.contains(normalizedQuery) || 
              translation.toLowerCase().contains(queryLower)) {
            results.add(SearchResult(
              surahNumber: surah.id.toString(),
              surahName: surah.name,
              ayatNumber: i + 1,
              arabicText: arabicText,
              translation: translation,
              type: SearchResultType.text,
            ));
          }
        }
      } catch (e) {
        print('Error searching surah $surahNumber: $e');
        continue;
      }
    }

    return results.toList();
  }

  Future<List<SearchResult>> searchByArabicText(String query) async {
    final results = <SearchResult>{};
    final normalizedQuery = _normalizeArabic(query.trim());
    
    if (normalizedQuery.isEmpty || normalizedQuery.length < 3) return [];

    for (int surahNumber = 1; surahNumber <= 114; surahNumber++) {
      if (results.length >= _maxResults) break;
      
      try {
        final surah = await _loadSurahToCache(surahNumber);
        
        for (int i = 0; i < surah.arabicTexts.length; i++) {
          if (results.length >= _maxResults) break;
          
          final arabicText = surah.arabicTexts[i];
          final normalizedText = _normalizeArabic(arabicText);
          
          if (normalizedText.contains(normalizedQuery)) {
            results.add(SearchResult(
              surahNumber: surah.id.toString(),
              surahName: surah.name,
              ayatNumber: i + 1,
              arabicText: arabicText,
              translation: i < surah.translations.length 
                  ? surah.translations[i] 
                  : '',
            ));
          }
        }
      } catch (e) {
        print('Error searching surah $surahNumber: $e');
        continue;
      }
    }

    return results.toList();
  }

  Future<List<SearchResult>> searchByTranslation(String query) async {
    final results = <SearchResult>{};
    final queryLower = query.trim().toLowerCase();
    
    if (queryLower.isEmpty || queryLower.length < 3) return [];

    for (int surahNumber = 1; surahNumber <= 114; surahNumber++) {
      if (results.length >= _maxResults) break;
      
      try {
        final surah = await _loadSurahToCache(surahNumber);
        
        for (int i = 0; i < surah.translations.length; i++) {
          if (results.length >= _maxResults) break;
          
          final translation = surah.translations[i].toLowerCase();
          
          if (translation.contains(queryLower)) {
            results.add(SearchResult(
              surahNumber: surah.id.toString(),
              surahName: surah.name,
              ayatNumber: i + 1,
              arabicText: i < surah.arabicTexts.length 
                  ? surah.arabicTexts[i] 
                  : '',
              translation: surah.translations[i],
            ));
          }
        }
      } catch (e) {
        print('Error searching surah $surahNumber: $e');
        continue;
      }
    }

    return results.toList();
  }

  String _normalizeArabic(String text) {
    return text
        .replaceAll(RegExp(r'[\u064B-\u0652]'), '')
        .replaceAll(RegExp(r'[\u0653-\u065F]'), '')
        .replaceAll(RegExp(r'[\u0670]'), '')
        .replaceAll('ٱ', 'ا')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه')
        .trim();
  }

  void clearCache() {
    _surahCache.clear();
  }
}

class _SurahData {
  final int id;
  final String name;
  final List<String> arabicTexts;
  final List<String> translations;

  _SurahData({
    required this.id,
    required this.name,
    required this.arabicTexts,
    required this.translations,
  });
}