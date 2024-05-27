import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc_app/screens/home_screen.dart';
import 'services/signalling.service.dart';

void main() {
  runApp(VideoCallApp());
}

class VideoCallApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'P2P Call App',
     darkTheme: ThemeData.dark().copyWith(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(),
      ),
      themeMode: ThemeMode.dark,
      home: HomeScreen(),
    );
  }
}