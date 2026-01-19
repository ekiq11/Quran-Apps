// screens/quran_list_page.dart - FIXED
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myquran/quran/model/bookmark_model.dart';
import 'package:myquran/quran/model/surah_model.dart';
import 'package:myquran/quran/screens/read_page.dart';
import 'package:myquran/quran/screens/search_ayat.dart';
import 'package:myquran/quran/service/quran_service.dart';
import 'package:myquran/screens/util/constants.dart';
import 'dart:math' as math;

class QuranListPage extends StatefulWidget {
  const QuranListPage({Key? key}) : super(key: key);

  @override
  State<QuranListPage> createState() => _QuranListPageState();
}

class _QuranListPageState extends State<QuranListPage> {
  final QuranService _quranService = QuranService();
  
  // ✅ PERBAIKAN: Gunakan tipe yang benar
  List<SurahListModel> _surahList = [];
  List<SurahListModel> _filteredList = [];
  
  BookmarkModel? _lastRead;
  int _bookmarkCount = 0;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final surahList = await _quranService.loadSurahList();
    final lastRead = await _quranService.getLastRead();
    final bookmarks = await _quranService.getBookmarks();
    
    setState(() {
      // ✅ PERBAIKAN: Tidak perlu cast lagi
      _surahList = surahList;
      _filteredList = surahList;
      _lastRead = lastRead;
      _bookmarkCount = bookmarks.length;
      _isLoading = false;
    });
  }

  void _filterSurah(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredList = _surahList;
      } else {
        _filteredList = _surahList.where((surah) {
          // ✅ PERBAIKAN: Akses property langsung
          final nameLatin = surah.nameLatin.toLowerCase();
          final number = surah.number;
          final searchLower = query.toLowerCase();
          
          return nameLatin.contains(searchLower) || number.contains(searchLower);
        }).toList();
      }
    });
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years tahun lalu';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months bulan lalu';
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, isTablet),
          
          if (_lastRead != null || _bookmarkCount > 0)
            SliverToBoxAdapter(
              child: _buildQuickAccessCards(context, isTablet),
            ),
          
          SliverToBoxAdapter(
            child: _buildSearchBar(isTablet),
          ),
          
          if (_isLoading)
            SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            )
          else
            _buildSurahList(context, isTablet),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isTablet) {
    return SliverAppBar(
      expandedHeight: isTablet ? 220 : 200,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      elevation: 0,
      centerTitle: true,
      actions: [
        Container(
          margin: EdgeInsets.only(right: 8, top: 8, bottom: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.25),
                Colors.white.withOpacity(0.15),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchAyatPage(),
                ),
              );
            },
            icon: Icon(
              Icons.search_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ],
      flexibleSpace: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double top = constraints.biggest.height;
          final double expandedHeight = isTablet ? 220.0 : 200.0;
          final double collapsedHeight = kToolbarHeight + MediaQuery.of(context).padding.top;
          final double scrollProgress = ((expandedHeight - top) / (expandedHeight - collapsedHeight)).clamp(0.0, 1.0);
          final double titleTop = MediaQuery.of(context).padding.top + (kToolbarHeight - 24) / 2;
          
          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF059669),
                      Color(0xFF047857),
                    ],
                  ),
                ),
              ),
              
              Positioned.fill(
                child: Opacity(
                  opacity: 0.08,
                  child: CustomPaint(
                    painter: IslamicPatternPainter(),
                  ),
                ),
              ),
              
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color(0xFFFFD700).withOpacity(0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              
              Positioned(
                left: -30,
                bottom: 30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              
              if (scrollProgress < 0.8)
                Positioned.fill(
                  child: Opacity(
                    opacity: (1.0 - scrollProgress).clamp(0.0, 1.0),
                    child: SafeArea(
                      child: Center(
                        child: SingleChildScrollView(
                          physics: NeverScrollableScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildOrnamentalDivider(isTablet),
                              SizedBox(height: isTablet ? 12 : 10),
                              Image.asset(
                                'assets/other/iconquran.png',
                                width: isTablet ? 70 : 60,
                                height: isTablet ? 70 : 60,
                                color: Color(0xFFFFD700),
                                fit: BoxFit.contain,
                              ),
                              SizedBox(height: isTablet ? 10 : 8),
                              Text(
                                'Al-Qur\'an',
                                style: TextStyle(
                                  fontSize: isTablet ? 24 : 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: isTablet ? 12 : 10),
                              _buildOrnamentalDivider(isTablet),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              
              Positioned(
                top: titleTop,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: scrollProgress,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/other/iconquran.png',
                          width: 24,
                          height: 24,
                          color: Color(0xFFFFD700),
                          fit: BoxFit.contain,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Al-Qur\'an',
                          style: TextStyle(
                            fontSize: isTablet ? 18 : 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrnamentalDivider(bool isTablet) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildOrnament(),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 12),
          width: isTablet ? 50 : 40,
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Color(0xFFFFD700).withOpacity(0.6),
                Colors.transparent,
              ],
            ),
          ),
        ),
        _buildOrnament(),
      ],
    );
  }

  Widget _buildOrnament() {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Color(0xFFFFD700),
            Color(0xFFFFE55C),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFFFD700).withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessCards(BuildContext context, bool isTablet) {
    return Padding(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      child: Column(
        children: [
          if (_lastRead != null)
            Container(
              margin: EdgeInsets.only(bottom: isTablet ? 14 : 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF3B82F6).withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuranReadPage(
                          surahNumber: _lastRead!.surahNumber,
                          initialAyah: _lastRead!.ayahNumber,
                        ),
                      ),
                    );
                    _loadData();
                  },
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                  child: Padding(
                    padding: EdgeInsets.all(isTablet ? 24 : 20),
                    child: Row(
                      children: [
                        Container(
                          width: isTablet ? 64 : 56,
                          height: isTablet ? 64 : 56,
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                          ),
                          child: Image.asset(
                            AppAssets.iconQuran,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.menu_book_rounded,
                                color: Colors.white,
                                size: isTablet ? 36 : 32,
                              );
                            },
                          ),
                        ),
                        SizedBox(width: isTablet ? 20 : 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lanjutkan Membaca',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: isTablet ? 14 : 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                _lastRead!.surahName,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isTablet ? 20 : 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Ayat ${_lastRead!.ayahNumber}',
                                      style: TextStyle(
                                        fontSize: isTablet ? 12 : 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '• ${_getTimeAgo(_lastRead!.lastRead)}',
                                    style: TextStyle(
                                      fontSize: isTablet ? 12 : 11,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          
          if (_bookmarkCount > 0)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF047857)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuranBookmarksPage(),
                      ),
                    );
                    _loadData();
                  },
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                  child: Padding(
                    padding: EdgeInsets.all(isTablet ? 24 : 20),
                    child: Row(
                      children: [
                        Container(
                          width: isTablet ? 64 : 56,
                          height: isTablet ? 64 : 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.bookmarks_rounded,
                            color: Colors.white,
                            size: isTablet ? 32 : 28,
                          ),
                        ),
                        SizedBox(width: isTablet ? 20 : 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bookmark Saya',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isTablet ? 20 : 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '$_bookmarkCount ayat tersimpan',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: isTablet ? 14 : 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: isTablet ? 24 : 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isTablet) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 16,
        vertical: isTablet ? 16 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterSurah,
        decoration: InputDecoration(
          hintText: 'Cari surah...',
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: isTablet ? 16 : 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.primary,
            size: isTablet ? 26 : 22,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, size: isTablet ? 24 : 20),
                  onPressed: () {
                    _searchController.clear();
                    _filterSurah('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? 20 : 16,
            vertical: isTablet ? 18 : 14,
          ),
        ),
      ),
    );
  }

  Widget _buildSurahList(BuildContext context, bool isTablet) {
    return SliverPadding(
      padding: EdgeInsets.only(
        left: isTablet ? 24 : 16,
        right: isTablet ? 24 : 16,
        bottom: isTablet ? 24 : 16,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            // ✅ PERBAIKAN: Langsung gunakan SurahListModel
            final surah = _filteredList[index];
            return _buildSurahItem(context, surah, isTablet);
          },
          childCount: _filteredList.length,
        ),
      ),
    );
  }

  Widget _buildSurahItem(
    BuildContext context,
    SurahListModel surah, // ✅ PERBAIKAN: Tipe parameter yang benar
    bool isTablet,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 14 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            HapticFeedback.lightImpact();
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuranReadPage(
                  surahNumber: surah.id, // ✅ PERBAIKAN: Gunakan surah.id
                ),
              ),
            );
            _loadData();
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 18 : 14),
            child: Row(
              children: [
                Container(
                  width: isTablet ? 52 : 46,
                  height: isTablet ? 52 : 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF059669), Color(0xFF047857)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      surah.number, // ✅ PERBAIKAN: Akses property langsung
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: isTablet ? 18 : 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        surah.nameLatin, // ✅ PERBAIKAN
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${surah.numberOfAyah} Ayat', // ✅ PERBAIKAN
                        style: TextStyle(
                          fontSize: isTablet ? 14 : 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Image.asset(
                  'assets/image/sname_${surah.id}.png', // ✅ PERBAIKAN
                  width: isTablet ? 82 : 74,
                  height: isTablet ? 36 : 32,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Text(
                      surah.name, // ✅ PERBAIKAN
                      style: TextStyle(
                        fontFamily: 'Utsmani',
                        fontSize: isTablet ? 24 : 20,
                        color: AppColors.primary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class IslamicPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final spacing = 40.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        _drawStar(canvas, Offset(x, y), 15, paint);
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    const points = 8;
    const angle = (2 * math.pi) / points;

    for (int i = 0; i < points; i++) {
      final currentAngle = i * angle;
      final currentRadius = radius * 0.5 * (i.isEven ? 1 : 0.5);
      
      final x = center.dx + currentRadius * math.cos(currentAngle);
      final y = center.dy + currentRadius * math.sin(currentAngle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}