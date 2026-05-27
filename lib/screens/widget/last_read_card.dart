  // screens/dashboard/widgets/last_read_card.dart - FIXED DATA SYNC
  import 'package:flutter/material.dart';
  import 'package:flutter/services.dart';
  import 'package:myquran/screens/util/constants.dart';
  import '../../../quran/model/surah_model.dart';


  class LastReadCard extends StatelessWidget {
    final BookmarkModel? lastRead;
    final bool isLoading;
    final VoidCallback? onTap;

    const LastReadCard({
      Key? key,
      required this.lastRead,
      this.isLoading = false,
      this.onTap,
    }) : super(key: key);

    @override
    Widget build(BuildContext context) {
      // Get screen size for responsive design
      final screenWidth = MediaQuery.of(context).size.width;
      final isSmallScreen = screenWidth < 360;
      final isMediumScreen = screenWidth >= 360 && screenWidth < 400;
      
      if (isLoading) {
        return _buildLoadingCard(isSmallScreen, isMediumScreen);
      }

      return Container(
        width: double.infinity*4,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          child: InkWell(
            onTap: lastRead != null
                ? () {
                    HapticFeedback.lightImpact();
                    onTap?.call();
                  }
                : null,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 14 : AppDimensions.paddingLarge),
              child: Row(
                children: [
                  _buildIcon(isSmallScreen),
                  SizedBox(width: isSmallScreen ? 12 : AppDimensions.paddingMedium),
                  Expanded(child: _buildContent(isSmallScreen, isMediumScreen)),
                  if (lastRead != null)
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppColors.primary,
                      size: isSmallScreen ? 18 : 20,
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Widget _buildIcon(bool isSmallScreen) {
      return Container(
        padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.primaryGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: SizedBox(
          width: isSmallScreen ? 34 : 40,
          height: isSmallScreen ? 34 : 40,
          child: Image.asset(
            AppAssets.iconQuran,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.menu_book_rounded,
                color: Colors.white,
                size: isSmallScreen ? 30 : 36,
              );
            },
          ),
        ),
      );
    }

    Widget _buildContent(bool isSmallScreen, bool isMediumScreen) {
      // Tentukan ukuran font berdasarkan layar
      final titleFontSize = isSmallScreen ? 14.0 : (isMediumScreen ? 15.0 : 16.0);
      final subtitleFontSize = isSmallScreen ? 11.0 : (isMediumScreen ? 12.0 : 13.0);
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            lastRead != null ? 'Lanjutkan Membaca' : 'Tilawah Hari Ini',
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: 0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isSmallScreen ? 3 : 4),
          Text(
            lastRead != null
                ? '${lastRead!.surahName} - Ayat ${lastRead!.ayahNumber}'
                : 'Reminder: 05:30 & 18:30',
            style: TextStyle(
              fontSize: subtitleFontSize,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }

    Widget _buildLoadingCard(bool isSmallScreen, bool isMediumScreen) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(isSmallScreen ? 14 : AppDimensions.paddingLarge),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.secondaryGradient,
                ),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
              child: Icon(
                Icons.menu_book_rounded,
                color: Colors.white,
                size: isSmallScreen ? 24 : 28,
              ),
            ),
            SizedBox(width: isSmallScreen ? 12 : AppDimensions.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Memuat...',
                    style: AppTextStyles.body1.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 14 : null,
                    ),
                  ),
                  SizedBox(height: 4),
                  SizedBox(
                    width: isSmallScreen ? 14 : 16,
                    height: isSmallScreen ? 14 : 16,
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }