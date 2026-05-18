import 'package:flutter/material.dart';

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color secondary;
  final Color accentCream;
  final Color softBeige;
  final Color background;
  final Color backgroundSecondary;
  final Color surface;
  final Color card;
  final Color divider;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textDisabled;
  final Color white;
  final Color success;
  final Color successLight;
  final Color warning;
  final Color warningLight;
  final Color error;
  final Color errorLight;
  final Color info;
  final Color infoLight;
  final LinearGradient primaryGradient;
  final LinearGradient premiumGradient;
  final LinearGradient backgroundGradient;
  
  // Legacy aliases
  final Color accent;
  final Color income;
  final Color expense;

  const AppColorsExtension({
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.secondary,
    required this.accentCream,
    required this.softBeige,
    required this.background,
    required this.backgroundSecondary,
    required this.surface,
    required this.card,
    required this.divider,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textDisabled,
    required this.white,
    required this.success,
    required this.successLight,
    required this.warning,
    required this.warningLight,
    required this.error,
    required this.errorLight,
    required this.info,
    required this.infoLight,
    required this.primaryGradient,
    required this.premiumGradient,
    required this.backgroundGradient,
    required this.accent,
    required this.income,
    required this.expense,
  });

  @override
  AppColorsExtension copyWith({
    Color? primary,
    Color? primaryDark,
    Color? primaryLight,
    Color? secondary,
    Color? accentCream,
    Color? softBeige,
    Color? background,
    Color? backgroundSecondary,
    Color? surface,
    Color? card,
    Color? divider,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textDisabled,
    Color? white,
    Color? success,
    Color? successLight,
    Color? warning,
    Color? warningLight,
    Color? error,
    Color? errorLight,
    Color? info,
    Color? infoLight,
    LinearGradient? primaryGradient,
    LinearGradient? premiumGradient,
    LinearGradient? backgroundGradient,
    Color? accent,
    Color? income,
    Color? expense,
  }) {
    return AppColorsExtension(
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      primaryLight: primaryLight ?? this.primaryLight,
      secondary: secondary ?? this.secondary,
      accentCream: accentCream ?? this.accentCream,
      softBeige: softBeige ?? this.softBeige,
      background: background ?? this.background,
      backgroundSecondary: backgroundSecondary ?? this.backgroundSecondary,
      surface: surface ?? this.surface,
      card: card ?? this.card,
      divider: divider ?? this.divider,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textDisabled: textDisabled ?? this.textDisabled,
      white: white ?? this.white,
      success: success ?? this.success,
      successLight: successLight ?? this.successLight,
      warning: warning ?? this.warning,
      warningLight: warningLight ?? this.warningLight,
      error: error ?? this.error,
      errorLight: errorLight ?? this.errorLight,
      info: info ?? this.info,
      infoLight: infoLight ?? this.infoLight,
      primaryGradient: primaryGradient ?? this.primaryGradient,
      premiumGradient: premiumGradient ?? this.premiumGradient,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      accent: accent ?? this.accent,
      income: income ?? this.income,
      expense: expense ?? this.expense,
    );
  }

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) {
      return this;
    }
    return AppColorsExtension(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      accentCream: Color.lerp(accentCream, other.accentCream, t)!,
      softBeige: Color.lerp(softBeige, other.softBeige, t)!,
      background: Color.lerp(background, other.background, t)!,
      backgroundSecondary: Color.lerp(backgroundSecondary, other.backgroundSecondary, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      card: Color.lerp(card, other.card, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      white: Color.lerp(white, other.white, t)!,
      success: Color.lerp(success, other.success, t)!,
      successLight: Color.lerp(successLight, other.successLight, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningLight: Color.lerp(warningLight, other.warningLight, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorLight: Color.lerp(errorLight, other.errorLight, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoLight: Color.lerp(infoLight, other.infoLight, t)!,
      primaryGradient: LinearGradient.lerp(primaryGradient, other.primaryGradient, t)!,
      premiumGradient: LinearGradient.lerp(premiumGradient, other.premiumGradient, t)!,
      backgroundGradient: LinearGradient.lerp(backgroundGradient, other.backgroundGradient, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
    );
  }

  static const light = AppColorsExtension(
    primary: Color(0xFF7FD1AE),
    primaryDark: Color(0xFF5DB38C),
    primaryLight: Color(0xFFB8E6D1),
    secondary: Color(0xFFA8CFA8),
    accentCream: Color(0xFFFFF4E8),
    softBeige: Color(0xFFF5E8DA),
    background: Color(0xFFFAFAF7),
    backgroundSecondary: Color(0xFFF4F6F2),
    surface: Color(0xFFEEF8F2),
    card: Color(0xFFFFFFFF),
    divider: Color(0xFFDDE7DF),
    border: Color(0xFFD2DED5),
    textPrimary: Color(0xFF2F3A3D),
    textSecondary: Color(0xFF5F6B6D),
    textMuted: Color(0xFF8B9597),
    textDisabled: Color(0xFFB5BDBF),
    white: Colors.white,
    success: Color(0xFF69C38C),
    successLight: Color(0xFFDDF5E6),
    warning: Color(0xFFF2C57C),
    warningLight: Color(0xFFFFF1D9),
    error: Color(0xFFE89A9A),
    errorLight: Color(0xFFFCE7E7),
    info: Color(0xFF8ECDF2),
    infoLight: Color(0xFFE6F5FF),
    primaryGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF7FD1AE), Color(0xFFB8E6D1)],
    ),
    premiumGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF5DB38C), Color(0xFF7FD1AE), Color(0xFFDDF5E6)],
    ),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFAFAF7), Color(0xFFEEF8F2)],
    ),
    accent: Color(0xFFA8CFA8),
    income: Color(0xFF69C38C),
    expense: Color(0xFFE89A9A),
  );

  static const dark = AppColorsExtension(
    primary: Color(0xFF638E6A),
    primaryDark: Color(0xFF3E5A44),
    primaryLight: Color(0xFFA2C4A9),
    secondary: Color(0xFF76A08D),
    accentCream: Color(0xFF272B30),
    softBeige: Color(0xFF1A1D1F),
    background: Color(0xFF0F1113),
    backgroundSecondary: Color(0xFF1A1D1F),
    surface: Color(0xFF1A1D1F),
    card: Color(0xFF272B30),
    divider: Color(0xFF272B30),
    border: Color(0xFF3E5A44),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF919EAB),
    textMuted: Color(0xFF637381),
    textDisabled: Color(0xFF637381),
    white: Colors.white,
    success: Color(0xFF4ADE80),
    successLight: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    warningLight: Color(0xFFFBBF24),
    error: Color(0xFFF87171),
    errorLight: Color(0xFFF87171),
    info: Color(0xFF60A5FA),
    infoLight: Color(0xFF60A5FA),
    primaryGradient: LinearGradient(
      colors: [Color(0xFF638E6A), Color(0xFF4A6B51)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    premiumGradient: LinearGradient(
      colors: [Color(0xFF638E6A), Color(0xFF4A6B51)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    backgroundGradient: LinearGradient(
      colors: [Color(0xFF0F1113), Color(0xFF1A1D1F)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    accent: Color(0xFF76A08D),
    income: Color(0xFF4ADE80),
    expense: Color(0xFFF87171),
  );
}

extension AppThemeContextExtension on BuildContext {
  AppColorsExtension get colors => Theme.of(this).extension<AppColorsExtension>()!;
}

class AppTheme {
  static ThemeData get lightTheme {
    final colors = AppColorsExtension.light;
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme.light(
        primary: colors.primary,
        secondary: colors.secondary,
        surface: colors.surface,
        error: colors.error,
        onPrimary: Colors.white,
        onSecondary: colors.textPrimary,
        onSurface: colors.textPrimary,
        onError: Colors.white,
      ),
      extensions: const [AppColorsExtension.light],
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
      ),
      cardTheme: CardThemeData(
        color: colors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerColor: colors.divider,
      textTheme: TextTheme(
        headlineLarge: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: colors.textPrimary),
        bodyMedium: TextStyle(color: colors.textSecondary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.backgroundSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final colors = AppColorsExtension.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Poppins',
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme.dark(
        primary: colors.primary,
        secondary: colors.accent,
        surface: colors.surface,
        error: colors.expense,
      ),
      extensions: const [AppColorsExtension.dark],
      textTheme: TextTheme(
        displayLarge: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary),
        headlineLarge: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary),
        headlineMedium: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary),
        titleLarge: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary),
        bodyLarge: TextStyle(color: colors.textPrimary),
        bodyMedium: TextStyle(color: colors.textSecondary),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
      ),
      cardTheme: CardThemeData(
        color: colors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withAlpha(12), width: 1), // withAlpha(12) is ~0.05 opacity
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.card.withAlpha(128),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withAlpha(25)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withAlpha(25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        labelStyle: TextStyle(color: colors.textSecondary),
        prefixIconColor: colors.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          shadowColor: colors.primary.withAlpha(76),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
