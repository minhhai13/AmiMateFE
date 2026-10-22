import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class AmiMateApp extends ConsumerWidget {
  const AmiMateApp({super.key, this.router});

  final GoRouter? router;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'AmiMate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router ?? ref.watch(appRouterProvider),
      locale: const Locale('vi'),
      supportedLocales: const [Locale('vi')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}
