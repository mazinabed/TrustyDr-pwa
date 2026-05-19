import 'package:flutter/material.dart';

class PatientAppColors {
  PatientAppColors._();

  // ─── Brand ──────────────────────────────────────────────────────────────────
  static const Color brandTeal = Color(0xFF5CC6BA); // primary gradient start
  static const Color brandTealAlt =
      Color(0xFF4DB6AC); // info/static page headers
  static const Color brandBlue = Color(0xFF4A90E2); // primary gradient end
  static const Color brandBlueAlt =
      Color(0xFF4B96DF); // icon backgrounds, accents
  static const Color brandIndigo =
      Color(0xFF6979F8); // legacy accent (primaryColor)

  // ─── Gradients ──────────────────────────────────────────────────────────────
  // Main brand gradient — used across booking, home, doctor, center pages
  static const LinearGradient brandGradient = LinearGradient(
    colors: [brandTeal, brandBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Secondary gradient — used in static/info page headers (about, FAQ, help, etc.)
  static const LinearGradient infoGradient = LinearGradient(
    colors: [brandTealAlt, brandBlueAlt],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Reversed brand gradient — used in speciality active-chip highlight [blue→teal]
  static const LinearGradient reverseBrandGradient = LinearGradient(
    colors: [brandBlue, brandTeal],
  );

  // ─── Backgrounds ────────────────────────────────────────────────────────────
  static const Color appBackground =
      Color(0xFFF3F8F6); // mint — scaffold bg (home, profile)
  static const Color pageBackground =
      Color(0xFFF6F8FB); // blue-grey — list page bg (appointments, doctors)
  static const Color surface = Color(0xFFFAF9F7); // warm off-white surface
  static const Color cardSurface =
      Color(0xFFFDFEFF); // card/panel bg (info pages, notifications)
  static const Color navBarBackground = Color(0xFFF2F5F9); // bottom nav bar bg
  static const Color white = Color(0xFFFFFFFF);

  // ─── Text / Navigation ──────────────────────────────────────────────────────
  static const Color darkNavy = Color(0xFF151C48); // primary headings
  static const Color navSelected =
      Color(0xFF2563EB); // bottom nav selected state
  static const Color navUnselected =
      Color(0xFF6B7280); // bottom nav unselected state

  // ─── Semantic Status ────────────────────────────────────────────────────────
  static const Color statusConfirmed =
      Color(0xFF4CAF50); // same as Colors.green
  static const Color statusPending = Color(0xFF2196F3); // same as Colors.blue
  static const Color statusCompleted =
      Color(0xFF2196F3); // blue — completed visits (info tone)
  static const Color statusWarning =
      Color(0xFFFF9800); // orange — pending/waiting
  static const Color statusCancelled =
      Color(0xFFF44336); // red — cancelled appointments

  // ─── Accent / Amber ─────────────────────────────────────────────────────────
  static const Color amberBg = Color(0xFFFFFBEB); // iOS tip banner background
  static const Color amberBorder = Color(0xFFFDE68A); // iOS tip banner border
  static const Color guestBannerBg =
      Color(0xFFFFF6D6); // home guest-login notice bg
  static const Color guestBannerBorder =
      Color(0xFFFFE8A3); // home guest-login notice border
  static const Color iosInstallBannerBg =
      Color(0xFFFFF9E6); // PWA install banner iOS bg

  // ─── Border Radius ──────────────────────────────────────────────────────────
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusCard = 18.0; // most card containers
  static const double radiusXl = 20.0;

  // ─── Shadows ────────────────────────────────────────────────────────────────
  // Standard card shadow — used in info cards, notification widgets, FAQ, help
  static const List<BoxShadow> shadowCard = [
    BoxShadow(
      color: Color(0x0A000000), // black ~4%
      blurRadius: 18,
      offset: Offset(0, 10),
    ),
    BoxShadow(
      color: Color(0x05000000), // black ~2%
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  // Nav bar upward shadow
  static const List<BoxShadow> shadowNav = [
    BoxShadow(
      color: Color(0x1F000000), // Colors.black12
      blurRadius: 10,
      offset: Offset(0, -2),
    ),
  ];

  // Subtle spread shadow — booking confirm card
  static const List<BoxShadow> shadowSubtle = [
    BoxShadow(
      color: Color(0x1A9E9E9E), // grey ~10%
      blurRadius: 5,
      spreadRadius: 2,
    ),
  ];
}
