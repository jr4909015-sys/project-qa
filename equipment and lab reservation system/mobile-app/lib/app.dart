import 'package:flutter/material.dart';

import 'navigation/app_router.dart';
import 'core/theme/app_theme.dart';

class SchoolReservationApp extends StatelessWidget {
  const SchoolReservationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Reserve',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRouter.login,
      routes: AppRouter.routes,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}