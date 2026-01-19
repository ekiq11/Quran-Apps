// screens/search_ayat_page.dart - PROFESSIONAL & POWERFUL (FIXED)
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myquran/quran/service/search_service.dart';
import 'package:myquran/quran/screens/read_page.dart';

class SearchAyatPage extends StatefulWidget {
  const SearchAyatPage({Key? key}) : super(key: key);

  @override
  State<SearchAyatPage> createState() => _SearchAyatPageState();
}

class _SearchAyatPageState extends State<SearchAyatPage> {
  final SearchService _searchService = SearchService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  
  List<SearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _searchInArabic = true;
  bool _searchInTranslation = true;
  String _errorMessage = '';
  Timer? _debounce;
  bool _isDirectSearch = false;

  late double _scaleFactor;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _calculateResponsiveSizes(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < 360) {
      _scaleFactor = 0.85;
    } else if (width < 400) {
      _scaleFactor = 0.9;
    } else if (width < 600) {
      _scaleFactor = 1.0;
    } else if (width < 800) {
      _scaleFactor = 1.1;
    } else {
      _scaleFactor = 1.2;
    }
  }

  double _fontSize(double size) => size * _scaleFactor;
  double _spacing(double size) => size * _scaleFactor;

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _performSearch();
    });
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _errorMessage = '';
        _isDirectSearch = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = '';
    });

    try {
      List<SearchResult> results;
      
      if (_searchInArabic && _searchInTranslation) {
        results = await _searchService.searchAll(query);
      } else if (_searchInArabic) {
        results = await _searchService.searchByArabicText(query);
      } else if (_searchInTranslation) {
        results = await _searchService.searchByTranslation(query);
      } else {
        results = [];
      }

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
          _isDirectSearch = results.isNotEmpty && results.first.type == SearchResultType.direct;
          
          if (results.isEmpty && query.length >= 3) {
            _errorMessage = 'Tidak ditemukan hasil';
          } else if (results.isEmpty && query.length < 3) {
            _errorMessage = 'Minimal 3 karakter';
          }
        });
        
        if (_isDirectSearch && results.isNotEmpty) {
          _openDirectResult(results.first);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Terjadi kesalahan';
          _isSearching = false;
        });
      }
    }
  }

  void _openDirectResult(SearchResult result) {
    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuranReadPage(
              surahNumber: int.parse(result.surahNumber),
              initialAyah: result.ayatNumber,
            ),
          ),
        );
      }
    });
  }

  void _toggleSearchArabic(bool value) {
    if (!value && !_searchInTranslation) return;
    
    setState(() {
      _searchInArabic = value;
    });
    if (_searchController.text.length >= 3) {
      _performSearch();
    }
  }

  void _toggleSearchTranslation(bool value) {
    if (!value && !_searchInArabic) return;
    
    setState(() {
      _searchInTranslation = value;
    });
    if (_searchController.text.length >= 3) {
      _performSearch();
    }
  }

@override
Widget build(BuildContext context) {
  _calculateResponsiveSizes(context);

  return Scaffold(
    body: Container(
      // Gradient yang sama persis dengan header
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF059669), Color(0xFF047857)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header dengan gradien yang sama
            _buildHeader(context),
            
            // Konten dengan background putih
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    // Search bar dan options dalam container putih
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildSearchBar(),
                          if (!_isDirectSearch) _buildSearchOptions(),
                          if (!_isDirectSearch && _searchResults.isNotEmpty)
                            SizedBox(height: _spacing(16)),
                        ],
                      ),
                    ),
                    
                    // Results area
                    Expanded(
                      child: Container(
                        color: Colors.white,
                        child: _buildSearchResults(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildHeader(BuildContext context) {
  return Container(
    width: double.infinity,
    // Gradient dihapus karena sudah ada di parent
    decoration: BoxDecoration(
      boxShadow: [
        BoxShadow(
          color: Color(0xFF059669).withOpacity(0.25),
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _spacing(16),
        vertical: _spacing(14),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back_rounded, color: Colors.white),
              iconSize: _fontSize(24),
              padding: EdgeInsets.all(_spacing(8)),
              constraints: BoxConstraints(),
            ),
          ),
          SizedBox(width: _spacing(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Pencarian Ayat',
                  style: TextStyle(
                    fontSize: _fontSize(20),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Cari dalam Al-Qur\'an',
                  style: TextStyle(
                    fontSize: _fontSize(12),
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(_spacing(16)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: _spacing(48),
              height: _spacing(56),
              alignment: Alignment.center,
              child: Container(
                width: _spacing(36),
                height: _spacing(36),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF047857)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.search_rounded,
                  color: Colors.white,
                  size: _fontSize(20),
                ),
              ),
            ),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                autofocus: false,
                decoration: InputDecoration(
                  hintText: 'Cari ayat atau ketik "9:10"',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: _fontSize(14),
                    height: 1.2,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: _spacing(18),
                  ),
                  isDense: true,
                ),
                style: TextStyle(
                  fontSize: _fontSize(14),
                  height: 1.2,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
            Container(
              width: _spacing(48),
              height: _spacing(56),
              alignment: Alignment.center,
              child: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        size: _fontSize(20),
                        color: Colors.grey[400],
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults = [];
                          _errorMessage = '';
                          _isDirectSearch = false;
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(
                        minWidth: _spacing(40),
                        minHeight: _spacing(40),
                      ),
                    )
                  : _isSearching
                      ? SizedBox(
                          width: _spacing(20),
                          height: _spacing(20),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF059669),
                          ),
                        )
                      : SizedBox(width: _spacing(40)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchOptions() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _spacing(16)),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterChip(
              'Arab',
              Icons.text_fields_rounded,
              _searchInArabic,
              _toggleSearchArabic,
            ),
          ),
          SizedBox(width: _spacing(10)),
          Expanded(
            child: _buildFilterChip(
              'Terjemahan',
              Icons.translate_rounded,
              _searchInTranslation,
              _toggleSearchTranslation,
            ),
          ),
          if (_searchResults.isNotEmpty) ...[
            SizedBox(width: _spacing(10)),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: _spacing(12),
                vertical: _spacing(10),
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF047857)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF059669).withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: _fontSize(16),
                    color: Colors.white,
                  ),
                  SizedBox(width: _spacing(6)),
                  Text(
                    '${_searchResults.length}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: _fontSize(14),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    IconData icon,
    bool isSelected,
    Function(bool) onSelected,
  ) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onSelected(!isSelected);
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: _spacing(12),
          vertical: _spacing(10),
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF047857)],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Color(0xFF059669) : Colors.grey[300]!,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Color(0xFF059669).withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: _fontSize(16),
              color: isSelected ? Colors.white : Color(0xFF6B7280),
            ),
            SizedBox(width: _spacing(6)),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: _fontSize(12),
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Color(0xFF6B7280),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    if (_isSearching) return _buildLoadingState();
    if (_errorMessage.isNotEmpty) return _buildErrorState();
    if (_searchController.text.isEmpty) return _buildEmptyInputState();
    if (_searchResults.isEmpty) return _buildNoResultsState();
    if (_isDirectSearch) return _buildDirectSearchState();

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        _spacing(16), 0, _spacing(16), _spacing(80),
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) => _buildResultItem(context, _searchResults[index], index),
    );
  }

  Widget _buildDirectSearchState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(_spacing(24)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(_spacing(24)),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF047857)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF059669).withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.navigate_next_rounded,
                size: _fontSize(60),
                color: Colors.white,
              ),
            ),
            SizedBox(height: _spacing(20)),
            Text(
              'Ayat Ditemukan!',
              style: TextStyle(
                fontSize: _fontSize(20),
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            SizedBox(height: _spacing(10)),
            Text(
              'Membuka ${_searchResults.first.surahName}\nAyat ${_searchResults.first.ayatNumber}',
              style: TextStyle(
                fontSize: _fontSize(13),
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: _spacing(20)),
            CircularProgressIndicator(color: Color(0xFF059669), strokeWidth: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF059669), strokeWidth: 3),
          SizedBox(height: _spacing(16)),
          Text(
            'Mencari ayat...',
            style: TextStyle(
              fontSize: _fontSize(13),
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(_spacing(20)),
            decoration: BoxDecoration(
              color: Colors.red[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: _fontSize(50),
              color: Colors.red[400],
            ),
          ),
          SizedBox(height: _spacing(16)),
          Text(
            _errorMessage,
            style: TextStyle(fontSize: _fontSize(13), color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyInputState() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(_spacing(20)),
      child: Column(
        children: [
          SizedBox(height: _spacing(40)),
          Container(
            padding: EdgeInsets.all(_spacing(24)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF059669).withOpacity(0.1),
                  Color(0xFF047857).withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_rounded, size: _fontSize(60), color: Color(0xFF059669)),
          ),
          SizedBox(height: _spacing(20)),
          Text(
            'Cari Ayat Al-Qur\'an',
            style: TextStyle(
              fontSize: _fontSize(18),
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: _spacing(10)),
          Text(
            'Masukkan kata kunci dalam bahasa Arab\natau terjemahan Indonesia',
            style: TextStyle(fontSize: _fontSize(12), color: Colors.grey[600], height: 1.5),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: _spacing(28)),
          Container(
            padding: EdgeInsets.all(_spacing(16)),
            decoration: BoxDecoration(
              color: Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Color(0xFF059669).withOpacity(0.3), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(_spacing(8)),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFF059669), Color(0xFF047857)]),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.lightbulb_rounded, size: _fontSize(18), color: Colors.white),
                    ),
                    SizedBox(width: _spacing(10)),
                    Text(
                      'Tips Pencarian',
                      style: TextStyle(
                        fontSize: _fontSize(14),
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: _spacing(14)),
                _buildTipItem('Minimal 3 karakter'),
                _buildTipItem('"9:10" → Surat 9 Ayat 10'),
                _buildTipItem('"taubah 10" → At-Taubah:10'),
                _buildTipItem('"surat 2 ayat 255"'),
                _buildTipItem('"al-baqarah 255"'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: _spacing(8)),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, size: _fontSize(16), color: Color(0xFF059669)),
          SizedBox(width: _spacing(8)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: _fontSize(11), color: Color(0xFF064E3B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(_spacing(24)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(_spacing(24)),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.search_off_rounded, size: _fontSize(60), color: Colors.grey[400]),
            ),
            SizedBox(height: _spacing(20)),
            Text(
              'Tidak Ditemukan',
              style: TextStyle(
                fontSize: _fontSize(18),
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            SizedBox(height: _spacing(10)),
            Container(
              padding: EdgeInsets.symmetric(horizontal: _spacing(14), vertical: _spacing(8)),
              decoration: BoxDecoration(
                color: Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '"${_searchController.text}"',
                style: TextStyle(
                  fontSize: _fontSize(12),
                  color: Color(0xFF6B7280),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            SizedBox(height: _spacing(14)),
            Text(
              'Coba kata kunci berbeda atau\nperiksa ejaan pencarian',
              style: TextStyle(fontSize: _fontSize(11), color: Colors.grey[600], height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem(BuildContext context, SearchResult result, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: _spacing(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: Offset(0, 3),
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
                  surahNumber: int.parse(result.surahNumber),
                  initialAyah: result.ayatNumber,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(_spacing(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: _spacing(44),
                      height: _spacing(44),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFF059669), Color(0xFF047857)]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF059669).withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          result.surahNumber,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: _fontSize(15),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: _spacing(10)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            result.surahName,
                            style: TextStyle(
                              fontSize: _fontSize(15),
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 3),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: _spacing(6),
                              vertical: _spacing(3),
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFF059669).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Ayat ${result.ayatNumber}',
                              style: TextStyle(
                                fontSize: _fontSize(10),
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // FIXED: Penomoran urut dari 1
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: _spacing(10),
                        vertical: _spacing(6),
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF059669).withOpacity(0.15),
                            Color(0xFF047857).withOpacity(0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Color(0xFF059669).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: _fontSize(12),
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: _spacing(14)),
                Divider(height: 1, color: Colors.grey[200]),
                SizedBox(height: _spacing(14)),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(_spacing(14)),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFFFFF7ED), Color(0xFFFEF3C7)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    result.arabicText,
                    style: TextStyle(
                      fontSize: _fontSize(25),
                             fontFamily: 'Utsmani',
                            height: 1.85,
                            letterSpacing: 0,
                            fontWeight: FontWeight.w500,
                      color: Color(0xFF78350F),
                    ),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                ),
                SizedBox(height: _spacing(12)),
                Text(
                  result.translation,
                  style: TextStyle(
                    fontSize: _fontSize(12),
                    height: 1.6,
                    color: Color(0xFF374151),
                  ),
                  textAlign: TextAlign.justify,
                ),
                SizedBox(height: _spacing(12)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: _spacing(12),
                        vertical: _spacing(7),
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFF059669), Color(0xFF047857)]),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF059669).withOpacity(0.3),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Buka',
                            style: TextStyle(
                              fontSize: _fontSize(11),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: _spacing(5)),
                          Icon(Icons.arrow_forward_rounded, size: _fontSize(14), color: Colors.white),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}