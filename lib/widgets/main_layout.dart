import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fin_track/core/theme.dart';
import 'package:fin_track/core/constants.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';

class MainLayout extends StatelessWidget {
  final Widget child;
  final String title;

  const MainLayout({
    super.key,
    required this.child,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < AppConstants.mobileBreakpoint;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: isMobile
          ? AppBar(
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              centerTitle: false,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: AppColors.background.withValues(alpha: 0.7)),
                ),
              ),
            )
          : null,
      drawer: isMobile ? _buildDrawer(context) : null,
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.background, Color(0xFF1A1D1F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Row(
            children: [
              if (!isMobile) _buildSidebar(context),
              Expanded(
                child: SafeArea(
                  top: isMobile,
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: AppConstants.maxWebWidth),
                      child: child,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            children: [
              const SizedBox(height: 60),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, size: 40, color: Colors.white),
              ).animate().scale(delay: 200.ms, duration: 600.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 20),
              Text(
                AppConstants.appName,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 50),
              _buildMenuItem(context, icon: Icons.grid_view_rounded, label: 'Dashboard', route: '/'),
              _buildMenuItem(context, icon: Icons.history_rounded, label: 'History', route: '/history'),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    _buildAddButton(context, isIncome: true),
                    const SizedBox(height: 16),
                    _buildAddButton(context, isIncome: false),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary.withValues(alpha: 0.2), Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_balance_wallet_rounded, size: 40, color: AppColors.primary),
                  const SizedBox(height: 12),
                  Text(
                    AppConstants.appName,
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          _buildDrawerItem(context, Icons.grid_view_rounded, 'Dashboard', '/'),
          _buildDrawerItem(context, Icons.history_rounded, 'History', '/history'),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Divider(color: Colors.white10),
          ),
          _buildDrawerItem(context, Icons.add_circle_outline, 'Income', '/add-income', color: AppColors.income),
          _buildDrawerItem(context, Icons.remove_circle_outline, 'Expense', '/add-expense', color: AppColors.expense),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String label, String route, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.textSecondary),
      title: Text(label, style: TextStyle(color: color ?? AppColors.textPrimary)),
      onTap: () {
        Navigator.pop(context);
        if (route == '/') {
          context.go(route);
        } else {
          context.push(route);
        }
      },
    );
  }

  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String label, required String route}) {
    final location = GoRouterState.of(context).uri.path;
    final isSelected = location == route;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: () => context.go(route),
        selected: isSelected,
        selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, {required bool isIncome}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isIncome ? AppColors.income : AppColors.expense).withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ElevatedButton(
        onPressed: () => context.push(isIncome ? '/add-income' : '/add-expense'),
        style: ElevatedButton.styleFrom(
          backgroundColor: isIncome ? AppColors.income : AppColors.expense,
          minimumSize: const Size.fromHeight(50),
          elevation: 0,
        ),
        child: Text(isIncome ? 'Income' : 'Expense'),
      ),
    );
  }
}
