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
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _initializeProvider();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F172A) : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDarkMode 
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              )
            : LinearGradient(
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
                backgroundColor: isDarkMode ? const Color(0xFF334155) : AppColors.primary,
                strokeWidth: 3,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  cacheExtent: 500,
                  slivers: [
                    SliverToBoxAdapter(
                      child: RepaintBoundary(
                        child: DashboardHeader(
                          scrollController: _scrollController,
                        ),
                      ),
                    ),
                    const SliverPadding(
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