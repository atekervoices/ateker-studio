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

import 'generated/l10n/app_localizations.dart';
import 'ui/core/themes/colors.dart';
import 'ui/splash/splash_screen.dart';

class AtekerVoicesApp extends StatelessWidget {
  const AtekerVoicesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorScheme: AppColors.lightColorScheme).copyWith(
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
                backgroundColor: Colors.grey.shade200)),
        darkTheme: ThemeData(colorScheme: AppColors.darkColorScheme).copyWith(
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
                backgroundColor: Colors.grey.shade900)),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SplashScreen());
  }
}
