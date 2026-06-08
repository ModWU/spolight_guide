import 'package:flutter/material.dart';

import 'spotlight_guide_home_page.dart';

class SpotlightGuideExampleApp extends StatelessWidget {
  const SpotlightGuideExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF316B67)),
        useMaterial3: true,
      ),
      home: const SpotlightGuideHomePage(),
    );
  }
}
