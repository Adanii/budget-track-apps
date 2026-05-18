import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fin_track/core/theme.dart';
import 'package:fin_track/core/constants.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:ui';

import 'package:fin_track/providers/theme_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainLayout extends ConsumerWidget {
  final Widget child;
  final String title;
  final Widget? floatingActionButton;

  const MainLayout({
    super.key,
    required this.child,
    required this.title,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < AppConstants.mobileBreakpoint;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: isMobile
          ? AppBar(
              title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
              centerTitle: false,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: context.colors.background.withValues(alpha: 0.7),
                  ),
                ),
              ),
            )
          : null,
      drawer: isMobile ? _buildDrawer(context, ref) : null,
      floatingActionButton: floatingActionButton,
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: context.colors.backgroundGradient,
              ),
            ),
          ),
          Row(
            children: [
              if (!isMobile) _buildSidebar(context, ref),
              Expanded(
                child: SafeArea(
                  top: isMobile,
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(
                        maxWidth: AppConstants.maxWebWidth,
                      ),
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

  Widget _buildSidebar(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final showQuickTip = MediaQuery.of(context).size.height > 840;

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: context.colors.surface.withValues(alpha: 0.8),
        border: Border(right: BorderSide(color: context.colors.border)),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Branding ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 34, 24, 20),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: context.colors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: context.colors.primary.withValues(
                              alpha: 0.4,
                            ),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          width: 42,
                          height: 42,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppConstants.appName,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                        Text(
                          'Kelola keuangan Anda',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: context.colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05),

              // ── Collapsible Menus ─────────────────────────────────────
              _CollapsibleSection(
                title: 'MENU',
                horizontalPadding: 24,
                children: [
                  _buildMenuItem(
                    context,
                    location,
                    icon: Icons.grid_view_rounded,
                    label: 'Dashboard',
                    route: '/',
                  ),
                  _buildMenuItem(
                    context,
                    location,
                    icon: Icons.history_rounded,
                    label: 'History',
                    route: '/history',
                  ),
                  _buildMenuItem(
                    context,
                    location,
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Manajemen Wallet',
                    route: '/wallets',
                  ),
                ],
              ),
              SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CollapsibleSection(
                        title: 'TRANSAKSI',
                        horizontalPadding: 24,
                        children: [
                          _buildMenuItem(
                            context,
                            location,
                            icon: Icons.add_circle_outline_rounded,
                            label: 'Tambah Pemasukan',
                            route: '/add-income',
                            accentColor: context.colors.income,
                          ),
                          _buildMenuItem(
                            context,
                            location,
                            icon: Icons.remove_circle_outline_rounded,
                            label: 'Tambah Pengeluaran',
                            route: '/add-expense',
                            accentColor: context.colors.expense,
                          ),
                          _buildMenuItem(
                            context,
                            location,
                            icon: Icons.swap_horiz_rounded,
                            label: 'Transfer Saldo',
                            route: '/transfer',
                            accentColor: context.colors.primary,
                          ),
                          _buildMenuItem(
                            context,
                            location,
                            icon: Icons.tune_rounded,
                            label: 'Penyesuaian Saldo',
                            route: '/add-adjustment',
                            accentColor: Colors.grey,
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      _CollapsibleSection(
                        title: 'PLAN',
                        horizontalPadding: 24,
                        children: [
                          _buildMenuItem(
                            context,
                            location,
                            icon: Icons.travel_explore_rounded,
                            label: 'Travel Plan',
                            route: '/travel-plan',
                            accentColor: context.colors.info,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Theme Switcher ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isDark ? 'Dark Mode' : 'Light Mode',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.colors.textSecondary,
                      ),
                    ),
                    Switch(
                      value: isDark,
                      onChanged: (val) =>
                          ref.read(themeModeProvider.notifier).toggleTheme(),
                      activeThumbColor: context.colors.primary,
                    ),
                  ],
                ),
              ),

              // ── Bottom Quick Action ───────────────────────────────────
              if (showQuickTip) ...[
                _buildQuickTip(context),
                const SizedBox(height: 10),
              ],

              const SizedBox(height: 4),
              Center(
                child: FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final version = snapshot.hasData
                        ? snapshot.data!.version
                        : '1.0.0';
                    return Text(
                      'v$version',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: context.colors.textMuted,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickTip(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              context.colors.primary.withValues(alpha: 0.15),
              context.colors.card,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: context.colors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: context.colors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.tips_and_updates_rounded,
                    color: context.colors.primary,
                    size: 14,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Quick Tip',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: context.colors.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Catat setiap transaksi untuk laporan yang akurat.',
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: context.colors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadAPK(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final url = Uri.parse(
              'https://github.com/Adanii/budget-track-apps/releases',
            );
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF3DDC84).withValues(alpha: 0.2),
                  context.colors.card,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Color(0xFF3DDC84).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3DDC84).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.android_rounded,
                    color: Color(0xFF3DDC84),
                    size: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Download APK',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3DDC84),
                        ),
                      ),
                      Text(
                        'Android build',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: context.colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.download_rounded,
                  color: Color(0xFF3DDC84),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String location, {
    required IconData icon,
    required String label,
    required String route,
    Color? accentColor,
  }) {
    final isSelected = location == route;
    final color = accentColor ?? context.colors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => context.go(route),
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: isSelected
                  ? Border.all(color: color.withValues(alpha: 0.25))
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withValues(alpha: 0.15)
                        : context.colors.border.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: isSelected ? color : context.colors.textSecondary,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: isSelected
                          ? context.colors.textPrimary
                          : context.colors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    return Drawer(
      backgroundColor: context.colors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.colors.primary.withValues(alpha: 0.15),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: context.colors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/app_icon.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConstants.appName,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Kelola keuangan Anda',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: context.colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8),
                  _CollapsibleSection(
                    title: 'MENU',
                    horizontalPadding: 16,
                    children: [
                      _buildDrawerItem(
                        context,
                        location,
                        Icons.grid_view_rounded,
                        'Dashboard',
                        '/',
                      ),
                      _buildDrawerItem(
                        context,
                        location,
                        Icons.history_rounded,
                        'History',
                        '/history',
                      ),
                      _buildDrawerItem(
                        context,
                        location,
                        Icons.account_balance_wallet_rounded,
                        'Manajemen Wallet',
                        '/wallets',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  _CollapsibleSection(
                    title: 'TRANSAKSI',
                    horizontalPadding: 16,
                    children: [
                      _buildDrawerItem(
                        context,
                        location,
                        Icons.add_circle_outline_rounded,
                        'Tambah Pemasukan',
                        '/add-income',
                        color: context.colors.income,
                      ),
                      _buildDrawerItem(
                        context,
                        location,
                        Icons.remove_circle_outline_rounded,
                        'Tambah Pengeluaran',
                        '/add-expense',
                        color: context.colors.expense,
                      ),
                      _buildDrawerItem(
                        context,
                        location,
                        Icons.swap_horiz_rounded,
                        'Transfer Saldo',
                        '/transfer',
                        color: context.colors.primary,
                      ),
                      _buildDrawerItem(
                        context,
                        location,
                        Icons.tune_rounded,
                        'Penyesuaian Saldo',
                        '/add-adjustment',
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _CollapsibleSection(
                    title: 'PLAN',
                    horizontalPadding: 16,
                    children: [
                      _buildDrawerItem(
                        context,
                        location,
                        Icons.travel_explore_rounded,
                        'Travel Plan',
                        '/travel-plan',
                        color: context.colors.info,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // ── Theme Switcher for Drawer ────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isDark ? 'Dark Mode' : 'Light Mode',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textSecondary,
                  ),
                ),
                Switch(
                  value: isDark,
                  onChanged: (val) =>
                      ref.read(themeModeProvider.notifier).toggleTheme(),
                  activeThumbColor: context.colors.primary,
                ),
              ],
            ),
          ),
          _buildQuickTip(context),

          const SizedBox(height: 4),
          Center(
            child: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final version = snapshot.hasData
                    ? snapshot.data!.version
                    : '1.0.0';
                return Text(
                  'v$version',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: context.colors.textMuted,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    String location,
    IconData icon,
    String label,
    String route, {
    Color? color,
  }) {
    final isSelected = location == route;
    final itemColor = color ?? context.colors.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: isSelected
                ? itemColor.withValues(alpha: 0.15)
                : context.colors.border.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isSelected ? itemColor : context.colors.textSecondary,
            size: 16,
          ),
        ),
        title: Text(
          label,
          style: GoogleFonts.outfit(
            color:
                color ??
                (isSelected
                    ? context.colors.textPrimary
                    : context.colors.textSecondary),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
        selected: isSelected,
        selectedTileColor: itemColor.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {
          Navigator.pop(context);
          context.go(route);
        },
      ),
    );
  }
}

class _CollapsibleSection extends StatefulWidget {
  final String title;
  final List<Widget> children;
  final double horizontalPadding;

  const _CollapsibleSection({
    required this.title,
    required this.children,
    this.horizontalPadding = 24.0,
  });

  @override
  State<_CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<_CollapsibleSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              widget.horizontalPadding,
              8,
              widget.horizontalPadding,
              8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: context.colors.textMuted,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                Icon(
                  _isExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 16,
                  color: context.colors.textMuted,
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.children,
          ),
          crossFadeState: _isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}
