import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/app/router/app_router.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/core/theme/theme_mode_notifier.dart';

/// Root GenZ Media Application widget.
class GenZApp extends ConsumerWidget {
  const GenZApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'GenZ Media',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
