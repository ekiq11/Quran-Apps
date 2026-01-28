// screens/dashboard/islamic_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myquran/provider/dashboard_provider.dart';
import 'package:myquran/screens/util/constants.dart';
import 'package:myquran/screens/widget/dashboard_header.dart';
import 'package:provider/provider.dart';
import '../../quran/screens/read_page.dart';

class IslamicDashboardPage extends StatefulWidget {
  const IslamicDashboardPage({Key? key}) : super(key: key);

  @override
  State<IslamicDashboardPage> createState() => _IslamicDashboardPageState();
}

class _IslamicDashboardPageState extends State<IslamicDashboardPage> {
  
  @override
  void initState() {
    super.initState();
    _initializeProvider();
  }

  void _initializeProvider() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().initialize();
    });
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.mediumImpact();
    await context.read<DashboardProvider>().refreshAll();
  }

  void _navigateToQuranRead(DashboardProvider provider) {
    if (provider.lastRead == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuranReadPage(
          surahNumber: provider.lastRead!.surahNumber,
          initialAyah: provider.lastRead!.ayahNumber,
        ),
      ),
    ).then((_) {
      if (mounted) {
        provider.loadLastRead();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.headerGradient,
          ),
        ),
        child: SafeArea(
          child: Consumer<DashboardProvider>(
            builder: (context, provider, child) {
              return RefreshIndicator(
                onRefresh: _handleRefresh,
                color: Colors.white,
                backgroundColor: AppColors.primary,
                strokeWidth: 3,
                // ✅ FIX: Urutan physics yang benar
                child: CustomScrollView(
                  physics: BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  // ✅ OPTIMASI: Tambahkan cacheExtent untuk smooth scrolling
                  cacheExtent: 500,
                  slivers: [
                    // ✅ OPTIMASI: Wrap dengan RepaintBoundary
                    SliverToBoxAdapter(
                      child: RepaintBoundary(
                        child: DashboardHeader(),
                      ),
                    ),
                    // ✅ HAPUS FadeTransition - tidak perlu untuk konten kosong
                    SliverPadding(
                      padding: EdgeInsets.only(bottom: 20),
                      sliver: SliverToBoxAdapter(
                        child: SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}