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

/// Returns a consistently-styled [AppBar] used across all main screens.
/// Title is left-aligned; optional [subtitle] appears below it.
AppBar buildStandardAppBar({
  required BuildContext context,
  required String title,
  String? subtitle,
  List<Widget>? actions,
  Widget? leading,
  bool automaticallyImplyLeading = true,
}) {
  final theme = Theme.of(context);
  return AppBar(
    backgroundColor: theme.colorScheme.surface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    automaticallyImplyLeading: false,
    leading: leading ?? Builder(
      builder: (ctx) => IconButton(
        icon: const Icon(Icons.menu_rounded),
        tooltip: 'Menu',
        onPressed: () {
          // Walk up the element tree to find the ancestor Scaffold that
          // actually owns the Drawer (the outer HomeController Scaffold),
          // skipping any nested Scaffolds that have no drawer.
          ctx.visitAncestorElements((element) {
            if (element is StatefulElement && element.state is ScaffoldState) {
              final s = element.state as ScaffoldState;
              if (s.hasDrawer) {
                s.openDrawer();
                return false; // stop walking
              }
            }
            return true; // keep walking
          });
        },
      ),
    ),
    actions: actions,
    titleSpacing: 20,
    title: subtitle != null
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(140),
                ),
              ),
            ],
          )
        : Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
  );
}

/// A pinned [SliverAppBar] with the same visual style as [buildStandardAppBar],
/// used in screens that have a [CustomScrollView].
SliverAppBar buildStandardSliverAppBar({
  required BuildContext context,
  required String title,
  String? subtitle,
  List<Widget>? actions,
}) {
  final theme = Theme.of(context);
  return SliverAppBar(
    pinned: true,
    floating: false,
    backgroundColor: theme.colorScheme.surface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    titleSpacing: 20,
    actions: actions,
    // Use title: directly — avoids FlexibleSpaceBar fighting with actions.
    title: subtitle != null
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(140),
                ),
              ),
            ],
          )
        : Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
  );
}
