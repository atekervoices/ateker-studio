// Copyright 2025 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter/material.dart';

abstract final class AppColors {
  static const black1 = Color(0xFF101010);
  static const white1 = Color(0xFFFFF7FA);
  static const grey1 = Color(0xFFF2F2F2);
  static const greylight = Color(0xFFE3E3E3);
  static var grey900 = Colors.grey.shade900;
  static const grey2 = Color(0xFF4D4D4D);
  static const grey3 = Color(0xFFA4A4A4);

  static const primary = Color(0xFFD06E1A);
  static const secondary = Color(0xFF6B2A05);
  static const tertiary = Color(0xFF6B2A05);
  static const whiteTransparent = Color(
    0x4DFFFFFF,
  ); // Figma rgba(255, 255, 255, 0.3)
  static const blackTransparent = Color(0x4D000000);
  static const red1 = Color(0xFFE74C3C);

  static const blueCardColor = Color(0xFFD3E3FD);
  static const lightCardColor = Color(0xFFE3E3E3);

  static const lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.white1,
    secondary: AppColors.secondary,
    onSecondary: AppColors.white1,
    tertiary: AppColors.tertiary,
    onTertiary: AppColors.blueCardColor,
    surface: Colors.white,
    onSurface: AppColors.black1,
    error: Colors.white,
    onError: Colors.red,
    outline: Colors.blueGrey,
  );

  static const darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primary,
    onPrimary: AppColors.white1,
    secondary: AppColors.secondary,
    onSecondary: AppColors.white1,
    tertiary: AppColors.tertiary,
    onTertiary: AppColors.blueCardColor,
    surface: AppColors.black1,
    onSurface: Colors.white,
    error: Colors.black,
    onError: AppColors.red1,
    outline: Colors.blueGrey,
  );
}
