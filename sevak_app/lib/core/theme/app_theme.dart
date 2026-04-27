import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SevakColors — ONLY for domain-specific semantic colors that must NOT change
// with the theme seed.  Everything else should come from ColorScheme.
// ─────────────────────────────────────────────────────────────────────────────
class SevakColors {
  SevakColors._();

  // Brand seed — Google Blue, consistent with Google app ecosystem
  static const Color seed = Color(0xFF1A73E8);

  // Urgency semantics (map pin colours, status indicators)
  static const Color urgencyCritical = Color(0xFFD93025); // Google Red
  static const Color urgencyUrgent   = Color(0xFFF9AB00); // Google Yellow
  static const Color urgencyModerate = Color(0xFF1E8E3E); // Google Green

  // Status
  static const Color success = Color(0xFF1E8E3E);
  static const Color warning = Color(0xFFF9AB00);
  static const Color error   = Color(0xFFD93025);
  static const Color info    = Color(0xFF1A73E8);
}

// ─────────────────────────────────────────────────────────────────────────────
// Backward-compat alias so existing imports of AppColors don't break during
// the migration.  Will be removed once all files are migrated.
// ─────────────────────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  // Re-expose via SevakColors
  static const Color primary       = SevakColors.seed;
  static const Color primaryDark   = Color(0xFF1557B0);
  static const Color accent        = Color(0xFF00897B); // Teal (tertiary)

  // Dark-theme surfaces (kept for files not yet migrated)
  static const Color bgBase        = Color(0xFF0F0F13);
  static const Color bgSurface     = Color(0xFF1A1A22);
  static const Color bgElevated    = Color(0xFF23232E);

  // Text
  static const Color textPrimary   = Color(0xFFE3E3F0);
  static const Color textSecondary = Color(0xFF9E9EB8);
  static const Color textDisabled  = Color(0xFF5C5C73);

  // Urgency
  static const Color urgencyCritical = SevakColors.urgencyCritical;
  static const Color urgencyUrgent   = SevakColors.urgencyUrgent;
  static const Color urgencyModerate = SevakColors.urgencyModerate;

  // Status
  static const Color success = SevakColors.success;
  static const Color warning = SevakColors.warning;
  static const Color error   = SevakColors.error;
  static const Color info    = SevakColors.info;

  // Border
  static const Color border = Color(0xFF2C2C3A);
}

// ─────────────────────────────────────────────────────────────────────────────
// SevakTheme — builds both light and dark MaterialTheme from the same seed.
// Reference: Google Material Design 3 spec + Google app UI patterns.
// ─────────────────────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  // ── Color Schemes ──────────────────────────────────────────────────────────

  static final ColorScheme _lightColorScheme = ColorScheme.fromSeed(
    seedColor: SevakColors.seed,
    brightness: Brightness.light,
    // Override error to match Google's precise red
    error: SevakColors.error,
  );

  static final ColorScheme _darkColorScheme = ColorScheme.fromSeed(
    seedColor: SevakColors.seed,
    brightness: Brightness.dark,
    error: SevakColors.error,
  );

  // ── Typography — Roboto (Google native, same as Google apps) ───────────────
  // Uses the M3 type scale with Roboto.
  static TextTheme _buildTextTheme(ColorScheme cs) {
    final base = GoogleFonts.robotoTextTheme();
    return base.copyWith(
      // Display
      displayLarge:  GoogleFonts.roboto(fontSize: 57, fontWeight: FontWeight.w400, letterSpacing: -0.25),
      displayMedium: GoogleFonts.roboto(fontSize: 45, fontWeight: FontWeight.w400),
      displaySmall:  GoogleFonts.roboto(fontSize: 36, fontWeight: FontWeight.w400),
      // Headline
      headlineLarge:  GoogleFonts.roboto(fontSize: 32, fontWeight: FontWeight.w600),
      headlineMedium: GoogleFonts.roboto(fontSize: 28, fontWeight: FontWeight.w600),
      headlineSmall:  GoogleFonts.roboto(fontSize: 24, fontWeight: FontWeight.w600),
      // Title
      titleLarge:  GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.w500),
      titleMedium: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.15),
      titleSmall:  GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
      // Body
      bodyLarge:   GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5),
      bodyMedium:  GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25),
      bodySmall:   GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4),
      // Label
      labelLarge:  GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
      labelMedium: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5),
      labelSmall:  GoogleFonts.roboto(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5),
    );
  }

  // ── Shared Component Themes ────────────────────────────────────────────────

  static AppBarTheme _appBarTheme(ColorScheme cs) => AppBarTheme(
    backgroundColor: cs.surface,
    foregroundColor: cs.onSurface,
    elevation: 0,
    scrolledUnderElevation: 3,
    shadowColor: cs.shadow,
    surfaceTintColor: cs.surfaceTint,
    centerTitle: false,
    titleTextStyle: GoogleFonts.roboto(
      fontSize: 22,
      fontWeight: FontWeight.w500,
      color: cs.onSurface,
    ),
    iconTheme: IconThemeData(color: cs.onSurfaceVariant),
    actionsIconTheme: IconThemeData(color: cs.onSurfaceVariant),
    systemOverlayStyle: cs.brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark,
  );

  static CardThemeData _cardTheme(ColorScheme cs) => CardThemeData(
    color: cs.surfaceContainerLow,
    elevation: 0,
    surfaceTintColor: cs.surfaceTint,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    margin: EdgeInsets.zero,
  );

  static InputDecorationTheme _inputTheme(ColorScheme cs) => InputDecorationTheme(
    filled: true,
    fillColor: cs.surfaceContainerHighest,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.error, width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.error, width: 2),
    ),
    hintStyle: GoogleFonts.roboto(
      color: cs.onSurfaceVariant,
      fontSize: 14,
    ),
    labelStyle: GoogleFonts.roboto(
      color: cs.onSurfaceVariant,
      fontSize: 14,
    ),
    floatingLabelStyle: GoogleFonts.roboto(
      color: cs.primary,
      fontSize: 12,
    ),
    prefixIconColor: cs.onSurfaceVariant,
    suffixIconColor: cs.onSurfaceVariant,
    errorStyle: GoogleFonts.roboto(color: cs.error, fontSize: 12),
  );

  static FilledButtonThemeData _filledButtonTheme(ColorScheme cs) =>
      FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
        ),
      );

  static OutlinedButtonThemeData _outlinedButtonTheme(ColorScheme cs) =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(color: cs.outline),
          textStyle: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
        ),
      );

  static TextButtonThemeData _textButtonTheme(ColorScheme cs) =>
      TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(64, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
        ),
      );

  static ElevatedButtonThemeData _elevatedButtonTheme(ColorScheme cs) =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, 48),
          backgroundColor: cs.surfaceContainerLow,
          foregroundColor: cs.primary,
          elevation: 1,
          shadowColor: cs.shadow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
        ),
      );

  static NavigationDrawerThemeData _drawerTheme(ColorScheme cs) =>
      NavigationDrawerThemeData(
        backgroundColor: cs.surface,
        indicatorColor: cs.secondaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.onSecondaryContainer,
            );
          }
          return GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: cs.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: cs.onSecondaryContainer);
          }
          return IconThemeData(color: cs.onSurfaceVariant);
        }),
      );

  static NavigationBarThemeData _navBarTheme(ColorScheme cs) =>
      NavigationBarThemeData(
        backgroundColor: cs.surfaceContainer,
        indicatorColor: cs.secondaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.roboto(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            );
          }
          return GoogleFonts.roboto(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: cs.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: cs.onSecondaryContainer);
          }
          return IconThemeData(color: cs.onSurfaceVariant);
        }),
      );

  static TabBarThemeData _tabBarTheme(ColorScheme cs) => TabBarThemeData(
    dividerColor: cs.outlineVariant,
    labelColor: cs.primary,
    unselectedLabelColor: cs.onSurfaceVariant,
    indicator: UnderlineTabIndicator(
      borderSide: BorderSide(color: cs.primary, width: 3),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
    ),
    labelStyle: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w600),
    unselectedLabelStyle: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w400),
  );

  static ChipThemeData _chipTheme(ColorScheme cs) => ChipThemeData(
    backgroundColor: cs.surfaceContainerHighest,
    selectedColor: cs.secondaryContainer,
    checkmarkColor: cs.onSecondaryContainer,
    side: BorderSide(color: cs.outlineVariant),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    labelStyle: GoogleFonts.roboto(fontSize: 13, fontWeight: FontWeight.w400),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  );

  static DialogThemeData _dialogTheme(ColorScheme cs) => DialogThemeData(
    backgroundColor: cs.surfaceContainerHigh,
    surfaceTintColor: cs.surfaceTint,
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    titleTextStyle: GoogleFonts.roboto(
      fontSize: 22,
      fontWeight: FontWeight.w500,
      color: cs.onSurface,
    ),
    contentTextStyle: GoogleFonts.roboto(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: cs.onSurfaceVariant,
    ),
  );

  static BottomSheetThemeData _bottomSheetTheme(ColorScheme cs) =>
      BottomSheetThemeData(
        backgroundColor: cs.surfaceContainerLow,
        surfaceTintColor: cs.surfaceTint,
        elevation: 1,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        dragHandleColor: cs.onSurfaceVariant.withAlpha(76),
        dragHandleSize: const Size(32, 4),
        showDragHandle: true,
      );

  static SnackBarThemeData _snackBarTheme(ColorScheme cs) => SnackBarThemeData(
    backgroundColor: cs.inverseSurface,
    contentTextStyle: GoogleFonts.roboto(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: cs.onInverseSurface,
    ),
    actionTextColor: cs.inversePrimary,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    behavior: SnackBarBehavior.floating,
  );

  static FloatingActionButtonThemeData _fabTheme(ColorScheme cs) =>
      FloatingActionButtonThemeData(
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      );

  static SwitchThemeData _switchTheme(ColorScheme cs) => SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return cs.onPrimary;
      return cs.outline;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return cs.primary;
      return cs.surfaceContainerHighest;
    }),
    trackOutlineColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return Colors.transparent;
      return cs.outline;
    }),
  );

  static DividerThemeData _dividerTheme(ColorScheme cs) => DividerThemeData(
    color: cs.outlineVariant,
    thickness: 1,
    space: 1,
  );

  static ListTileThemeData _listTileTheme(ColorScheme cs) => ListTileThemeData(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    titleTextStyle: GoogleFonts.roboto(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: cs.onSurface,
    ),
    subtitleTextStyle: GoogleFonts.roboto(
      fontSize: 14,
      color: cs.onSurfaceVariant,
    ),
  );

  static SearchBarThemeData _searchBarTheme(ColorScheme cs) => SearchBarThemeData(
    backgroundColor: WidgetStatePropertyAll(cs.surfaceContainerHighest),
    elevation: const WidgetStatePropertyAll(0),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    textStyle: WidgetStatePropertyAll(
      GoogleFonts.roboto(fontSize: 16, color: cs.onSurface),
    ),
    hintStyle: WidgetStatePropertyAll(
      GoogleFonts.roboto(fontSize: 16, color: cs.onSurfaceVariant),
    ),
  );

  static ProgressIndicatorThemeData _progressTheme(ColorScheme cs) =>
      ProgressIndicatorThemeData(
        color: cs.primary,
        linearTrackColor: cs.surfaceContainerHighest,
        circularTrackColor: cs.surfaceContainerHighest,
        linearMinHeight: 4,
        borderRadius: const BorderRadius.all(Radius.circular(4)),
      );

  // ── Theme Builder ──────────────────────────────────────────────────────────

  static ThemeData _buildTheme(ColorScheme cs) {
    final textTheme = _buildTextTheme(cs);
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      brightness: cs.brightness,
      scaffoldBackgroundColor: cs.surface,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: _appBarTheme(cs),
      cardTheme: _cardTheme(cs),
      inputDecorationTheme: _inputTheme(cs),
      filledButtonTheme: _filledButtonTheme(cs),
      outlinedButtonTheme: _outlinedButtonTheme(cs),
      textButtonTheme: _textButtonTheme(cs),
      elevatedButtonTheme: _elevatedButtonTheme(cs),
      navigationDrawerTheme: _drawerTheme(cs),
      navigationBarTheme: _navBarTheme(cs),
      tabBarTheme: _tabBarTheme(cs),
      chipTheme: _chipTheme(cs),
      dialogTheme: _dialogTheme(cs),
      bottomSheetTheme: _bottomSheetTheme(cs),
      snackBarTheme: _snackBarTheme(cs),
      floatingActionButtonTheme: _fabTheme(cs),
      switchTheme: _switchTheme(cs),
      dividerTheme: _dividerTheme(cs),
      listTileTheme: _listTileTheme(cs),
      searchBarTheme: _searchBarTheme(cs),
      progressIndicatorTheme: _progressTheme(cs),
      // Rounded icon button shapes
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  static ThemeData get lightTheme => _buildTheme(_lightColorScheme);
  static ThemeData get darkTheme  => _buildTheme(_darkColorScheme);

  // ── Domain Utilities ───────────────────────────────────────────────────────

  /// Returns the urgency indicator colour for an urgency score [0–100].
  static Color urgencyColor(int score) {
    if (score >= 80) return SevakColors.urgencyCritical;
    if (score >= 50) return SevakColors.urgencyUrgent;
    return SevakColors.urgencyModerate;
  }

  /// Returns a human-readable urgency label.
  static String urgencyLabel(int score) {
    if (score >= 80) return 'CRITICAL';
    if (score >= 50) return 'URGENT';
    return 'MODERATE';
  }
}
