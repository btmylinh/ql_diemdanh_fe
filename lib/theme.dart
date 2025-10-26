import 'package:flutter/material.dart';

const kGreen = Color(0xFF2AB090);
const kBlue = Color(0xFF2196F3);

final lightTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: kGreen, brightness: Brightness.light),
  useMaterial3: true,
  scaffoldBackgroundColor: Colors.white,
);

final darkTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: kGreen, brightness: Brightness.dark),
  useMaterial3: true,
);
