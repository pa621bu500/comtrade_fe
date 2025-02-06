import 'package:comtrade_fe/homepage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_core/core.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'util/ThemeProvider.dart';

void main() {
  runApp(ChangeNotifierProvider(
      create: (context) => ThemeProvider(), child: const MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          home: const Scaffold(
            body: Center(
              child: MainScreen(),
            ),
          ),
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeNotifier.isDark ? ThemeMode.dark : ThemeMode.light,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
