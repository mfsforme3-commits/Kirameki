import 'package:flutter/widgets.dart';

class AppSizes {
  AppSizes._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double triple = 32;

  static const double borderRadius = 16;
}

class Gap {
  Gap._();

  static const gap4 = SizedBox(height: AppSizes.xs);
  static const gap8 = SizedBox(height: AppSizes.sm);
  static const gap12 = SizedBox(height: AppSizes.md);
  static const gap16 = SizedBox(height: AppSizes.lg);
  static const gap20 = SizedBox(height: AppSizes.xl);
  static const gap24 = SizedBox(height: AppSizes.xxl);
  static const gap32 = SizedBox(height: AppSizes.triple);
}
