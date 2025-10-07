import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../widgets/fade_in_wrapper.dart';
import '../navigation/main_navigation.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NexTarget',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Colors.amber,
          secondary: Color(0xFF16FF8B),
          surface: Color(0xFF23272F),
        ),
        scaffoldBackgroundColor: Color(0xFF181A20),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 1.2,
          ),
        ),
        cardColor: Color(0xFF23272F),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF16FF8B),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            elevation: 2,
          ),
        ),
        textTheme: ThemeData.dark().textTheme.copyWith(
          bodyLarge: TextStyle(fontSize: 16, color: Colors.white),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.white70),
          titleLarge: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF23272F),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF16FF8B), width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.amber, width: 2),
          ),
          labelStyle: TextStyle(color: Color(0xFF16FF8B)),
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
        iconTheme: IconThemeData(color: Color(0xFF16FF8B), size: 24),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF16FF8B),
          foregroundColor: Colors.black,
        ),
        dividerColor: Colors.grey[800],
      ),
      home: FadeInWrapper(
        duration: Duration(milliseconds: AppConfig.I.splashFadeDurationMs),
        child: MainNavigation(),
      ),
    );
  }
}