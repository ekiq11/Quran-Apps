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

class _IslamicDashboardPageState extends State<IslamicDashboardPage>
    with SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeProvider();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: AppAnimations.long,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController!,
      curve: AppAnimations.defaultCurve,
    );

    _animationController!.forward();
  }

  void _initializeProvider() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
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
                child: CustomScrollView(
                  physics: AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: DashboardHeader(),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingLarge,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: _fadeAnimation != null
                            ? FadeTransition(
                                opacity: _fadeAnimation!,
                                child: Column(
                                  children: [
                                    
                                  ],
                                ),
                              )
                            : SizedBox.shrink(),
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