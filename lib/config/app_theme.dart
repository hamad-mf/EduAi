import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── Core Palette ──────────────────────────────────────────────────────
  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color accentBlue = Color(0xFF42A5F5);
  static const Color darkText = Color(0xFF1A1A2E);
  static const Color secondaryText = Color(0xFF5C6B8A);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color backgroundTint = Color(0xFFF5F8FF);
  static const Color borderLight = Color(0xFFE0E8F5);
  static const Color shadowBlue = Color(0x141565C0);

  // ── Gradients ─────────────────────────────────────────────────────────
  static const LinearGradient pageBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[Color(0xFFFFFFFF), Color(0xFFF0F4FF)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF1565C0), Color(0xFF42A5F5)],
  );

  // ── Reusable Decorations ──────────────────────────────────────────────
  static BoxDecoration cardDecoration({double radius = 16}) => BoxDecoration(
    color: surfaceWhite,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: const <BoxShadow>[
      BoxShadow(color: shadowBlue, blurRadius: 12, offset: Offset(0, 4)),
    ],
  );

  static BoxDecoration accentLeftBorder({double radius = 14}) => BoxDecoration(
    color: surfaceWhite,
    borderRadius: BorderRadius.circular(radius),
    border: const Border(
      left: BorderSide(color: primaryBlue, width: 3.5),
    ),
    boxShadow: const <BoxShadow>[
      BoxShadow(color: shadowBlue, blurRadius: 10, offset: Offset(0, 3)),
    ],
  );

  static BoxDecoration tintedContainer({double radius = 12}) => BoxDecoration(
    color: const Color(0xFFEDF2FF),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderLight),
  );

  // ── Section Header Widget ─────────────────────────────────────────────
  static Widget sectionHeader(BuildContext context, String title, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 20, color: primaryBlue),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: darkText,
            ),
          ),
        ],
      ),
    );
  }

  // ── Stat Card Widget ──────────────────────────────────────────────────
  static Widget statCard({
    required String label,
    required String value,
    required IconData icon,
    Color iconBg = const Color(0xFFE3EDFF),
    Color iconColor = primaryBlue,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: darkText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Score Badge ────────────────────────────────────────────────────────
  static Widget scoreBadge(double percent) {
    final bool pass = percent >= 50;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: pass ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${percent.toStringAsFixed(1)}%',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: pass ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
        ),
      ),
    );
  }

  // ── Chapter Chip ──────────────────────────────────────────────────────
  static Widget chapterChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE3EDFF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: primaryBlue,
        ),
      ),
    );
  }

  // ── Theme Data ────────────────────────────────────────────────────────
  static ThemeData lightTheme() {
    final TextTheme baseTextTheme = GoogleFonts.interTextTheme();

    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      textTheme: baseTextTheme.apply(
        bodyColor: darkText,
        displayColor: darkText,
      ),
      colorScheme: scheme.copyWith(
        primary: primaryBlue,
        secondary: accentBlue,
        surface: surfaceWhite,
        onSurface: darkText,
      ),
      scaffoldBackgroundColor: surfaceWhite,
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceWhite,
        foregroundColor: darkText,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: darkText,
        ),
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFE8EDF5), width: 1),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(vertical: 5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderLight, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 1.8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: const TextStyle(color: secondaryText, fontSize: 14),
        hintStyle: const TextStyle(color: secondaryText, fontSize: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(120, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(120, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          foregroundColor: primaryBlue,
          side: const BorderSide(color: Color(0xFFBBD0F0)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(90, 42),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          foregroundColor: primaryBlue,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: const Color(0xFFDCE8FF),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryBlue, size: 24);
          }
          return const IconThemeData(color: secondaryText, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primaryBlue,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: secondaryText,
          );
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFE3EDFF),
        selectedColor: const Color(0xFFCCDCFF),
        side: const BorderSide(color: Color(0xFFBBD0F0)),
        labelStyle: const TextStyle(
          color: primaryBlue,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: darkText,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE8EDF5),
        thickness: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryBlue,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return primaryBlue;
          }
          return const Color(0xFFB0BEC5);
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFFBBD6F7);
          }
          return const Color(0xFFE0E0E0);
        }),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        surfaceTintColor: Colors.transparent,
        backgroundColor: surfaceWhite,
      ),
      dropdownMenuTheme: const DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFFF8FAFF),
        ),
      ),
    );
  }
}
