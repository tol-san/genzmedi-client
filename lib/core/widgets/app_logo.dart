import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum AppLogoVariant { icon, wordmark }

/// Official GenZ Media logo rendering widget.
class AppLogo extends StatelessWidget {
  final AppLogoVariant variant;
  final double? width;
  final double? height;
  final Color? color;

  const AppLogo({
    super.key,
    this.variant = AppLogoVariant.wordmark,
    this.width,
    this.height,
    this.color,
  });

  const AppLogo.icon({super.key, this.width = 44, this.height = 34, this.color})
    : variant = AppLogoVariant.icon;

  const AppLogo.wordmark({
    super.key,
    this.width = 170,
    this.height = 26,
    this.color,
  }) : variant = AppLogoVariant.wordmark;

  @override
  Widget build(BuildContext context) {
    final assetPath = variant == AppLogoVariant.icon
        ? 'assets/logos/app_logo.svg'
        : 'assets/logos/app_wordmark.svg';

    return SvgPicture.asset(
      assetPath,
      width: width,
      height: height,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
      fit: BoxFit.contain,
    );
  }
}
