import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../navigation/app_router.dart';
import '../widgets/fade_in_wrapper.dart';
import '../theme/app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NexTarget',
      theme: AppTheme.darkTheme,
      home: FadeInWrapper(
        duration: Duration(milliseconds: AppConfig.I.splashFadeDurationMs),
        child: AppNavigator(),
      ),
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: AppRouter.home,
    );
  }
}