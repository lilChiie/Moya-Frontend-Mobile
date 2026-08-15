import 'package:flutter/material.dart';
import 'app/routes.dart';
import 'app/theme.dart';

void main() {
  runApp(const MoyaApp());
}

class MoyaApp extends StatelessWidget {
  const MoyaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moya',
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.getRoutes(),
      debugShowCheckedModeBanner: false,
    );
  }
}
