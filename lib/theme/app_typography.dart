import 'package:flutter/material.dart';

/// U-081 — named type roles. Replaces ad-hoc font sizes (the same role rendered
/// at 13/15/15.5/18/22/26px) with a complete scale. Display/title roles use
/// Space Grotesk (the brand's geometric face); body/label stay on the global
/// font. Sizes are integers so rhythm stays consistent across device pixel
/// ratios; small roles carry positive tracking for legibility.
class AppType {
  AppType._();

  static const String fontDisplay = 'SpaceGrotesk';

  static const TextStyle displayL = TextStyle(
      fontFamily: fontDisplay,
      fontSize: 28,
      height: 1.1,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5);

  static const TextStyle displayM = TextStyle(
      fontFamily: fontDisplay,
      fontSize: 24,
      height: 1.15,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3);

  /// 20px headline — fills the hole between displayM (24) and titleL (18) so
  /// section headers stop being squeezed into the wrong role.
  static const TextStyle headline = TextStyle(
      fontFamily: fontDisplay,
      fontSize: 20,
      height: 1.25,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2);

  static const TextStyle titleL = TextStyle(
      fontFamily: fontDisplay, fontSize: 18, height: 1.25, fontWeight: FontWeight.w700);

  static const TextStyle titleM = TextStyle(
      fontFamily: fontDisplay, fontSize: 16, height: 1.3, fontWeight: FontWeight.w700);

  static const TextStyle titleS = TextStyle(
      fontFamily: fontDisplay, fontSize: 13, height: 1.3, fontWeight: FontWeight.w600);

  /// 16px reading body — the base every top-tier consumer app uses for prose.
  static const TextStyle bodyL =
      TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.w400);

  static const TextStyle body =
      TextStyle(fontSize: 14, height: 1.5, fontWeight: FontWeight.w400);

  static const TextStyle label = TextStyle(
      fontSize: 12, height: 1.3, fontWeight: FontWeight.w600, letterSpacing: 0.2);

  static const TextStyle caption = TextStyle(
      fontSize: 11, height: 1.3, fontWeight: FontWeight.w500, letterSpacing: 0.2);

  /// Button label — Space Grotesk so CTAs carry the brand voice.
  static const TextStyle button = TextStyle(
      fontFamily: fontDisplay,
      fontSize: 15,
      height: 1.2,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.1);
}
