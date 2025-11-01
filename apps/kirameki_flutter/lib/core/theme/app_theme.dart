import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

final appThemeProvider = StateNotifierProvider<AppThemeController, ThemeMode>((
  ref,
) {
  return AppThemeController();
});

class AppThemeController extends StateNotifier<ThemeMode> {
  AppThemeController() : super(ThemeMode.dark);

  ThemeData light() => _buildTheme(Brightness.light);

  ThemeData dark() => _buildTheme(Brightness.dark);

  void setThemeMode(ThemeMode mode) => state = mode;
}

ThemeData _buildTheme(Brightness brightness) {
  final palette = _Palette.forBrightness(brightness);
  final baseScheme = ColorScheme.fromSeed(
    brightness: brightness,
    seedColor: palette.primary,
  );

  final colorScheme = baseScheme.copyWith(
    primary: palette.primary,
    secondary: palette.secondary,
    tertiary: palette.tertiary,
    surface: palette.surface,
    surfaceContainerHighest: palette.surfaceContainer,
    surfaceContainerHigh: palette.surfaceContainer,
    surfaceContainerLow: palette.surface,
    onSurface: palette.onSurface,
    onSurfaceVariant: palette.onSurfaceVariant,
    outline: palette.outline,
    shadow: palette.shadow,
    scrim: palette.scrim,
    inverseSurface: palette.inverseSurface,
    onInverseSurface: palette.onInverseSurface,
  );

  final textTheme =
      GoogleFonts.urbanistTextTheme(
        brightness == Brightness.dark
            ? ThemeData.dark().textTheme
            : ThemeData.light().textTheme,
      ).apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: palette.background,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: palette.surface.withValues(alpha: 0.8),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      color: palette.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      backgroundColor: palette.surface.withValues(alpha: 0.9),
      indicatorColor: palette.primary.withValues(alpha: 0.16),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: palette.primary);
        }
        return IconThemeData(color: palette.onSurface.withValues(alpha: 0.7));
      }),
      labelTextStyle: WidgetStatePropertyAll(
        textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: palette.surface.withValues(alpha: 0.92),
      indicatorColor: palette.primary.withValues(alpha: 0.18),
      selectedIconTheme: IconThemeData(color: palette.primary),
      unselectedIconTheme: IconThemeData(
        color: palette.onSurface.withValues(alpha: 0.7),
      ),
      selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: palette.primary,
      ),
      unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
        color: palette.onSurface.withValues(alpha: 0.7),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: palette.surfaceContainer,
      selectedColor: palette.primary.withValues(alpha: 0.18),
      labelStyle: textTheme.labelLarge,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surface.withValues(alpha: 0.65),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      hintStyle: textTheme.bodyMedium?.copyWith(
        color: palette.onSurface.withValues(alpha: 0.6),
      ),
    ),
  );
}

class _Palette {
  const _Palette({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.surface,
    required this.surfaceContainer,
    required this.background,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outline,
    required this.shadow,
    required this.scrim,
    required this.inverseSurface,
    required this.onInverseSurface,
  });

  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color surface;
  final Color surfaceContainer;
  final Color background;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outline;
  final Color shadow;
  final Color scrim;
  final Color inverseSurface;
  final Color onInverseSurface;

  static _Palette forBrightness(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return _Palette(
        primary: const Color(0xFFDC2626),
        secondary: const Color(0xFF0EA5E9),
        tertiary: const Color(0xFFFBBF24),
        surface: const Color(0xFF111827),
        surfaceContainer: const Color(0xFF1F2937),
        background: const Color(0xFF05060A),
        onSurface: const Color(0xFFF9FAFB),
        onSurfaceVariant: const Color(0xFFCBD5F5),
        outline: const Color(0xFF334155),
        shadow: Colors.black.withValues(alpha: 0.7),
        scrim: Colors.black.withValues(alpha: 0.8),
        inverseSurface: const Color(0xFFF1F5F9),
        onInverseSurface: const Color(0xFF0B1120),
      );
    }

    return _Palette(
      primary: const Color(0xFFDC2626),
      secondary: const Color(0xFF0EA5E9),
      tertiary: const Color(0xFFF97316),
      surface: const Color(0xFFF5F7FB),
      surfaceContainer: const Color(0xFFE2E8F0),
      background: const Color(0xFFFDFDFE),
      onSurface: const Color(0xFF0F172A),
      onSurfaceVariant: const Color(0xFF475569),
      outline: const Color(0xFFCBD5E1),
      shadow: Colors.black.withValues(alpha: 0.1),
      scrim: Colors.black.withValues(alpha: 0.15),
      inverseSurface: const Color(0xFF0B1120),
      onInverseSurface: const Color(0xFFE2E8F0),
    );
  }
}
