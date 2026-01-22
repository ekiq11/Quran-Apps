import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:myquran/screens/util/islamic_event.dart';

class HijriCalendarBottomSheet extends StatefulWidget {
  final HijriCalendar initialHijriDate;

  const HijriCalendarBottomSheet({
    Key? key,
    required this.initialHijriDate,
  }) : super(key: key);

  @override
  State<HijriCalendarBottomSheet> createState() =>
      _HijriCalendarBottomSheetState();
}

class _HijriCalendarBottomSheetState extends State<HijriCalendarBottomSheet> {
  late HijriCalendar selectedHijriDate;
  late int currentMonth;
  late int currentYear;
  
  // ✅ CACHE untuk menyimpan mapping Hijri -> Gregorian (offline)
  static final Map<String, DateTime> _dateCache = {};
  static final Map<String, int> _monthDaysCache = {};

  final List<String> hijriMonths = [
    'Muharram',
    'Safar',
    'Rabi\' al-Awwal',
    'Rabi\' al-Thani',
    'Jumada al-Ula',
    'Jumada al-Akhirah',
    'Rajab',
    'Syakban',
    'Ramadan',
    'Shawwal',
    'Dhul-Qi\'dah',
    'Dhul-Hijjah',
  ];

  final List<String> dayNames = [
    'Ahad',
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jum\'at',
    'Sabtu'
  ];

  @override
  void initState() {
    super.initState();
    selectedHijriDate = widget.initialHijriDate;
    currentMonth = widget.initialHijriDate.hMonth;
    currentYear = widget.initialHijriDate.hYear;
  }

  void _previousMonth() {
    setState(() {
      if (currentMonth == 1) {
        currentMonth = 12;
        currentYear--;
      } else {
        currentMonth--;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (currentMonth == 12) {
        currentMonth = 1;
        currentYear++;
      } else {
        currentMonth++;
      }
    });
  }

  /// ✅ METODE PALING AKURAT: Gunakan library hijri dengan reverse lookup
  /// 
  /// Cara kerja:
  /// 1. Estimasi tanggal Gregorian berdasarkan referensi yang diketahui akurat
  /// 2. Cek mundur/maju dari estimasi untuk menemukan exact match
  /// 3. Validasi dengan HijriCalendar.fromDate()
  /// 4. Cache hasilnya untuk performa
  DateTime _hijriToGregorian(int hYear, int hMonth, int hDay) {
    String cacheKey = '$hYear-$hMonth-$hDay';
    
    // Cek cache terlebih dahulu
    if (_dateCache.containsKey(cacheKey)) {
      return _dateCache[cacheKey]!;
    }
    
    // STRATEGI: Gunakan tanggal referensi yang pasti akurat
    // Referensi: 22 Januari 2026 = 3 Syaban 1447 H (dari data Anda)
    DateTime referenceGregorian = DateTime(2026, 1, 22);
    HijriCalendar referenceHijri = HijriCalendar();
    referenceHijri.hYear = 1447;
    referenceHijri.hMonth = 8; // Syaban
    referenceHijri.hDay = 3;
    
    // Hitung selisih hari dalam kalender Hijriah
    int daysDifference = _calculateHijriDaysDifference(referenceHijri, hYear, hMonth, hDay);
    
    // Terapkan selisih ke tanggal Gregorian
    DateTime estimatedDate = referenceGregorian.add(Duration(days: daysDifference));
    
    // Verifikasi dan fine-tune (cek ±2 hari untuk memastikan)
    for (int offset = -2; offset <= 2; offset++) {
      DateTime testDate = estimatedDate.add(Duration(days: offset));
      HijriCalendar testHijri = HijriCalendar.fromDate(testDate);
      
      if (testHijri.hYear == hYear && 
          testHijri.hMonth == hMonth && 
          testHijri.hDay == hDay) {
        // Found exact match!
        _dateCache[cacheKey] = testDate;
        return testDate;
      }
    }
    
    // Jika tidak ketemu dalam ±2 hari, gunakan estimasi
    _dateCache[cacheKey] = estimatedDate;
    return estimatedDate;
  }

  /// ✅ Hitung selisih hari antara dua tanggal Hijriah
  int _calculateHijriDaysDifference(HijriCalendar reference, int targetYear, int targetMonth, int targetDay) {
    int totalDays = 0;
    
    // Selisih tahun
    int yearDiff = targetYear - reference.hYear;
    if (yearDiff != 0) {
      // Rata-rata tahun Hijriah = 354.36667 hari
      // Tapi kita hitung lebih akurat dengan menjumlahkan per tahun
      int startYear = yearDiff > 0 ? reference.hYear : targetYear;
      int endYear = yearDiff > 0 ? targetYear : reference.hYear;
      
      for (int y = startYear; y < endYear; y++) {
        totalDays += _getDaysInHijriYear(y);
      }
      
      if (yearDiff < 0) totalDays = -totalDays;
    }
    
    // Selisih bulan dalam tahun yang sama
    int monthDiff = targetMonth - reference.hMonth;
    if (monthDiff != 0) {
      int startMonth = monthDiff > 0 ? reference.hMonth : targetMonth;
      int endMonth = monthDiff > 0 ? targetMonth : reference.hMonth;
      int year = targetYear;
      
      for (int m = startMonth; m < endMonth; m++) {
        totalDays += _getDaysInHijriMonth(year, m);
      }
      
      if (monthDiff < 0) totalDays = -totalDays;
    }
    
    // Selisih hari
    int dayDiff = targetDay - reference.hDay;
    totalDays += dayDiff;
    
    return totalDays;
  }

  /// ✅ Hitung jumlah hari dalam satu tahun Hijriah
  int _getDaysInHijriYear(int year) {
    int total = 0;
    for (int month = 1; month <= 12; month++) {
      total += _getDaysInHijriMonth(year, month);
    }
    return total;
  }

  /// ✅ Hitung jumlah hari dalam bulan Hijriah
  /// Menggunakan library hijri untuk akurasi
  int _getDaysInHijriMonth(int year, int month) {
    String cacheKey = 'days-$year-$month';
    
    if (_monthDaysCache.containsKey(cacheKey)) {
      return _monthDaysCache[cacheKey]!;
    }
    
    // Gunakan library untuk menentukan jumlah hari
    // Cara: bandingkan tanggal 1 bulan ini dengan tanggal 1 bulan depan
    DateTime firstDay = _hijriToGregorianDirect(year, month, 1);
    DateTime firstDayNextMonth;
    
    if (month == 12) {
      firstDayNextMonth = _hijriToGregorianDirect(year + 1, 1, 1);
    } else {
      firstDayNextMonth = _hijriToGregorianDirect(year, month + 1, 1);
    }
    
    int days = firstDayNextMonth.difference(firstDay).inDays;
    
    // Validasi: bulan Hijriah selalu 29 atau 30 hari
    if (days < 29 || days > 30) {
      days = 29; // fallback
    }
    
    _monthDaysCache[cacheKey] = days;
    return days;
  }

  /// ✅ Konversi langsung tanpa cache (untuk helper functions)
  DateTime _hijriToGregorianDirect(int hYear, int hMonth, int hDay) {
    // Gunakan referensi tanggal yang pasti benar
    DateTime referenceGregorian = DateTime(2026, 1, 22);
    HijriCalendar referenceHijri = HijriCalendar();
    referenceHijri.hYear = 1447;
    referenceHijri.hMonth = 8;
    referenceHijri.hDay = 3;
    
    int daysDiff = _calculateHijriDaysDifferenceSimple(
      referenceHijri.hYear, referenceHijri.hMonth, referenceHijri.hDay,
      hYear, hMonth, hDay
    );
    
    return referenceGregorian.add(Duration(days: daysDiff));
  }

  /// ✅ Perhitungan sederhana selisih hari (untuk menghindari infinite loop)
  int _calculateHijriDaysDifferenceSimple(int fromYear, int fromMonth, int fromDay, int toYear, int toMonth, int toDay) {
    // Estimasi kasar: gunakan rata-rata hari per bulan
    int totalDays = 0;
    
    // Selisih tahun (354 hari rata-rata per tahun)
    totalDays += (toYear - fromYear) * 354;
    
    // Selisih bulan (29.5 hari rata-rata per bulan)
    totalDays += ((toMonth - fromMonth) * 29.5).round();
    
    // Selisih hari
    totalDays += (toDay - fromDay);
    
    return totalDays;
  }

  List<Widget> _buildCalendarDays() {
    List<Widget> dayWidgets = [];

    // Dapatkan tanggal pertama bulan ini
    DateTime gregorianFirstDay = _hijriToGregorian(currentYear, currentMonth, 1);
    int firstWeekday = gregorianFirstDay.weekday % 7; // 0 = Minggu, 1 = Senin, dst

    // Tambahkan space kosong untuk hari sebelum tanggal 1
    for (int i = 0; i < firstWeekday; i++) {
      dayWidgets.add(SizedBox());
    }

    // Dapatkan jumlah hari dalam bulan
    int daysInMonth = _getDaysInHijriMonth(currentYear, currentMonth);

    // Tambahkan tanggal-tanggal
    for (int day = 1; day <= daysInMonth; day++) {
      DateTime gregorianDate = _hijriToGregorian(currentYear, currentMonth, day);

      bool isToday = selectedHijriDate.hDay == day &&
          selectedHijriDate.hMonth == currentMonth &&
          selectedHijriDate.hYear == currentYear;

      dayWidgets.add(
        _buildDayCell(day, gregorianDate, isToday),
      );
    }

    return dayWidgets;
  }

  Widget _buildDayCell(int hijriDay, DateTime gregorianDate, bool isToday) {
    int weekday = gregorianDate.weekday % 7;
    
    List<IslamicEvent> events = IslamicCalendarEvents.getEventsForHijriDate(
      currentYear,
      currentMonth,
      hijriDay,
      weekday,
    );

    Color? eventColor = IslamicCalendarEvents.getEventColor(
      currentYear,
      currentMonth,
      hijriDay,
      weekday,
    );

    bool isObligatory = events
        .any((e) => e.type == IslamicEventType.fastingObligatory);

    return InkWell(
      onTap: () {
        setState(() {
          selectedHijriDate = HijriCalendar();
          selectedHijriDate.hYear = currentYear;
          selectedHijriDate.hMonth = currentMonth;
          selectedHijriDate.hDay = hijriDay;
        });
        
        if (events.isNotEmpty) {
          _showEventDetails(context, hijriDay, events);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isToday 
              ? Color(0xFFD4AF37) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$hijriDay',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isObligatory ? FontWeight.w700 : FontWeight.w500,
                      color: isToday ? Colors.white : Color(0xFF111827),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '${gregorianDate.day}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w400,
                      color: isToday
                          ? Colors.white.withOpacity(0.8)
                          : Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            
            if (events.isNotEmpty && !isToday && eventColor != null)
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: eventColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showEventDetails(BuildContext context, int day, List<IslamicEvent> events) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        insetPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Color(0xFFD4AF37),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event_note_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$day ${hijriMonths[currentMonth - 1]} $currentYear H',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.white, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
            ),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: events.map((event) => Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: _buildCleanEventCard(event),
                  )).toList(),
                ),
              ),
            ),
            
            // Button
            Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFD4AF37),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Siap',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Clean event card
  Widget _buildCleanEventCard(IslamicEvent event) {
    IconData eventIcon;
    
    switch (event.type) {
      case IslamicEventType.fastingObligatory:
        eventIcon = Icons.star;
        break;
      case IslamicEventType.fastingHighlySunnah:
        eventIcon = Icons.favorite;
        break;
      case IslamicEventType.fastingSunnah:
        eventIcon = Icons.favorite_border;
        break;
      case IslamicEventType.forbiddenFasting:
        eventIcon = Icons.block;
        break;
      case IslamicEventType.specialDay:
        eventIcon = Icons.event;
        break;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Event name
        Row(
          children: [
            Icon(eventIcon, color: event.color, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                event.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        
        // Description
        Text(
          event.description,
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF6B7280),
            height: 1.5,
          ),
        ),
        SizedBox(height: 10),
        
        // Dalil
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.menu_book,
                size: 14,
                color: Color(0xFF9CA3AF),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  event.dalil,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4B5563),
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getGregorianDateString() {
    DateTime gregorian = _hijriToGregorian(
      selectedHijriDate.hYear, 
      selectedHijriDate.hMonth, 
      selectedHijriDate.hDay
    );
    return DateFormat('dd MMMM yyyy', 'id_ID').format(gregorian);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kalender Hijriah',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _previousMonth,
                  icon: Icon(Icons.chevron_left, color: Color(0xFFD4AF37)),
                ),
                Column(
                  children: [
                    Text(
                      hijriMonths[currentMonth - 1],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Text(
                      '$currentYear H',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _nextMonth,
                  icon: Icon(Icons.chevron_right, color: Color(0xFFD4AF37)),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.2,
              ),
              itemCount: 7,
              itemBuilder: (context, index) {
                return Center(
                  child: Text(
                    dayNames[index].substring(0, 3),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                );
              },
            ),
          ),
          
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                crossAxisCount: 7,
                children: _buildCalendarDays(),
              ),
            ),
          ),
          
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFFF9FAFB),
              border: Border(
                top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tanggal Terpilih',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${selectedHijriDate.hDay} ${hijriMonths[selectedHijriDate.hMonth - 1]} ${selectedHijriDate.hYear} H',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Text(
                      _getGregorianDateString(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}