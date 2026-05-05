import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'configurations/theme/app_theme.dart';
import 'configurations/routes/app_routes.dart';
import 'core/utils/app_scroll_behavior.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    const ProviderScope(
      child: MedPredictApp(),
    ),
  );
}

class MedPredictApp extends StatelessWidget {
  const MedPredictApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MedPredict AI',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: AppRoutes.router,
      scrollBehavior: AppScrollBehavior(),
    );
  }
}
