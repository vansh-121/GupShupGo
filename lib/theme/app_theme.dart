import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// GupShupGo — Brand Design System
class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF6C5CE7); // vibrant purple-indigo
  static const Color primaryDk = Color(0xFF5246BE);
  static const Color primaryLt = Color(0xFFEDE9FE); // soft lavender tint

  // ── Bubbles ────────────────────────────────────────────────────────
  static const Color sent = Color(0xFF6C5CE7);
  static const Color received = Color(0xFFF0EFF8);

  // ── Status indicator ──────────────────────────────────────────────
  static const Color online = Color(0xFF10B981);

  // ── Surface / Background ──────────────────────────────────────────
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF5F3FF); // settings rows / inputs
  static const Color chatBg = Color(0xFFF2F1FA); // chat body

  // ── Text ──────────────────────────────────────────────────────────
  static const Color textHigh = Color(0xFF1E293B); // main text
  static const Color textMid = Color(0xFF64748B); // secondary text
  static const Color textLow = Color(0xFF94A3B8); // placeholder / muted

  // ── Stroke / Divider ──────────────────────────────────────────────
  static const Color border = Color(0xFFE4E1F5);
  static const Color divider = Color(0xFFF1F0F9);

  // ── Semantic ──────────────────────────────────────────────────────
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
}

/// Dark-mode equivalents — same brand, dark surfaces.
class AppColorsDark {
  AppColorsDark._();

  // ── Brand (same) ───────────────────────────────────────────────────
  static const Color primary = Color(0xFF7C6FF0);
  static const Color primaryDk = Color(0xFF5246BE);
  static const Color primaryLt = Color(0xFF2C2860); // dark lavender tint

  // ── Bubbles ────────────────────────────────────────────────────────
  static const Color sent = Color(0xFF6C5CE7);
  static const Color received = Color(0xFF252540);

  // ── Status indicator ──────────────────────────────────────────────
  static const Color online = Color(0xFF34D399);

  // ── Surface / Background ──────────────────────────────────────────
  static const Color surface = Color(0xFF151520);
  static const Color surfaceAlt = Color(0xFF1E1E30); // settings rows / inputs
  static const Color chatBg = Color(0xFF0E0E18); // chat body

  // ── Text ──────────────────────────────────────────────────────────
  static const Color textHigh = Color(0xFFECECF5); // near-white
  static const Color textMid = Color(0xFF9B9BB8); // secondary text
  static const Color textLow = Color(0xFF6A6A88); // placeholder / muted

  // ── Stroke / Divider ──────────────────────────────────────────────
  static const Color border = Color(0xFF2A2A45);
  static const Color divider = Color(0xFF1E1E34);

  // ── Semantic ──────────────────────────────────────────────────────
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
}

/// Context-aware color resolver. Returns light or dark palette based on
/// the current theme brightness.
///
/// Usage: `final c = AppThemeColors.of(context);`
/// Then: `c.surface`, `c.textHigh`, etc.
class AppThemeColors {
  final bool isDark;
  const AppThemeColors._(this.isDark);

  factory AppThemeColors.of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return AppThemeColors._(brightness == Brightness.dark);
  }

  Color get primary => isDark ? AppColorsDark.primary : AppColors.primary;
  Color get primaryDk => isDark ? AppColorsDark.primaryDk : AppColors.primaryDk;
  Color get primaryLt => isDark ? AppColorsDark.primaryLt : AppColors.primaryLt;
  Color get sent => isDark ? AppColorsDark.sent : AppColors.sent;
  Color get received => isDark ? AppColorsDark.received : AppColors.received;
  Color get online => isDark ? AppColorsDark.online : AppColors.online;
  Color get surface => isDark ? AppColorsDark.surface : AppColors.surface;
  Color get surfaceAlt => isDark ? AppColorsDark.surfaceAlt : AppColors.surfaceAlt;
  Color get chatBg => isDark ? AppColorsDark.chatBg : AppColors.chatBg;
  Color get textHigh => isDark ? AppColorsDark.textHigh : AppColors.textHigh;
  Color get textMid => isDark ? AppColorsDark.textMid : AppColors.textMid;
  Color get textLow => isDark ? AppColorsDark.textLow : AppColors.textLow;
  Color get border => isDark ? AppColorsDark.border : AppColors.border;
  Color get divider => isDark ? AppColorsDark.divider : AppColors.divider;
  Color get error => isDark ? AppColorsDark.error : AppColors.error;
  Color get success => isDark ? AppColorsDark.success : AppColors.success;
  Color get warning => isDark ? AppColorsDark.warning : AppColors.warning;

  /// White in light mode, dark surface in dark mode — useful for card/container bgs.
  Color get cardBg => isDark ? AppColorsDark.surfaceAlt : Colors.white;
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    const cs = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryLt,
      onPrimaryContainer: AppColors.primaryDk,
      secondary: Color(0xFF8B5CF6),
      onSecondary: Colors.white,
      secondaryContainer: AppColors.primaryLt,
      onSecondaryContainer: AppColors.primaryDk,
      tertiary: AppColors.online,
      onTertiary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: Color(0xFFFEE2E2),
      onErrorContainer: Color(0xFFB91C1C),
      surface: AppColors.surface,
      onSurface: AppColors.textHigh,
      surfaceVariant: AppColors.surfaceAlt,
      onSurfaceVariant: AppColors.textMid,
      outline: AppColors.border,
      outlineVariant: AppColors.divider,
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: AppColors.textHigh,
      onInverseSurface: Colors.white,
      inversePrimary: AppColors.primaryLt,
      surfaceTint: Color(0x0A6C5CE7),
      background: AppColors.surface,
      onBackground: AppColors.textHigh,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      textTheme: GoogleFonts.poppinsTextTheme(),
      scaffoldBackgroundColor: AppColors.surface,

      // ── AppBar ──────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.8,
        shadowColor: AppColors.border,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textHigh,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.textHigh, size: 22),
        actionsIconTheme:
            const IconThemeData(color: AppColors.textHigh, size: 22),
        titleTextStyle: GoogleFonts.poppins(
          color: AppColors.textHigh,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
      ),

      // ── TabBar ──────────────────────────────────────────────────
      tabBarTheme: TabBarTheme(
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.primary, width: 3),
          borderRadius: BorderRadius.all(Radius.circular(3)),
        ),
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textLow,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AppColors.divider,
        overlayColor: MaterialStateProperty.all(
          AppColors.primaryLt.withOpacity(0.3),
        ),
        labelStyle:
            GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle:
            GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
      ),

      // ── FAB ─────────────────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // ── ElevatedButton ──────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle:
              GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      // ── OutlinedButton ──────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textHigh,
          side: const BorderSide(color: AppColors.border, width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle:
              GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      // ── TextButton ──────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle:
              GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // ── InputDecoration ─────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.textLow),
        labelStyle: const TextStyle(color: AppColors.textMid),
        prefixIconColor: AppColors.textMid,
        suffixIconColor: AppColors.textMid,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // ── Switch ──────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.all(Colors.white),
        trackColor: MaterialStateProperty.resolveWith((s) =>
            s.contains(MaterialState.selected)
                ? AppColors.primary
                : AppColors.textLow.withOpacity(0.35)),
        trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
      ),

      // ── Divider ─────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 0,
      ),

      // ── ListTile ────────────────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
        iconColor: AppColors.textMid,
      ),

      // ── PopupMenu ───────────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        elevation: 10,
        shadowColor: AppColors.primary.withOpacity(0.12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.poppins(fontSize: 14, color: AppColors.textHigh),
        position: PopupMenuPosition.under,
      ),

      // ── SnackBar ────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textHigh,
        contentTextStyle:
            GoogleFonts.poppins(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        insetPadding: const EdgeInsets.all(16),
      ),

      // ── BottomSheet ─────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        elevation: 8,
      ),

      // ── Dialog ──────────────────────────────────────────────────
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 8,
        titleTextStyle: GoogleFonts.poppins(
          color: AppColors.textHigh,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: GoogleFonts.poppins(
          color: AppColors.textMid,
          fontSize: 14,
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // DARK THEME
  // ════════════════════════════════════════════════════════════════════════════
  static ThemeData get dark {
    const cs = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColorsDark.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColorsDark.primaryLt,
      onPrimaryContainer: AppColorsDark.primaryDk,
      secondary: Color(0xFF9D8DF5),
      onSecondary: Colors.white,
      secondaryContainer: AppColorsDark.primaryLt,
      onSecondaryContainer: AppColorsDark.primary,
      tertiary: AppColorsDark.online,
      onTertiary: Colors.white,
      error: AppColorsDark.error,
      onError: Colors.white,
      errorContainer: Color(0xFF4A1010),
      onErrorContainer: Color(0xFFFCA5A5),
      surface: AppColorsDark.surface,
      onSurface: AppColorsDark.textHigh,
      surfaceVariant: AppColorsDark.surfaceAlt,
      onSurfaceVariant: AppColorsDark.textMid,
      outline: AppColorsDark.border,
      outlineVariant: AppColorsDark.divider,
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: AppColorsDark.textHigh,
      onInverseSurface: AppColorsDark.surface,
      inversePrimary: AppColorsDark.primaryLt,
      surfaceTint: Color(0x0A7C6FF0),
      background: AppColorsDark.surface,
      onBackground: AppColorsDark.textHigh,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData(brightness: Brightness.dark).textTheme,
      ),
      scaffoldBackgroundColor: AppColorsDark.surface,

      // ── AppBar ──────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.8,
        shadowColor: AppColorsDark.border,
        backgroundColor: AppColorsDark.surface,
        foregroundColor: AppColorsDark.textHigh,
        surfaceTintColor: Colors.transparent,
        iconTheme:
            const IconThemeData(color: AppColorsDark.textHigh, size: 22),
        actionsIconTheme:
            const IconThemeData(color: AppColorsDark.textHigh, size: 22),
        titleTextStyle: GoogleFonts.poppins(
          color: AppColorsDark.textHigh,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
      ),

      // ── TabBar ──────────────────────────────────────────────────
      tabBarTheme: TabBarTheme(
        indicator: const UnderlineTabIndicator(
          borderSide:
              BorderSide(color: AppColorsDark.primary, width: 3),
          borderRadius: BorderRadius.all(Radius.circular(3)),
        ),
        labelColor: AppColorsDark.primary,
        unselectedLabelColor: AppColorsDark.textLow,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AppColorsDark.divider,
        overlayColor: MaterialStateProperty.all(
          AppColorsDark.primaryLt.withOpacity(0.15),
        ),
        labelStyle:
            GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle:
            GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
      ),

      // ── FAB ─────────────────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColorsDark.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // ── ElevatedButton ──────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsDark.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          padding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle:
              GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      // ── OutlinedButton ──────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColorsDark.textHigh,
          side:
              const BorderSide(color: AppColorsDark.border, width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          padding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle:
              GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      // ── TextButton ──────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColorsDark.primary,
          textStyle:
              GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // ── InputDecoration ─────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsDark.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColorsDark.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColorsDark.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColorsDark.primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColorsDark.textLow),
        labelStyle: const TextStyle(color: AppColorsDark.textMid),
        prefixIconColor: AppColorsDark.textMid,
        suffixIconColor: AppColorsDark.textMid,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // ── Switch ──────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.all(Colors.white),
        trackColor: MaterialStateProperty.resolveWith((s) =>
            s.contains(MaterialState.selected)
                ? AppColorsDark.primary
                : AppColorsDark.textLow.withOpacity(0.35)),
        trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
      ),

      // ── Divider ─────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColorsDark.divider,
        thickness: 1,
        space: 0,
      ),

      // ── ListTile ────────────────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
        iconColor: AppColorsDark.textMid,
      ),

      // ── PopupMenu ───────────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        color: AppColorsDark.surfaceAlt,
        elevation: 10,
        shadowColor: Colors.black45,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.poppins(
            fontSize: 14, color: AppColorsDark.textHigh),
        position: PopupMenuPosition.under,
      ),

      // ── SnackBar ────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColorsDark.surfaceAlt,
        contentTextStyle:
            GoogleFonts.poppins(color: AppColorsDark.textHigh, fontSize: 14),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        insetPadding: const EdgeInsets.all(16),
      ),

      // ── BottomSheet ─────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColorsDark.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        elevation: 8,
      ),

      // ── Dialog ──────────────────────────────────────────────────
      dialogTheme: DialogTheme(
        backgroundColor: AppColorsDark.surfaceAlt,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 8,
        titleTextStyle: GoogleFonts.poppins(
          color: AppColorsDark.textHigh,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: GoogleFonts.poppins(
          color: AppColorsDark.textMid,
          fontSize: 14,
        ),
      ),
    );
  }
}
