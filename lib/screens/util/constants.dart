// screens/util/constants.dart
// ✅ Instagram-style Typography System — Inter font, proporsional
// Hierarki: Display → Title → Heading → Subheading → Body → Caption → Micro
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================================
// COLOR PALETTE
// ============================================================
class AppColors {
  // Primary — Brand Green
  static const Color primary     = Color(0xFF059669);
  static const Color primaryDark = Color(0xFF047857);
  static const Color primaryDeep = Color(0xFF065F46);

  // Secondary — Orange accent
  static const Color secondary     = Color(0xFFF97316);
  static const Color secondaryDark = Color(0xFFEA580C);

  // Purple — Dzikir
  static const Color purple     = Color(0xFF8B5CF6);
  static const Color purpleDark = Color(0xFF7C3AED);

  // Gold — Hijriah / Quran
  static const Color gold     = Color(0xFFD4AF37);
  static const Color goldDark = Color(0xFFB8860B);

  // Neutral
  static const Color textPrimary   = Color(0xFF111827); // Near-black
  static const Color textSecondary = Color(0xFF6B7280); // Gray-500
  static const Color textTertiary  = Color(0xFF9CA3AF); // Gray-400
  static const Color textDisabled  = Color(0xFFD1D5DB); // Gray-300

  static const Color background    = Color(0xFFF9FAFB); // Gray-50
  static const Color surface       = Colors.white;
  static const Color border        = Color(0xFFE5E7EB); // Gray-200
  static const Color borderLight   = Color(0xFFF3F4F6); // Gray-100
  static const Color divider       = Color(0xFFE5E7EB);

  // Semantic
  static const Color success = Color(0xFF059669);
  static const Color error   = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info    = Color(0xFF3B82F6);

  // Legacy aliases (backward compat)
  static const Color primaryLight  = Color(0xFFD1FAE5); // was ARB
  static const Color cardBackground = Colors.white;
  static const Color textLight = textTertiary;

  // Gradients
  static const List<Color> primaryGradient   = [primary, primaryDark];
  static const List<Color> secondaryGradient = [secondary, secondaryDark];
  static const List<Color> purpleGradient    = [purple, purpleDark];
  static const List<Color> headerGradient    = [Color(0xFF059669), Color(0xFF047857)];
}

// ============================================================
// TYPOGRAPHY — Instagram-style (Inter font)
// ============================================================
// Referensi hierarki ukuran Instagram/Meta:
//   Display  : 32px 800  — Angka besar, hero text
//   Title    : 24px 700  — Judul halaman
//   Heading  : 18px 700  — Judul section, card title
//   Subhead  : 15px 600  — Sub-judul, label penting
//   Body     : 14px 400  — Konten utama
//   BodySm   : 13px 400  — Konten sekunder
//   Caption  : 12px 400  — Label, timestamp
//   Micro    : 10px 500  — Badge, tag, counter
// ============================================================
class AppTextStyles {
  // ---------- DISPLAY (hero numbers, big stats) ----------
  static TextStyle display({Color? color}) =>
    GoogleFonts.inter(
      fontSize: 32,
      fontWeight: FontWeight.w800,
      color: color ?? AppColors.textPrimary,
      letterSpacing: -1.0,
      height: 1.1,
    );

  // Jam sholat — extra large clock
  static TextStyle clock({Color? color}) =>
    GoogleFonts.inter(
      fontSize: 48,
      fontWeight: FontWeight.w700,
      color: color ?? Colors.white,
      letterSpacing: -1.5,
      height: 1.0,
    );

  // ---------- TITLE (judul halaman, app bar) ----------
  static TextStyle title({Color? color, FontWeight? weight}) =>
    GoogleFonts.inter(
      fontSize: 22,
      fontWeight: weight ?? FontWeight.w700,
      color: color ?? AppColors.textPrimary,
      letterSpacing: -0.5,
      height: 1.25,
    );

  // App bar title — sedikit lebih kecil
  static TextStyle appBarTitle({Color? color}) =>
    GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: color ?? Colors.white,
      letterSpacing: -0.3,
    );

  // ---------- HEADING (section header, card title) ----------
  static TextStyle heading({Color? color, FontWeight? weight}) =>
    GoogleFonts.inter(
      fontSize: 17,
      fontWeight: weight ?? FontWeight.w700,
      color: color ?? AppColors.textPrimary,
      letterSpacing: -0.3,
      height: 1.3,
    );

  // ---------- SUBHEADING (sub-section, tab label, badge label) ----------
  static TextStyle subheading({Color? color, FontWeight? weight}) =>
    GoogleFonts.inter(
      fontSize: 15,
      fontWeight: weight ?? FontWeight.w600,
      color: color ?? AppColors.textPrimary,
      letterSpacing: -0.1,
      height: 1.35,
    );

  // ---------- BODY (main content) ----------
  static TextStyle body({Color? color, FontWeight? weight}) =>
    GoogleFonts.inter(
      fontSize: 14,
      fontWeight: weight ?? FontWeight.w400,
      color: color ?? AppColors.textPrimary,
      letterSpacing: 0,
      height: 1.5,
    );

  // Body semibold — untuk emphasis dalam konten
  static TextStyle bodySemibold({Color? color}) =>
    GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: color ?? AppColors.textPrimary,
      letterSpacing: 0,
      height: 1.5,
    );

  // Body small — konten sekunder
  static TextStyle bodySmall({Color? color, FontWeight? weight}) =>
    GoogleFonts.inter(
      fontSize: 13,
      fontWeight: weight ?? FontWeight.w400,
      color: color ?? AppColors.textSecondary,
      letterSpacing: 0,
      height: 1.45,
    );

  // ---------- CAPTION (label, timestamp, hint) ----------
  static TextStyle caption({Color? color, FontWeight? weight}) =>
    GoogleFonts.inter(
      fontSize: 12,
      fontWeight: weight ?? FontWeight.w400,
      color: color ?? AppColors.textSecondary,
      letterSpacing: 0.1,
      height: 1.4,
    );

  // ---------- MICRO (badge, counter, tag) ----------
  static TextStyle micro({Color? color, FontWeight? weight}) =>
    GoogleFonts.inter(
      fontSize: 10,
      fontWeight: weight ?? FontWeight.w600,
      color: color ?? Colors.white,
      letterSpacing: 0.2,
      height: 1.2,
    );

  // ---------- BUTTON ----------
  // Primary button — medium font
  static TextStyle button({Color? color}) =>
    GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: color ?? Colors.white,
      letterSpacing: 0,
    );

  // Secondary / text button — sedikit lebih kecil
  static TextStyle buttonSmall({Color? color}) =>
    GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: color ?? AppColors.primary,
      letterSpacing: 0,
    );

  // ---------- NAVIGATION LABEL ----------
  static TextStyle navLabel({Color? color}) =>
    GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: color ?? AppColors.textSecondary,
      letterSpacing: 0.1,
    );

  // ---------- PRAYER NAME (waktu sholat) ----------
  static TextStyle prayerLabel({Color? color}) =>
    GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: color ?? AppColors.textSecondary,
      letterSpacing: 0.3,
    );

  static TextStyle prayerTime({Color? color}) =>
    GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: color ?? AppColors.textPrimary,
      letterSpacing: -0.5,
    );

  // ---------- ARABIC TEXT (khusus font Amiri/Utsmani) ----------
  static const TextStyle arabicSmall = TextStyle(
    fontFamily: 'Utsmani',
    fontSize: 22,
    height: 2.0,
    color: AppColors.textPrimary,
  );

  static const TextStyle arabicMedium = TextStyle(
    fontFamily: 'Utsmani',
    fontSize: 28,
    height: 2.0,
    color: AppColors.textPrimary,
  );

  static const TextStyle arabicLarge = TextStyle(
    fontFamily: 'Utsmani',
    fontSize: 36,
    height: 2.0,
    color: AppColors.textPrimary,
  );

  // ---------- LEGACY (backward compat — prefer method variants) ----------
  static final TextStyle h1 = GoogleFonts.inter(
    fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.5,
  );
  static final TextStyle h2 = GoogleFonts.inter(
    fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.3,
  );
  static final TextStyle h3 = GoogleFonts.inter(
    fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.2,
  );
  static final TextStyle body1 = GoogleFonts.inter(
    fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.textPrimary,
  );
  static final TextStyle body2 = GoogleFonts.inter(
    fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary,
  );
  static final TextStyle captionStyle = GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textTertiary, letterSpacing: 0.1,
  );
  static const TextStyle prayerName = TextStyle(
    fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5,
  );
}

// ============================================================
// DIMENSIONS
// ============================================================
class AppDimensions {
  static const double paddingXS     = 4.0;
  static const double paddingSmall  = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge  = 24.0;
  static const double paddingXLarge = 32.0;

  static const double radiusXS     = 6.0;
  static const double radiusSmall  = 10.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge  = 24.0;
  static const double radiusXL     = 32.0;
  static const double radiusFull   = 999.0;

  static const double iconXS     = 14.0;
  static const double iconSmall  = 18.0;
  static const double iconMedium = 22.0;
  static const double iconLarge  = 28.0;
  static const double iconXLarge = 40.0;

  static const double cardHeightSmall  = 100.0;
  static const double cardHeightMedium = 140.0;
  static const double cardHeightLarge  = 200.0;
}

// ============================================================
// ANIMATIONS
// ============================================================
class AppAnimations {
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration short   = Duration(milliseconds: 200);
  static const Duration medium  = Duration(milliseconds: 350);
  static const Duration long    = Duration(milliseconds: 550);

  static const Curve defaultCurve  = Curves.easeInOut;
  static const Curve enterCurve    = Curves.easeOut;
  static const Curve exitCurve     = Curves.easeIn;
  static const Curve bounceCurve   = Curves.elasticOut;
  static const Curve springCurve   = Curves.bounceOut;
}

// ============================================================
// ASSETS
// ============================================================
class AppAssets {
  static const String iconQuran   = 'assets/other/iconquran.png';
  static const String iconApp     = 'assets/other/icon.png';
  static const String bismillah   = 'assets/image/img_bismillah.png';
  static const String adzanAudio  = 'assets/adzan/adzan.mp3';
}